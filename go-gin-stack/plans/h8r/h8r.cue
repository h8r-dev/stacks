package h8r

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/alpine"
)

#Tke: {
	// Tencent secret id
	secretId: dagger.#Input & {string}
	// Tencent secret key
	secretKey: dagger.#Secret @dagger(input)
	// region
	zone: "ap-hongkong"

	references: {
		string

		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash:      true
					package: jq:        true
					package: git:       true
					package: python3:   true
					package: curl:      true
					package: "py3-pip": true
				}
				// from: os.#Container & {
				//     image: "python:3.9.10-slim-bullseye"
				//     setup: [
				//         "pip install tccli",
				//         "apt update && apt install jq -y",
				//     ]
				//     secret: "/run/secrets/secretKey": account.secretKey
				//     env: {
				//         SECRET_ID: account.secretId
				//         ZONE: account.zone
				//     }
				//     always: true
				//     shell: args: [
				//         #"""
				//             tccli configure set secretId $SECRET_ID
				//             tccli configure set secretKey $(cat /run/secrets/secretKey)
				//             tccli configure set region $ZONE
				//             tccli tke CreateCluster --cli-unfold-argument  \
				//             --region $ZONE \
				//             --ClusterType MANAGED_CLUSTER \
				//             --ClusterCIDRSettings.ClusterCIDR 10.4.0.0/14 \
				//             --RunInstancesForNode.0.NodeRole WORKER \
				//             --RunInstancesForNode.0.RunInstancesPara '{"VirtualPrivateCloud":{"SubnetId":"subnet-gjfyzxor","VpcId":"vpc-1ds1cs38"},"Placement":{"Zone":"ap-hongkong-2"},"InstanceType":"SA2.MEDIUM4","SystemDisk":{"DiskType":"CLOUD_PREMIUM"},"DataDisks":[{"DiskType":"CLOUD_PREMIUM","DiskSize":50}],"InstanceCount":1,"InternetAccessible":{"PublicIpAssigned":true,"InternetMaxBandwidthOut":100},"LoginSettings":{"Password":"Coding123!"}}' > /cluster.json
				//             export CLUSTER_ID=$(cat /cluster.json | jq .ClusterId | cut -d/ -f4)
				//             tccli tke DescribeClusterStatus --cli-unfold-argument --region $ZONE --ClusterIds $CLUSTER_ID --waiter "{'expr':'ClusterStatusSet[0].ClusterState','to':'Running','timeout':600,'interval':1}"
				//             tccli tke CreateClusterEndpointVip --cli-unfold-argument --region $ZONE --ClusterIds $CLUSTER_ID --SecurityPolicies 0.0.0.0/0
				//             tccli tke DescribeClusterEndpointVipStatus --cli-unfold-argument --region $ZONE --ClusterIds $CLUSTER_ID --waiter "{'expr':'Status','to':'Created','timeout':600,'interval':1}"
				//             tccli tke DescribeClusterKubeconfig --cli-unfold-argument --region $ZONE --ClusterId $CLUSTER_ID > /cluster_info.json
				//             export KUBECONFIG=$(cat /cluster_info.json | jq .Kubeconfig | cut -d/ -f4)
				//         """#
				//     ]
				// }
			},

			op.#Exec & {
				mount: "/run/secrets/secretKey": secret: secretKey
				dir: "/"
				env: {
					SECRET_ID: secretId
					ZONE:      zone
				}
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
						    pip3 install tccli
						    wget https://github.com/mikefarah/yq/releases/download/v4.19.1/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
						    tccli configure set secretId $SECRET_ID
						    tccli configure set secretKey $(cat /run/secrets/secretKey)
						    tccli configure set region $ZONE
						    # check cluster exist
						    tccli tke DescribeClusters --cli-unfold-argument --region $ZONE --Filters.0.Name ClusterName --Filters.0.Values h8r > /check_cluster.json
						    checkClusterID=$(cat /check_cluster.json | jq .Clusters[0].ClusterId | sed 's/\"//g')
						    if [ "$checkClusterID" == "null" ]; then
						        echo 'Creating TKE'
						    else
						        echo 'TKE already created'
						        tccli tke DescribeClusterKubeconfig --cli-unfold-argument --region $ZONE --ClusterId $checkClusterID > /cluster_info.json
						        yq -P '.Kubeconfig' /cluster_info.json > /cluster_kubeocnfig
						        exit 0
						    fi
						    # get subnet
						    tccli vpc DescribeSubnets --cli-unfold-argument --region ap-hongkong > /subnet.json
						    VpcId=$(cat /subnet.json | jq '.SubnetSet[0] | .VpcId' | cut -d/ -f4)
						    SubnetId=$(cat /subnet.json | jq '.SubnetSet[0] | .SubnetId' | cut -d/ -f4)
						    VPCZone=$(cat /subnet.json | jq '.SubnetSet[0] | .Zone' | cut -d/ -f4)
						    tccli tke CreateCluster --cli-unfold-argument  \
						    --region $ZONE \
						    --ClusterType MANAGED_CLUSTER \
						    --ClusterCIDRSettings.ClusterCIDR 10.4.0.0/14 \
						    --ClusterCIDRSettings.IgnoreClusterCIDRConflict True \
						    --ClusterBasicSettings.ClusterName h8r \
						    --RunInstancesForNode.0.NodeRole WORKER \
						    --RunInstancesForNode.0.RunInstancesPara '{"VirtualPrivateCloud":{"SubnetId":'$SubnetId',"VpcId":'$VpcId'},"Placement":{"Zone":'$VPCZone'},"InstanceType":"SA2.MEDIUM4","SystemDisk":{"DiskType":"CLOUD_PREMIUM"},"DataDisks":[{"DiskType":"CLOUD_PREMIUM","DiskSize":50}],"InstanceCount":1,"InternetAccessible":{"PublicIpAssigned":true,"InternetMaxBandwidthOut":100},"LoginSettings":{"Password":"Coding123!"}}' > /cluster.json
						    CLUSTER_ID=$(cat /cluster.json | jq .ClusterId | cut -d/ -f4 | sed 's/\"//g')
						    echo 'Created success, TKE cluster ID: '$CLUSTER_ID
						    echo 'Waiting for cluster ready...'
						    tccli tke DescribeClusterStatus --cli-unfold-argument --region $ZONE --ClusterIds $CLUSTER_ID --waiter "{'expr':'ClusterStatusSet[0].ClusterState','to':'Running','timeout':600,'interval':1}"
						    echo 'Opening Endpoint for 0.0.0.0/0...'
						    tccli tke CreateClusterEndpointVip --cli-unfold-argument --region $ZONE --ClusterId $CLUSTER_ID --SecurityPolicies 0.0.0.0/0
						    tccli tke DescribeClusterEndpointVipStatus --cli-unfold-argument --region $ZONE --ClusterId $CLUSTER_ID --waiter "{'expr':'Status','to':'Created','timeout':600,'interval':1}"
						    tccli tke DescribeClusterKubeconfig --cli-unfold-argument --region $ZONE --ClusterId $CLUSTER_ID > /cluster_info.json
						    yq -P '.Kubeconfig' /cluster_info.json > /cluster_kubeocnfig
						"""#,
				]
				always: true
			},

			op.#Export & {
				source: "/cluster_kubeocnfig"
				format: "string"
			},
		]
	} @dagger(output)
}

#Helm: {
	// release name
	releaseName: dagger.#Input & {string}

	// helm chart path
	helmPath: dagger.#Input & {string}

	// git repo url
	repoUrl: dagger.#Input & {string}

	// kubeconfig

	kubeconfig: dagger.#Input & {string}

	// deploy namespace
	namespace: dagger.#Input & {string}

	install: {
		string

		#up: [
			op.#Load & {
				from: alpine.#Image & {
					package: bash: true
					package: jq:   true
					package: git:  true
					package: curl: true
				}
			},

			op.#Exec & {
				mount: "/run/secrets/kubeconfig": from: kubeconfig
				dir: "/"
				env: {
					REPO_URL:     repoUrl
					HELM_PATH:    helmPath
					RELEASE_NAME: releaseName
					NAMESPACE:    namespace
				}
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
						    # use setup avoid download everytime
						    export VERIFY_CHECKSUM=false
						    curl "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash
						    export KUBECONFIG=/run/secrets/kubeconfig/cluster_kubeocnfig
						    git clone $REPO_URL
						    cd $RELEASE_NAME/$HELM_PATH
						    helm upgrade $RELEASE_NAME . --dependency-update --namespace $NAMESPACE --create-namespace --install
						    # wait for deployment ready
						    curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
						    chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl
						    kubectl wait --for=condition=available --timeout=600s deployment/$RELEASE_NAME-go-gin-stack -n $NAMESPACE
						    kubectl get services --namespace $NAMESPACE $RELEASE_NAME-go-gin-stack --output jsonpath='{.status.loadBalancer.ingress[0].ip}' > /end_point.txt
						    PORT=$(kubectl get services --namespace $NAMESPACE $RELEASE_NAME-go-gin-stack --output jsonpath='{.spec.ports[0].port}')
						    echo ":$PORT" >> /end_point.txt
						"""#,
				]
				always: true
			},

			op.#Export & {
				source: "/end_point.txt"
				format: "string"
			},
		]
	} @dagger(output)
}

