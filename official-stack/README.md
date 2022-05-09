# Official-stack

## How to create new stack
We will create `spring-vue` stack to example.

### 1. Initialize spring boot project
create a new spring boot project. you can use IDEA or use [start-spring-web](https://start.spring.io/) to create a new project.
> We weill use docker to run the project, we need add `dockerfile` to the project.

### 2. Create new framework and copy template files
create new spring framework
```shell
mkdir /stacks/chain/components/framework/spring
mkdir /stacks/chain/components/framework/spring/template

cp -r ${your spring boot project directory} /stacks/chain/components/framework/spring/template/
```

### 3. Create cue file
```shell
nano /stacks/chain/components/framework/spring/input.cue
```
```
package spring

import (
	"universe.dagger.io/docker"
)

#Input: {
	name:  string // application name
	image: docker.#Image
}
```
```shell
touch /stacks/chain/components/framework/spring/output.cue
```
```
package spring

import (
	"universe.dagger.io/docker"
)

#Output: {
	image:   docker.#Image
	success: bool | *true
}
```
```shell
touch /stacks/chain/components/framework/spring/spring.cue
```
```
package spring

import (
	"universe.dagger.io/docker"
	"dagger.io/dagger/core"
)

#Instance: {
	input: #Input
	_file: core.#Source & {
		path: "template" // path to template directory
	}
	do: docker.#Copy & {
		"input":  input.image
		contents: _file.output
		dest:     "/scaffold/\(input.name)"
	}
	output: #Output & {
		image: do.output
	}
}
```

### 4. Create stack
create spring-vue stack
```shell
mkdir /stacks/official-stack/spring-vue
```
- add cue modules to `/spring-vue/cue.mods` stack directory
```go
module github.com/h8r-dev/stacks/offcial-stacks/spring-vue

cue 0.4.0

require (
  github.com/h8r-dev/stacks/chain v0.0.0
)

replace github.com/h8r-dev/stacks/chain => ../../chain
```

- create `schemas/schema.yaml` file
- create `plans/plan.cue` file
```cue
package main

dagger.#Plan & {
	client: {
		...
	}

	actions: {
		...
		_scaffold: scaffoldfactory.#Instance & {
			input: scaffoldfactory.#Input & {
				scm:                 "github"
				organization:        client.env.ORGANIZATION
				personalAccessToken: client.env.GITHUB_TOKEN
				repository: [
					// this is vue project
					{
						name:      client.env.APP_NAME + "-frontend"
						type:      "frontend"
						framework: "vue"
						ci:        "github"
						registry:  "github"
					},
					// this is spring boot project
					{
						name:      client.env.APP_NAME + "-backend"
						type:      "backend"
						framework: "spring"
						ci:        "github"
						registry:  "github"
						deployTemplate: {
							helmStarter: "spring-boot"
						}
					},
					// this is helm repo
					{
						name:      client.env.APP_NAME + "-deploy"
						type:      "deploy"
						framework: "helm"
					},
				]
				addons: [
					// if you want to use other addons, add them here
					...
				]
			}
		}

		_git: scmfactory.#Instance & {
			...
		}

		up: {
			...
		}
	}
}
```

- in stacks directory execute `make watch` to watch the changes and update project