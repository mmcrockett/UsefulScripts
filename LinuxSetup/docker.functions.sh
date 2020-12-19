function docker-list-tags {
  local NAMESPACE=$1

  if [ -z "${NAMESPACE}" ]; then
    echo "Need the namespace example 'library/debian'" && return 1
  fi

  command -v jq >/dev/null 2>&1

  if [ "0" -eq "$?" ]; then
    i=0

    while [ $? == 0 ]; do 
      i=$((i+1))
      curl https://registry.hub.docker.com/v2/repositories/${NAMESPACE}/tags/?page=$i 2>/dev/null|jq '."results"[]["name"]'
    done
  else
    abort 'Need jq installed.'
  fi
}
function dockercompose-do {
  if [ -f "${DOCKERCOMPOSE_FILE}" ]; then
    docker-compose --file "${DOCKERCOMPOSE_FILE}" "${@}"
  elif [ -d "${DOCKERCOMPOSE_HOME}" ]; then
    local _PWD="${PWD}"
    cd ${DOCKERCOMPOSE_HOME} && docker-compose "${@}"
    local _RESULT=$?
    cd ${_PWD}
    return $_RESULT
  else
    echo 'Expected DOCKERCOMPOSE_HOME to be set.'
    return 1
  fi
}
function docker-start {
  dockercompose-do up -d
}
function docker-start-rebuild {
  dockercompose-do up --build -d
}
function docker-stop {
  dockercompose-do down
}
function docker-restart {
  docker-stop && docker-start && docker system prune -f
}
function docker-restart-rebuild {
  docker-stop && docker-start-rebuild && docker system prune -f
}
function docker-ps-short {
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Command}}\t{{.Ports}}\t{{.Status}}"
}
function docker-switch-to-local-rails {
  if [ -n "${DOCKERCOMPOSE_HOME}" ]; then
    local DOCKER_PID="$(docker ps -q --filter "name=.*app.*")"
    local API_DIR="${WORKSPACE_HOME}/weinfuse_api"

    if [ -n "${DOCKER_PID}" ]; then
      docker kill ${DOCKER_PID} && rm ${API_DIR}/tmp/pids/server.pid
    fi

    cd ${API_DIR} && rails server --port 3000 --binding 0.0.0.0
  fi
}
