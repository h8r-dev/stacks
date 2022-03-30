package main

import (
	"strings"
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
)

#InitNocalhostData: {
	nocalhostURL:       string
	githubAccessToken:  dagger.#Secret
	githubOrganization: string
	kubeconfig:         string | dagger.#Secret
	applicationName:    string
	gitURL:             string

	nocalhostToken: #GetNocalhostToken & {
		url: nocalhostURL
	}

	githubOrganizationMembers: #GetGithubOrganizationMembers & {
		accessToken:  githubAccessToken
		organization: githubOrganization
	}

	createNocalhostTeam: #CreateNocalhostTeam & {
		token:   nocalhostToken.output
		members: githubOrganizationMembers.output
		url:     nocalhostURL
	}

	createNocalhostCluster: #CreateNocalhostCluster & {
		token:        nocalhostToken.output
		url:          nocalhostURL
		"kubeconfig": kubeconfig
	}

	createNocalhostApplication: #CreateNocalhostApplication & {
		token:             nocalhostToken.output
		url:               nocalhostURL
		"applicationName": applicationName
		"gitURL":          gitURL
	}

	createNocalhostDevSpace: #CreateNocalhostDevSpace & {
		token:                         nocalhostToken.output
		url:                           nocalhostURL
		waitForCreateNocalhostTeam:    createNocalhostTeam.success
		waitForCreateNocalhostCluster: createNocalhostCluster.success
	}
}

#GetNocalhostToken: {
	url:      string
	user:     string | *"admin@admin.com"
	password: string | *"123456"

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
			jq: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		script: contents: #"""
			until $(curl --output /dev/null --silent --head --fail \#(url)/health); do
				echo 'nocalhost not ready'
				sleep 2
			done
			mkdir /output
			curl --retry 10 --retry-delay 2 --location --request POST \#(url)/v1/login \
				--header "Content-Type: application/json" \
				--data-raw '{"email":"\#(user)","password":"\#(password)"}' > /result
			printf "$(jq '.data.token' /result)" > /result
			"""#
		export: files: "/result": string
	}

	output: strings.Replace(run.export.files."/result", "\n", "", -1)
}

#GetGithubOrganizationMembers: {
	accessToken:  dagger.#Secret
	organization: string

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
			jq: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		env: TOKEN:       accessToken
		script: contents: #"""
		username=$(curl -sH "Authorization: token ${TOKEN}" https://api.github.com/user | jq -r '.login') > /result
		if [ "$username" == \#(organization) ]; then
			# personal github name
			exit 0
		else
			# github organization name
			curl -sH "Authorization: token ${TOKEN}" https://api.github.com/orgs/\#(organization)/members | jq -r '.[].login' > /result
		fi
		"""#

		export: files: "/result": string
	}

	output: run.export.files."/result"
}

#CreateNocalhostTeam: {
	token:   string
	members: string
	url:     string
	password: string | *"123456"

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		script: contents: #"""
			sh_c='sh -c'
			until $(curl --output /dev/null --silent --head --fail \#(url)/health); do
				echo 'nocalhost ready'
				sleep 2
			done
			MEMBERS="\#(members)"
			URL="\#(url)/v1/users"
			HEADER="--header 'Authorization: Bearer \#(token)' --header 'Content-Type: application/json'"
			for user in ${MEMBERS[@]}; do
				DATA_RAW='{"confirm_password":"123456","email":"'"$user"'@h8r.io","is_admin":0,"name":"'"$user"'","password":"123456","status":1}'
			  do_create="curl $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
				$sh_c "$do_create"
			done
			"""#
	}
	success: run.success
}

#CreateNocalhostCluster: {
	token:      string
	url:        string
	kubeconfig: string | dagger.#Secret

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		script: contents: #"""
			sh_c='sh -c'
			until $(curl --output /dev/null --silent --head --fail \#(url)/health); do
				echo 'nocalhost ready'
				sleep 2
			done

			kubeconfig="$(base64 -w0 /etc/kubernetes/config)"
			URL="\#(url)/v1/cluster"
			DATA_RAW='{"name":"initCluster","kubeconfig":"'$kubeconfig'"}'
			HEADER="--header 'Authorization: Bearer \#(token)' --header 'Content-Type: application/json'"
			do_create="curl $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
			$sh_c "$do_create"
			"""#
		mounts: "kubeconfig": {
			dest:     "/etc/kubernetes/config"
			contents: kubeconfig
		}
	}
	success: run.success
}

#CreateNocalhostApplication: {
	token:           string
	url:             string
	applicationName: string
	gitURL:          string
	source:          string | *"git"
	installType:     string | *"helm_chart"

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		script: contents: #"""
			sh_c='sh -c'
			until $(curl --output /dev/null --silent --head --fail \#(url)/health); do
				echo 'nocalhost ready'
				sleep 2
			done

			URL="\#(url)/v1/application"
			DATA_RAW='{"context":"{\"application_url\":\"\#(gitURL)\",\"application_name\":\"\#(applicationName)\",\"source\":\"\#(source)\",\"install_type\":\"\#(installType)\",\"resource_dir\":[]}","status":1}'
			HEADER="--header 'Authorization: Bearer \#(token)' --header 'Content-Type: application/json'"
			do_create="curl $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
			$sh_c "$do_create"
			"""#
	}
}

#CreateNocalhostDevSpace: {
	token:                         string
	url:                           string
	waitForCreateNocalhostTeam:    bool
	waitForCreateNocalhostCluster: bool

	baseImage: alpine.#Build & {
		packages: {
			bash: {}
			curl: {}
			jq: {}
			sed: {}
		}
	}

	run: bash.#Run & {
		always: true
		input:  baseImage.output
		script: contents: #"""
			echo "waitForCreateNocalhostTeam \#(waitForCreateNocalhostTeam)"
			echo "waitForCreateNocalhostCluster \#(waitForCreateNocalhostCluster)"
			sh_c='sh -c'
			until $(curl --output /dev/null --silent --head --fail \#(url)/health); do
				echo 'nocalhost ready'
				sleep 2
			done
			
			URL="\#(url)/v2/dev_space/cluster"
			HEADER="--header 'Authorization: Bearer \#(token)'"
			do_create="curl $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_create")"
			cluster_id=$(echo "$messages" | jq '.data | .[0] | .id')
			if [[ "$cluster_id" == "null" ]]; then
			  echo "cluster not fond"
				exit 1
			fi

			URL="\#(url)/v1/users"
			do_create="curl $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_create")"
			user_ids=$(echo "$messages" | jq -r '.data | .[] | .id')

			URL="\#(url)/v2/dev_space"
			do_create="curl $HEADER -s --location --request GET $URL"
			messages="$($sh_c "$do_create")"
			had_space_ids=$(echo "$messages" | jq -r '.data | .[] | .user_id')

			URL="\#(url)/v1/dev_space"
			HEADER="--header 'Authorization: Bearer \#(token)' --header 'Content-Type: application/json'"
			for id in ${user_ids[@]}; do
				[[ "${had_space_ids[@]}" =~ "$id" ]] && continue
				DATA_RAW='{"cluster_id":'"$cluster_id"',"cluster_admin":0,"user_id":'"$id"',"space_name":"","space_resource_limit":null}'
				echo $DATA_RAW
				do_create="curl $HEADER --location --request POST $URL --data-raw '$DATA_RAW'"
				$sh_c "$do_create"
			done
			"""#
	}
}
