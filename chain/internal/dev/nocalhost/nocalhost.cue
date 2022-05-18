package nocalhost

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"github.com/h8r-dev/stacks/chain/internal/utils/base"
)

#GetToken: {
	url:      string | *"nocalhost-web.nocalhost"
	user:     string | *"admin@admin.com"
	password: string | *"123456"
	waitFor?: bool

	_baseImage: base.#Image

	_run: bash.#Run & {
		always: true
		input:  _baseImage.output
		env: {
			if waitFor != _|_ {
				WAIT_FOR: "\(waitFor)"
			}
			USER:     user
			PASSWORD: password
			NH_HOST:  url
		}
		script: contents: #"""
			echo "waiting for nocalhost to be ready..."
			n=0
			until [ $n -ge 500 ] ; do
				if $(curl --output /dev/null --silent --head --fail $NH_HOST/health); then
					break
				fi
				n=$((n+1))
				if [[ $(( n % 30)) == 0 ]] ; then
					echo "waiting for nocalhost to be ready... ${n}s"
				fi
				sleep 1
			done
			if [ $n -ge 500 ]; then
				echo "timeout waiting for nocalhost to be ready"
				exit 1
			fi

			token=""
			for i in $(seq 1 50); do
				token=""
				DATA_RAW='{"email":"'"$USER"'","password":"'"$PASSWORD"'"}'
				curl -s --retry 20 --retry-delay 2 --location --request POST $NH_HOST/v1/login \
					--header "Content-Type: application/json" \
					--data-raw "$DATA_RAW" > /result
				set +e
				token=$(jq -r '.data | .token' /result)
				exit_code=$?
				set -e
				if [[ $exit_code != 0 ]]; then
					echo "failed to get token, retrying..."
					sleep 5
					continue
				fi
				if [[ "$token" != "" && $token != "null" ]]; then
					echo "successfully got token"
					break
				fi
				echo "failed to get token, retrying..."
				sleep 5
			done
			printf $token > /result
			"""#
		export: files: "/result": string
	}

	output: _run.export.files."/result"
}

#CreateTeam: {
	url:         string | *"nocalhost-web.nocalhost"
	token:       string
	members:     string
	password:    string | *"123456"
	emailSuffix: string | *"@h8r.io"
	waitFor?:    bool

	_baseImage: base.#Image

	_run: bash.#Run & {
		env: {
			if waitFor != _|_ {
				WAIT_FOR: "\(waitFor)"
			}
			NH_HOST:  url
			TOKEN:    token
			PASSWORD: password
			MEMBERS:  members
		}
		always: true
		input:  _baseImage.output
		script: contents: #"""
			sh_c='sh -c'
			URL="$NH_HOST/v1/users"
			HEADER="--header 'Authorization: Bearer "$TOKEN"' --header 'Content-Type: application/json'"
			for user in ${MEMBERS[@]}; do
			  email="$user$EMAIL_SUFFIX"
				DATA_RAW='{"confirm_password":"'"$PASSWORD"'","email":"'"$email"'","is_admin":0,"name":"'"$user"'","password":"'"$PASSWORD"'","status":1}'
			  do_create="curl -s --retry 20 --retry-delay 2 $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
				messages="$($sh_c "$do_create")"
				echo "msg: $(echo "$messages" | jq -r '.message')"
			done
			"""#
	}
	success: _run.success
}

#CreateCluster: {
	url:        string | *"nocalhost-web.nocalhost"
	token:      string
	waitFor?:   bool
	kubeconfig: string | dagger.#Secret
	apiServer:  string

	_baseImage: base.#Image

	_run: bash.#Run & {
		always: true
		input:  _baseImage.output
		env: {
			if waitFor != _|_ {
				WAIT_FOR: "\(waitFor)"
			}
			NH_HOST:    url
			TOKEN:      token
			API_SERVER: apiServer
		}
		script: contents: #"""
			sh_c='sh -c'
			kubeconfig="$(base64 -w0 /etc/kubernetes/config)"
			URL="$NH_HOST/v1/cluster"
			DATA_RAW='{"name":"initCluster","kubeconfig":"'"$kubeconfig"'","extra_api_server":"'"$API_SERVER"'"}'
			HEADER="--header 'Authorization: Bearer "$TOKEN"' --header 'Content-Type: application/json'"
			do_create="curl -s --retry 20 --retry-delay 2 $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
			messages="$($sh_c "$do_create")"
			echo "msg: $(echo "$messages" | jq -r '.message')"
			"""#
		mounts: "kubeconfig": {
			dest:     "/etc/kubernetes/config"
			contents: kubeconfig
		}
	}
	success: _run.success
}

#CreateApplication: {
	url:         string | *"nocalhost-web.nocalhost"
	waitFor?:    bool
	token:       string
	appName:     string
	appGitURL:   string
	source:      string | *"git"
	installType: string | *"helm_chart"

	_baseImage: base.#Image

	_run: bash.#Run & {
		always: true
		input:  _baseImage.output
		env: {
			if waitFor != _|_ {
				WAIT_FOR: "\(waitFor)"
			}
			TOKEN:        token
			APP_NAME:     appName
			APP_GIT_URL:  appGitURL
			SOURCE:       source
			INSTALL_TYPE: installType
			NH_HOST:      url
		}
		script: contents: #"""
			sh_c='sh -c'
			URL="$NH_HOST/v1/application"
			# FixMe: hardcode
			RESOURCE_DIR="$APP_NAME-backend"
			DATA_RAW='{"context":"{\"application_url\":\"'"$APP_GIT_URL"'\",\"application_name\":\"'"$RESOURCE_DIR"'\",\"source\":\"'"$SOURCE"'\",\"install_type\":\"'"$INSTALL_TYPE"'\",\"resource_dir\":[\"'"$RESOURCE_DIR"'\"]}","status":1}'
			HEADER="--header 'Authorization: Bearer "$TOKEN"' --header 'Content-Type: application/json'"
			do_create="curl -s --retry 20 --retry-delay 2 $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
			messages="$($sh_c "$do_create")"
			echo "msg: $(echo "$messages" | jq -r '.message')"
			"""#
	}
}

#CreateDevSpace: {
	url:      string | *"nocalhost-web.nocalhost"
	token:    string
	url:      string
	waitFor?: bool

	_baseImage: base.#Image

	_run: bash.#Run & {
		always: true
		input:  _baseImage.output
		env: {
			if waitFor != _|_ {
				WAIT_FOR: "\(waitFor)"
			}
			TOKEN:   token
			NH_HOST: url
		}
		script: contents: #"""
			sh_c='sh -c'
			URL="$NH_HOST/v2/dev_space/cluster"
			HEADER="--header 'Authorization: Bearer "$TOKEN"'"
			do_get="curl --retry 20 --retry-delay 2 $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_get")"
			cluster_id=$(echo "$messages" | jq '.data | .[0] | .id')
			if [[ "$cluster_id" == "null" ]]; then
			  echo "cluster not fond"
				exit 1
			fi

			URL="$NH_HOST/v1/users"
			do_create="curl --retry 20 --retry-delay 2 $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_create")"
			user_ids=$(echo "$messages" | jq -r '.data | .[] | .id')

			URL="$NH_HOST/v2/dev_space"
			do_get="curl --retry 20 --retry-delay 2 $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_get")"
			had_space_ids=$(echo "$messages" | jq -r '.data | .[] | .user_id')

			URL="$NH_HOST/v1/dev_space"
			HEADER="--header 'Authorization: Bearer "$TOKEN"' --header 'Content-Type: application/json'"
			touch /namespaces
			for id in ${user_ids[@]}; do
				[[ "${had_space_ids[@]}" =~ "$id" ]] && continue
				DATA_RAW='{"cluster_id":'"$cluster_id"',"cluster_admin":0,"user_id":'"$id"',"space_name":"","space_resource_limit":null}'
				do_create="curl -s --retry 20 --retry-delay 2 $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
				messages="$($sh_c "$do_create")"
				echo "msg: $(echo "$messages" | jq -r '.message')"
				ns=$(echo "$messages" |  jq -r '.data | .namespace')
				echo "$ns" >> /namespaces
			done
			"""#

		export: files: "/namespaces": string
	}

	nsOutput: _run.export.files."/namespaces"
}
