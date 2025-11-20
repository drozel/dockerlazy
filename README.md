# docker-lazy

A set of helper functions for Docker CLI, especially useful for managing Docker Swarm clusters across multiple contexts.

## Overview

Docker-lazy assumes you are using Docker contexts, grouped into namespaces to manage multiple environments. Different nodes of one cluster would be contexts in the same namespace.

For example, if you have a context named `dev-cluster.1` and another named `dev-cluster.2`, they belong to the same namespace `dev-cluster` and docker-lazy will be able to find containers across them.

## Commands

- `dlazy-help` - Display help information
- `dlazy-find <container_name>` - Find container(s) by name in the current context (partial search supported)
- `dlazy-find-in-cluster <container_name>` - Find and switch to the context running a container with the desired name
- `dlazy-exec <container_name>` - Exec bash (or sh as fallback) in a Docker container by name across all contexts from the same namespace
- `dlazy-foreach-svc <filter> <action>` - Execute an action on all services matching the filter

## Installation

### Using Zinit

Add the following to your `~/.zshrc`:

```zsh
zinit light drozel/dockerlazy
```

Then reload your shell:

```zsh
source ~/.zshrc
```

### Using Oh-My-Zsh

1. Clone this repository into Oh-My-Zsh's plugins directory:

```zsh
git clone https://github.com/drozel/dockerlazy.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/docker-lazy
```

2. Add `docker-lazy` to the plugins array in your `~/.zshrc`:

```zsh
plugins=(... docker-lazy)
```

3. Reload your shell:

```zsh
source ~/.zshrc
```

### Manual Installation

Clone this repository and source the plugin file in your `~/.zshrc`:

```zsh
git clone https://github.com/drozel/dockerlazy.git ~/.docker-lazy
echo "source ~/.docker-lazy/dockerlazy.plugin.zsh" >> ~/.zshrc
source ~/.zshrc
```

## Usage Examples

### Find a container by name
```zsh
dlazy-find myapp
```

### Find a container across cluster contexts
```zsh
dlazy-find-in-cluster web-server
```

### Execute a command in a container
```zsh
dlazy-exec myapp
```

### Perform action on multiple services
```zsh
dlazy-foreach-svc database rm
```

This will execute `docker service rm` for each service containing "database" in its name.

## Requirements

- Docker
- Zsh shell
- Docker contexts configured (for cluster operations)

## License

MIT
