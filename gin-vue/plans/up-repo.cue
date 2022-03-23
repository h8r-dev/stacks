// package main

// import (
//  "dagger.io/dagger"
//  "universe.dagger.io/alpine"
//  "universe.dagger.io/bash"
//  "universe.dagger.io/docker"
// )

// dagger.#Plan & {
//  client: {
//   filesystem: "code/": read: contents: dagger.#FS
//   env: {
//    GITHUB_TOKEN: dagger.#Secret
//    APP_NAME:     string
//   }
//  }

//  actions: {
//   deps: docker.#Build & {
//    steps: [
//     alpine.#Build & {
//      packages: {
//       bash: {}
//       curl: {}
//       git: {}
//       jq: {}
//       yq: {}
//      }
//     },
//     docker.#Copy & {
//      contents: client.filesystem."code/".read.contents
//      dest:     "/src"
//     },
//     bash.#Run & {
//      env: GITHUB_TOKEN: client.env.GITHUB_TOKEN
//      script: contents: #"""
//       mkdir /output /github
//       curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /github/user.json
//       curl -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/emails > /github/email.json
//       """#
//     },
//    ]
//   }
//   up: initRepos: {
//    backend: #GithubCreate & {
//     input:   deps.output
//     workdir: "/src/go-gin"
//     #suffix: "-backend"
//    }
//    frontend: #GithubCreate & {
//     input:   deps.output
//     workdir: "/src/vue-front"
//     #suffix: "-frontend"
//    }
//    deploy: {
//     prepare: bash.#Run & {
//      input:   deps.output
//      workdir: "/src/helm"
//      env: APP_NAME:      client.env.APP_NAME
//      env: BACKEND_NAME:  "\(env.APP_NAME)\(backend.#suffix)"
//      env: FRONTEND_NAME: "\(env.APP_NAME)\(frontend.#suffix)"
//      script: contents: #"""
//       export GITHUB_USER=$(cat /github/user.json | jq -r '.login')
//       yq eval -i '.image.repository="ghcr.io/'$GITHUB_USER'/'$BACKEND_NAME'"' values.yaml
//       yq eval -i '.frontImage.repository="ghcr.io/'$GITHUB_USER'/'$FRONTEND_NAME'"' values.yaml
//       yq eval -i '.nocalhost.backend.dev.gitUrl="git@github.com:'$GITHUB_USER'/'$BACKEND_NAME.git'"' values.yaml
//       yq eval -i '.nocalhost.frontend.dev.gitUrl="git@github.com:'$GITHUB_USER'/'$FRONTEND_NAME.git'"' values.yaml
//       yq eval -i '.name="$APP_NAME"' Chart.yaml
//       """#
//     }
//     run: #GithubCreate & {
//      input:   prepare.output
//      workdir: "/src/helm"
//      #suffix: "-deploy"
//     }
//    }
//   }
//  }

//  #GithubCreate: bash.#Run & {
//   #appname: client.env.APP_NAME
//   #suffix:  string
//   #token:   client.env.GITHUB_TOKEN

//   env: REPO_NAME:    "\(#appname)\(#suffix)"
//   env: GITHUB_TOKEN: #token
//   script: contents: #"""
//    curl -XPOST -d '{"name":"'$REPO_NAME'"}' -sH "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos > /github/repo.json
//    export GITHUB_USER=$(cat /github/user.json | jq -r '.login')
//    export GITHUB_EMAIL=$(cat /github/email.json | jq -r '[.[] | .email] | .[0]')
//    export HTTPS_URL=https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git
//    git config --global user.name $GITHUB_USER
//    git config --global user.email $GITHUB_EMAIL

//    git init
//    git add .
//    git commit -m "first commit"
//    git branch -M main
//    git remote add origin $HTTPS_URL
//    git push -u origin main
//    """#
//  }
// }