#Deploy: {
	// Ingress host name
	ingressHostName: dagger.#Input & {string}

	// Ghcr name
	ghcrName: dagger.#Input & {string}

	// Ghcr password
	ghcrPassword: dagger.#Input & {dagger.#Secret}

	//Release name
	releaseName: dagger.#Input & {string}

	// Github SSH private key
	// sshDir: dagger.#Artifact @dagger(input)

	// Helm chart path
	helmPath: dagger.#Input & {string}

	// Git repo url
	repoUrl: dagger.#Input & {string}

	// TODO Kubeconfig path, set infra/kubeconfig and fill kubeconfig to infra/kubeconfig/config.yaml file
	kubeconfig: dagger.#Artifact @dagger(input)

	// Deploy namespace
	namespace: dagger.#Input & {string}

	install: {
		string

		#up: [
			// op.#Load & {
			//     from: alpine.#Image & {
			//   package: bash: true
			//   package: jq:   true
			//   package: git:  true
			//         package: curl: true
			//         package: openssh: true
			//  }
			// },

			op.#FetchContainer & {
				ref: "docker.io/lyzhang1999/alpine:v1"
			},

			op.#Exec & {
				mount: "/run/secrets/kubeconfig": from: kubeconfig
                mount: "/run/secrets/github": secret: ghcrPassword
				// mount: "/root/.ssh/": from:             sshDir
				dir: "/"
				env: {
					REPO_URL:        repoUrl
					HELM_PATH:       helmPath
					RELEASE_NAME:    releaseName
					NAMESPACE:       namespace
					GHCRNAME:        ghcrName
					INGRESSHOSTNAME: ingressHostName
				}
				args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
					#"""
                        # use setup avoid download everytime
                        export KUBECONFIG=/run/secrets/kubeconfig/config.yaml
                        git clone $REPO_URL
                        cd $RELEASE_NAME/$HELM_PATH
                        kubectl create secret docker-registry h8r-secret \
                        --docker-server=ghcr.io \
                        --docker-username=$GHCRNAME \
                        --docker-password=$(cat /run/secrets/github) \
                        -o yaml --dry-run=client | kubectl apply -f -
                        helm upgrade $RELEASE_NAME . --dependency-update --namespace $NAMESPACE --install --set "ingress.hosts[0].host=$INGRESSHOSTNAME,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=ImplementationSpecific" > /end_point.txt
                        # wait for deployment ready
                        # kubectl wait --for=condition=available --timeout=600s deployment/$RELEASE_NAME-go-gin-stack -n $NAMESPACE
                    """#,
				]
				always: true
			},

			op.#Export & {
				source: "/end_point.txt"
				format: "string"
			},
		]
	} @dagger(output)
}

#CheckInfra: {
    // TODO default repoDir path, now you can set "." with dagger dir type
    sourceCodeDir: dagger.#Artifact @dagger(input)

    check: {
        string

        #up: [
            op.#FetchContainer & {
				ref: "docker.io/lyzhang1999/alpine:v1"
			},

            op.#Exec & {
				mount: "/root": from: sourceCodeDir
                args: [
					"/bin/bash",
					"--noprofile",
					"--norc",
					"-eo",
					"pipefail",
					"-c",
                    #"""
                    FILE=/root/infra/kubeconfig/config.yaml
                    if [ ! -f "$FILE" ] || [ ! -s "$FILE" ]; then
                        echo "Please add your kubeconfig to infra/kubeconfig/config.yaml file"
                        exit 1
                    fi
                    echo "OK!" >  /success
                    """#,
				]
				always: true
            },

            op.#Export & {
				source: "/success"
				format: "string"
			},
        ]
    } @dagger(output)
}