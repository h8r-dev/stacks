# Sample

This is a sample stack to demonstrate the stack format.

## 什么是 Stack?

Stack 是一套面向开发者设计的、围绕某一类应用开发框架设计的云原生最佳实践。
比如我们有 Java Spring Stack, Go Gin Stack，等等。
开发者专注于编写业务代码，使用 Stack 就可以快速使用上云原生能力，享受云原生带来的红利。

## Stack 格式

- `metadata.yaml`: 描述 Stack metadata，如 version/description/url 等
- `schemas`: 暴露给用户的 Schema，可用于生成用户可读的表单
- `plans`: 交付云原生应用的执行计划，比如生成并 apply k8s 资源
