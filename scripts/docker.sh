function dc {
    if [ -f "docker-compose.debug.yml" ]; then
        docker compose -f docker-compose.yml -f docker-compose.debug.yml "$@";	
    else
        docker compose "$@";
    fi;
}
