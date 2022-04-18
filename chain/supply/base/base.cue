package base

#Addons: {
	name:     string | "prometheus" | "loki" | "nocalhost"
	version?: string
}

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

	// Helm set values
	// Format: '.image.repository = "rep" | .image.tag = "tag"'
	set?: string | *""
}
