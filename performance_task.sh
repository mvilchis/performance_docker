#! /usr/bin/bash

POSTGRES_CONTAINER="postgres-prueba-rp"
RAPIDPRO_CONTAINER="rapidpro-prueba-rp"
CELERY_CONTAINER="rp-celery-rp"
REDIS_CONTAINER="redis-prueba-rp"
PATH_RAPIDPRO="./rapidpro"
RAPIPRO_IMAGE="rapidpro:v1.4.20"
##########################################################
#             Remove all old dockers
function remove  {
  for i in "${containers[@]}"
  do
    docker rm -f i
  done
}
function pp() {
echo $POSTGRES_MEM
}
##########################################################
#             First create Docker of postgres

function  create_postgres(){
  result=`docker images --format "{{.Repository}}:{{.Tag}}" | grep "postgres-rp:latest"`
  if [ -z "$result" ]; then
      docker build -t postgres-rp $PATH_RAPIDPRO/docker_postgres
  else
    echo "Imagen postgres-rp creada"
  fi

  is_running=`docker ps -a --format "{{.Names}}"|grep "${POSTGRES_CONTAINER}"`
  if [ -z "$is_running" ]; then
    docker run --name $POSTGRES_CONTAINER --memory=$POSTGRES_MEM -e TEMBAPASSWD=supersecret -d postgres-rp ||{
      echo "$POSTGRES_CONTAINER error"
    }
    sleep 20s
    docker cp tmp.sql  $POSTGRES_CONTAINER:/tmp/tmp.sql
    remove_temba="UPDATE pg_database SET datistemplate='false' WHERE datname='temba'; DROP DATABASE temba;"
    create_temba="CREATE DATABASE temba"
    update_temba="psql temba < /tmp/tmp.sql"
    docker exec -i  $POSTGRES_CONTAINER psql -U postgres <<EOF
    $remove_temba
    $create_temba
EOF
    docker exec -i  $POSTGRES_CONTAINER   bash <<EOF
    su postgres
    psql
    $update_temba
EOF
  else
    echo "$POSTGRES_CONTAINER corriendo"
  fi
}

function connect_containers() {
  result=`docker images --format "{{.Repository}}:{{.Tag}}" | grep "$RAPIPRO_IMAGE"`
  if [ -z "$result" ]; then
    docker build -t rapidpro-prueba $PATH_RAPIDPRO
  else
    echo "Imagen rapidpro-prueba ya creada"
  fi

  is_running=`docker ps --format "{{.Names}}"|grep "${RAPIDPRO_CONTAINER}"`
  if [ -z "$is_running" ]; then
    docker run --name $REDIS_CONTAINER -p 6379:6379 -d redis &> /dev/null ||{
      echo "Redis ya esta corriendo"
    }
    docker run  --name $RAPIDPRO_CONTAINER --link $POSTGRES_CONTAINER:postgres --link $REDIS_CONTAINER:redis \
    -e SEND_MAIL=True \
    -e DEBUG=False \
    -e EMAIL_HOST_USER=rapidpro@email.com \
    -e EMAIL_HOST_PASSWORD=supersecret \
    -e DEFAULT_LANGUAGE=es \
    -e SEND_WEBHOOKS=True  \
    -e SECRET_KEY=supersecret \
    -e CONTAINER_INIT=start_rapidpro.sh \
    -e SEND_MESSAGES=True -p 8000:8000 -d $RAPIPRO_IMAGE
  else
    echo "$RAPIDPRO_CONTAINER corriendo"
  fi
  is_running=`docker ps --format "{{.Names}}"|grep "${CELERY_CONTAINER}"`
  if [ -z "$is_running" ]; then
    docker run  --name $CELERY_CONTAINER --link $POSTGRES_CONTAINER:postgres --link $REDIS_CONTAINER:redis \
    -e SEND_MAIL=True \
    -e DEBUG=False \
    -e EMAIL_HOST_USER=rapidpro@email.com \
    -e EMAIL_HOST_PASSWORD=supersecret \
    -e DEFAULT_LANGUAGE=es \
    -e SEND_WEBHOOKS=True  \
    -e SECRET_KEY=supersecret \
    -e CONTAINER_INIT=start_celery.sh \
    -e SEND_MESSAGES=True -p 5555:5555 -d $RAPIPRO_IMAGE
  else
    echo "$RAPIDPRO_CONTAINER corriendo"
  fi
}


function main() {
  POSTGRES_MEM="${@:2}"
  case "$1" in
    "--all")
      create_postgres;
      connect_containers;
      sleep 10s;
      docker stats $POSTGRES_CONTAINER  | grep -v "CPU" >> performance_postgres &
      docker stats $RAPIDPRO_CONTAINER  | grep -v "CPU" >> performance_rapidpro &
      nohup python prueba_estres.py &> mensajes_aceptados;
      shift;;
    "--postgres")
      create_postgres;
      connect_containers;
      sleep 10s;
      docker stats $POSTGRES_CONTAINER  | grep -v "CPU" >> performance_postgres &
      docker stats $RAPIDPRO_CONTAINER  | grep -v "CPU" >> performance_rapidpro &
      nohup python prueba_estres.py &> mensajes_aceptados;
      shift;;
    "--rapidpro")
      connect_containers;
      sleep 10s;
      docker stats $POSTGRES_CONTAINER  | grep -v "CPU" >> performance_postgres &
      docker stats $RAPIDPRO_CONTAINER  | grep -v "CPU" >> performance_rapidpro &
      nohup python prueba_estres.py &> mensajes_aceptados;
      shift;;
  esac

}

main "$@"
