package helm

#code: #"""
	# Add the repository
	# cat /helm/values.yaml
	if [ -n "$HELM_REPO" ]; then
		helm repo add repository "${HELM_REPO}"
		helm repo update
	fi

	# If the chart is a file, then it's the chart name
	# If it's a directly, then it's the contents of the cart
	# if [ -f "/helm/chart" ]; then
	#	HELM_CHART="repository/$(cat /helm/chart)"
	# else
	#	HELM_CHART="/helm/chart"
	# fi
	HELM_CHART="repository/$CHART_NAME"


	OPTS=""
	OPTS="$OPTS --timeout "$HELM_TIMEOUT""
	OPTS="$OPTS --namespace "$KUBE_NAMESPACE""
	OPTS="$OPTS --set $HELM_SET"
	[ "$HELM_CHART_VERSION" != "" ] &&  OPTS="$OPTS --version $HELM_CHART_VERSION"
	[ "$HELM_WAIT" = "true" ] && OPTS="$OPTS --wait"
	[ "$HELM_ATOMIC" = "true" ] && OPTS="$OPTS --atomic"
	[ -f "/helm/values.yaml" ] && OPTS="$OPTS -f /helm/values.yaml"

	# Select the namespace
	kubectl create namespace "$KUBE_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
	# kubectl create namespace "$KUBE_NAMESPACE" || true

	# Try delete pending-upgrade helm release
	# https://github.com/helm/helm/issues/4558
	kubectl -n "$KUBE_NAMESPACE" delete secret -l name="$HELM_NAME",status=pending-upgrade
	kubectl -n "$KUBE_NAMESPACE" delete secret -l name="$HELM_NAME",status=pending-install

	case "$HELM_ACTION" in
		install)
			helm install $OPTS "$HELM_NAME" "$HELM_CHART"
		;;
		upgrade)
			helm upgrade $OPTS "$HELM_NAME" "$HELM_CHART"
		;;
		installOrUpgrade)
			helm upgrade $OPTS --install "$HELM_NAME" "$HELM_CHART"
		;;
		*)
			echo unsupported helm action "$HELM_ACTION"
			exit 1
		;;
	esac

	mkdir /output
	echo 'OK' > /output/wait
	"""#
