function dc {
    if [ -f "docker-compose.dev.yml" ]; then
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml "$@";	
    else
        docker-compose "$@";
    fi;
}
