function dc {
    if [ -f "docker-compose.dev.yml" ]; then
        docker-compose -f docker-compose.dev.yml "$@";	
    elif [ -f "dev/docker-compose.yml" ]; then
        docker-compose -f dev/docker-compose.yml "$@";
    elif [ -f "docker/docker-compose.yml" ]; then
        docker-compose -f docker/docker-compose.yml "$@";
    else
        docker-compose "$@";
    fi;
}
