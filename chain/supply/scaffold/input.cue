package scaffold

#Repository: {
	// Repository name
	name: string

	// Repository type
	"type": string | *"frontend" | "backend" | "deploy"

	// Framework
	framework: string | *"gin" | "helm" | "next" | "react" | "vue"

	// TODO Repository visibility
	visibility: string | *"public" | "private"

	// CI
	ci: string | *"github"

	// Addons
	addons?: [...]
}

#Input: {
	provider:     string | *"github"
	organization: string
	repository: [...#Repository]
}
