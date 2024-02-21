#!/usr/bin/bash
#  Build and Start container
#  
#  If container already exists
# ---
# Status of container
# See https://docs.podman.io/en/latest/markdown/podman-container-inspect.1.html
# docker container inspect androidCinnamon --format "{{.Name}} {{.State.Status}} {{.State.StartedAt}} {{.State.FinishedAt}}"
#
# Options
#   - status
#   - pause / resume: Pause will keep VNC session open but frozen. Resume will thaw the session.
#   - start / stop: Start will bring up a new instance. In instance is not found the it will be started using run. Stop will stop the instance
#   - rebuild
#   - remove
#

readonly G_LOG_I='[INFO]'
readonly G_LOG_W='[WARN]'
readonly G_LOG_E='[ERROR]'
BL='\033[0;34m'
G='\033[0;32m'
NC='\033[0m' # No Color

DOCKERFILE=Dockerfile.cinnamon
CONTAINER=androidCinnamon
IMAGE=android-emulator-cinnamon
HOSTNAME=avd_cinnamon
CONTAINERID=
CONTAINERSTATUS=

progname=$(basename $0)
ARG_BUILD=0
ARG_STATUS=0
ARG_RUN=0
ARG_VERBOSE=0

# usage function
usage()
{
   printf "
   Usage: $progname [--status] [--build] [--run] [--verbose]

   optional arguments:
     -h, --help           show this help message and exit
     -s, --status         show status of container
     -b, --build          build container. ${G}Note${NC} Container is unpaused or stopped then removed before builing
     -r, --run            run container
     -v, --verbose        verbose output. vv for very verbose
     "
}  

parse_args() {
# use getopt and store the output into $OPTS
# note the use of -o for the short options, --long for the long name options
# and a : for any option that takes a parameter

OPTS=$(getopt -o "hsbrv" --long "help,status,build,run,verbose" -n "$progname" -- "$@")
if [ $? != 0 ] ; then echo "Error in command line arguments." >&2 ; usage; return; fi

if [ "$OPTS" == " --" ]; then usage; return; fi

eval set -- "$OPTS"

while true; do
  # uncomment the next line to see how shift is working
  # echo "\$1:\"$1\" \$2:\"$2\""
  case "$1" in
    -h | --help ) usage; exit; ;;
    -s | --status ) ARG_STATUS=1; shift ;;
    -b | --build )  ARG_BUILD=1; shift ;;
    -r | --run )    ARG_RUN=1; shift ;;
    -v | --verbose ) ARG_VERBOSE=$((ARG_VERBOSE + 1)); shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ $ARG_VERBOSE -gt 1 ]; then
   # print out all the parameters we read in
   printf "${G_LOG_I} ARG_BUILD=$ARG_BUILD
${G_LOG_I} ARG_STATUS=$ARG_STATUS
${G_LOG_I} ARG_RUN=$ARG_RUN
${G_LOG_I} ARG_VERBOSE=$ARG_VERBOSE
${G_LOG_I} DOCKERFILE=$DOCKERFILE
${G_LOG_I} CONTAINER=$CONTAINER
${G_LOG_I} IMAGE=$IMAGE
${G_LOG_I} HOSTNAME=$HOSTNAME
"
fi

}

main() {
  printf "${G}==> ${BL}Welcome to cinnamon docker desktop ${G}<==${NC}""\n"
  [ $ARG_STATUS -gt 0 ] && launch_docker_status
  [ $ARG_BUILD -gt 0  ] && launch_docker_build
  [ $ARG_RUN -gt 0    ] && launch_docker_run
  [ $ARG_RUN -gt 0    ] && launch_docker_prompt
}

