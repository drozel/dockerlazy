function dlazy-help() {
    echo "dlazy - Docker lazy commands"
    echo "Docker-lazy is a set of helper functions for Docker CLI, especially useful for managing Swarm clusters."
    echo ""
    echo "Docker-lazy assumes you are using Docker contexts, grouped into namespaces to manage multiple environments. Different nodes of one cluster would be contexts in the same namespace."
    echo "For example, if you have a context named 'dev-cluster.1' and another named 'dev-cluster.2', they belong to the same namespace 'dev-cluster' and Docker-lazy will be able to find containers across them (e.g. using dlazy-find-in-cluster)."
    echo ""
    echo "Commands:"
    echo "  dlazy-help                             Prints this help."
    echo "  dlazt-find <container_name>            Returns the ID os a container matching to given name (partial search). Uses only current context."
    echo "  dlazy-find-in-cluster <container_name> Find the contexts running a container with desired name starting with the current one. Contexts are expected to be grouped into namespaces."
    echo "  dexecp <container_name>       Exec bash (or sh as fallback) in a Docker container by name across all contexts from the same namespace."
    echo "  dlogs <container_name>        Show logs for a Docker container by name in the current context."
    echo "  dforservice <filter> <action> Execute an action on all services matching the filter."
}
function dlazy-find() {
    if [[ $1 == "--help" ]]; then
        echo "Usage: $0 <container_name>"
        echo "Find a Docker container(s) by name in the current context. Returns the container ID(s). Name can be partial."
        return 0
    fi

    containers=$(docker ps --filter "name=$1" --format "{{.ID}}")
    echo $containers
}

function dlazy-find-in-cluster() {
    if [[ $1 == "--help" ]]; then
        echo "Usage: $0 <container_name>"
        echo "Find a Docker container by name across all contexts from the same namespace and switch to it."
        return 0
    fi

    container_name=$1
    current_context=$(docker context show)
    base_name="${current_context%\.*}"
    local available_contexts=("${(@f)$(docker context ls --format "{{.Name}}" | grep "^$base_name")}")

    # Ensure the current context is the first in the list
    available_contexts=("$current_context" "${(@)available_contexts:#$current_context}")

    for target_context in "${available_contexts[@]}"; do
        echo "Checking context: $target_context"

        docker context use "$target_context" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Failed to switch to context $target_context, skipping."
            continue
        fi

        # Check for the container by name in the target context
        container_id=$(dlazy-find $container_name)
        if [ -n "$container_id" ]; then
            echo "Container '$container_name' found in context $target_context"
            echo "Switched to context $target_context"
            return 0
        fi
    done
    echo "Container '$container_name' not found in any context."
    docker context use "$current_context" >/dev/null 2>&1
    return 1
}

function dlazy-exec() {
    if [[ $1 == "--help" ]]; then
        echo "Usage: $0 <container_name>"
        echo "Exec bash (or sh as fallback) in a Docker container by name across all contexts from the same namespace. Enters the first found if multiple."
        return 0
    fi
    dlazy-find-in-cluster $1
    if [ $? -ne 0 ]; then
        echo "Container '$1' not found in any context."
        return 1
    fi

    container_ids=$(dlazy-find $1)
    if [[ $(echo "$container_ids" | wc -l) -ne 1 ]]; then
        container_ids=$(echo "$container_ids" | head -n 1)
        container_name=$(docker ps --filter "id=$container_ids" --format "{{.Names}}")
        echo "Found more than one container on the node, using the first: $container_name"
    fi

    docker exec -it $container_ids bash || docker exec -it $container_ids sh 
}

function dlazy-foreach-svc() {
    if [[ $1 == "--help" ]]; then
        echo "Usage: $0 <service_name> <action>"
        echo "Execute an action on all services matching the filter. E.g.: `$0 database rm` will invoke `docker service rm <service>` multiple times for each service having <service_name> in its name."
        return 0
    fi
    local filter="$1"
    shift
    local action="$1"
    shift
    for n in $(docker service ls --filter name="$filter" -q); do
        eval "$action $@" "$n"
    done
}