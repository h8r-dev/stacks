package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/alpine"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	// FIXME: Ideally we would want to automatically set the platform's arch identical to the host
	// to avoid the performance hit caused by qemu (linter goes from <3s to >3m when arch is x86)
	// Uncomment if running locally on Mac M1 to bypass qemu
	// platform: "linux/aarch64"
	// platform: "linux/amd64"

	client: {
		filesystem: code: read: {
			contents: dagger.#FS
			exclude: [
				"go-gin/README.md",
				"vue-front/README.md",
			]
		}
		env: {
			GITHUB_TOKEN:  dagger.#Secret
			HLN_PROJ_NAME: string
		}
	}

	actions: {
		// 参考 https://docs.dagger.io/1205/container-images
		// create: {
		//  "backend":  _
		//  "frontend": _
		//  "helm":     _

		//  [tag=string]: run: docker.#Build & {
		//   steps: [
		//    alpine.#Build & {
		//     packages: {
		//      bash: {}
		//      curl: {}
		//     }
		//    },
		//    docker.#Copy & {
		//     contents: client.filesystem.code.read.contents
		//     dest:     "/src"
		//    },
		//    bash.#Run & {
		//     workdir: "/src"
		//     env: HLN_PROJ_NAME: client.env.HLN_PROJ_NAME
		//     env: GITHUB_TOKEN:  client.env.GITHUB_TOKEN
		//     script: contents: #"""
		//      mkdir -p /output
		//      echo hello > /output/output.txt
		//     """#
		//    },
		//   ]
		//  }
		// }

		runCreate: docker.#Build & {
			steps: [
				alpine.#Build & {
					packages: {
						bash: {}
						curl: {}
					}
				},
				docker.#Copy & {
					contents: client.filesystem.code.read.contents
					dest:     "/src"
				},
				bash.#Run & {
					workdir: "/src"
					env: HLN_PROJ_NAME: client.env.HLN_PROJ_NAME
					env: GITHUB_TOKEN:  client.env.GITHUB_TOKEN
					script: contents: #"""
							mkdir -p /output
							curl -XPOST -d '{"name":"'$HLN_PROJ_NAME'"}' -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos > /output/output.txt
						"""#
				},
			]
		}
		create: {
			run: bash.#Run & {
				input:   runCreate.output
				workdir: "/src"
				script: contents: #"""
					"""#
			}
			contents: dagger.#Subdir & {
				input: run.output.rootfs
				path:  "/output"
			}
		}
		runDelete: docker.#Build & {
			steps: [
				alpine.#Build & {
					packages: {
						bash: {}
						curl: {}
						jq: {}
						sed: {}
					}
				},
				docker.#Copy & {
					contents: client.filesystem.code.read.contents
					dest:     "/src"
				},
				bash.#Run & {
					workdir: "/src"
					env: HLN_PROJ_NAME: client.env.HLN_PROJ_NAME
					env: GITHUB_TOKEN:  client.env.GITHUB_TOKEN
					script: contents: #"""
							mkdir -p /output
							export GITHUB_USER_NAME=$(curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -r .login)
							curl -i -XDELETE -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/$GITHUB_USER_NAME/$HLN_PROJ_NAME > /output/output.txt
						"""#
				},
			]
		}
		delete: {
			run: bash.#Run & {
				input:   runDelete.output
				workdir: "/src"
				script: contents: #"""
					"""#
			}
			contents: dagger.#Subdir & {
				input: run.output.rootfs
				path:  "/output"
			}
		}
	}
}