launch_docker_status() {
    #
    # Status
    #   running: Up 17 minutes ago
    #   paused: paused
    #   stopped: Exited (137) 6 seconds ago
    #   notfound: not found
    #
    local status=()
    IFS='>' read -r -a status <<< `docker container ls --all --format "{{.Names}}>{{.ID}}>{{.State}}" | grep -w $CONTAINER `
    local w1=$(echo -n ${status[2]} | cut -d" " -f1)
    case "$w1" in
      Up ) CONTAINERSTATUS=running ;;
      Exited ) CONTAINERSTATUS=stopped ;;
      paused ) CONTAINERSTATUS=paused ;;
      "" ) CONTAINERSTATUS=notfound ;;
      * ) CONTAINERSTATUS=unknown ;;
    esac
    
    [ $ARG_STATUS  -gt 0 ] && printf "${G_LOG_I} Status ${status[0]} ${status[1]} ${status[2]} $CONTAINERSTATUS""\n"
    [ $ARG_VERBOSE -gt 0 ] && [ $ARG_STATUS  -eq 0 ] && printf "${G_LOG_I} Status ${status[0]} ${status[1]} ${status[2]} $CONTAINERSTATUS""\n"
    [ $ARG_VERBOSE -gt 1 ] && printf "${G_LOG_I} Status first word ${w1}""\n"
}

launch_docker_build() {
    printf "${G_LOG_I} Building image $IMAGE using $DOCKERFILE ....""\n"
    # check if container already exists or is running
    # get CONTAINERSTATUS
    [ $ARG_STATUS -eq 0 ] && launch_docker_status

    case "$CONTAINERSTATUS" in
       # note: ;& is fallthrough
       # paused: unpause, stop, remove
       # running: stop, remove
       # stopped: remove
       # notfound: proceed with build
      paused  ) [ $ARG_VERBOSE -gt 0 ] && printf "${G_LOG_I} Unpausing container ${CONTAINER}""\n";
                 docker container unpause $CONTAINER;
                 ;&
      running ) [ $ARG_VERBOSE -gt 0 ] && printf "${G_LOG_I} Stopping container ${CONTAINER}""\n";
                 docker container stop $CONTAINER;
                 ;&
      stopped ) [ $ARG_VERBOSE -gt 0 ] && printf "${G_LOG_I} Removing container ${CONTAINER}""\n";
                 docker container rm $CONTAINER;
                 ;;
      notfound ) ;;
              *) printf "${G_LOG_E} Unexpected container status $CONTAINERSTATUS. Check setup.""\n"; exit 8; ;;
    esac

    docker build --format docker -f $DOCKERFILE -t $IMAGE .
    retVal=$?
    if [ $retVal -ne 0 ]; then
        printf "${G_LOG_E} Building image: $retVal""\n"
        ARG_RUN=0
        return $retVal
    fi
    printf "${G_LOG_I} Building image $IMAGE using $DOCKERFILE .... DONE""\n"
}

launch_docker_run() {
    # check if container already is running
    printf "${G_LOG_I} Starting image $IMAGE name $CONTAINER hostname $HOSTNAME ....""\n"
    docker run -it --detach --publish 5902:5902 --publish 3389:3389 --name $CONTAINER --hostname $HOSTNAME $IMAGE
    retVal=$?
    if [ $retVal -ne 0 ]; then
        printf "${G_LOG_E} Running image: $retVal""\n"
        return $retVal
    fi

    # get container id
    CONTAINERID=`docker container ls --all | grep $CONTAINER | cut -d" " -f1`

    printf "${G_LOG_I} Started container $CONTAINERID""\n"
    printf "${G_LOG_I} ... Switch to ${G}TigerVNC Viewer${NC} localhost:5902""\n"

}

launch_docker_prompt() {
    printf "${G_LOG_I} Started prompt inside container $CONTAINERID. Note exit from this prompt will stop the container.""\n"

    docker exec -it $CONTAINERID bash

    printf "${G_LOG_I} Stopping container $CONTAINERID ... ""\n"

    docker stop $CONTAINERID

    printf "${G_LOG_I} Container stopped.""\n"
}

control_c() {
    echo ""
    exit
}

trap control_c SIGINT SIGTERM SIGHUP

parse_args "$@"

main

#exit