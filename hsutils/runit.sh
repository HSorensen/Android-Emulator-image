#!/usr/bin/bash

docker build --format docker -t android-emulator .
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building image: $retVal"
    return $retVal
fi


docker run --rm -it -d -p 5900:5900 --name androidContainer --hostname avd_docker --volume $PWD/android:/root/Android --device=/dev/kvm -e VNC_PASSWORD=password --privileged android-emulator
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error running image: $retVal"
    return $retVal
fi

# get container id
CONTAINERID=`docker container ls --all | grep androidContainer | cut -d" " -f1`

echo "Started container $CONTAINERID"

docker exec --privileged -it androidContainer bash -c "./start_vnc_hs.sh"

echo "Stopping container $CONTAINERID ... "

docker stop $CONTAINERID

echo "Container stopped."
