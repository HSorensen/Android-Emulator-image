#!/bin/bash

readonly G_LOG_I='[INFO]'
readonly G_LOG_W='[WARN]'
readonly G_LOG_E='[ERROR]'
BL='\033[0;34m'
G='\033[0;32m'
NC='\033[0m' # No Color

main() {
    printf "${G}==> ${BL}Welcome to android-emulator VNC based on amrsa ${G}<==${NC}""\n"
    launch_android_sdk
    launch_dbus
    launch_xvfb
#    launch_xephyr
    launch_window_manager
    run_vnc_server
}

launch_android_sdk() {
    echo "${G_LOG_I} Launching android sdk."
    # check android commandline tools are in the right place
    if [ -z $ANDROID_SDK_ROOT ]; then
    echo "${G_LOG_W} Check setup. Missing ANDROID_SDK_ROOT."
    return
    fi

    if [ ! -f $ANDROID_SDK_ROOT/cmdline-tools/NOTICE.txt ]; then
    pushd /root > /dev/null
    echo "${G_LOG_I} Activating Android tools. ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
    mkdir -p $ANDROID_SDK_ROOT/cmdline-tools 
    cd /root/cmdline-tools && mv NOTICE.txt source.properties bin lib $ANDROID_SDK_ROOT/cmdline-tools/
    popd > /dev/null
    fi 

    if [ ! -f $ANDROID_SDK_ROOT/platform-tools/apkanalyzer ]; then
    # To statisfy appium driver doctor uiautomator2
    echo "${G_LOG_I} Activating Android tools apkanalyzer."
    ln -s /root/cmdline-tools/bin/apkanalyzer $ANDROID_SDK_ROOT/platform-tools/apkanalyzer
    fi 


}

launch_dbus() {
    echo "${G_LOG_I} Launching dbus."
    # ensure dbus is running for Awsome
    local dbus_status=`/etc/init.d/dbus status | grep "not running"`
    if [  "${dbus_status}" ]; then
    echo "${G_LOG_I} starting dbus."
    /etc/init.d/dbus start
    fi
}

launch_xvfb() {
    echo "${G_LOG_I} Launching xvfb."
    # Set defaults if the user did not specify envs.
    export DISPLAY=${XVFB_DISPLAY:-:0}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-1280x1024x24}
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either Xvfb to be fully up or we hit the timeout.
    Xvfb ${DISPLAY} -ac -screen ${screen} ${resolution} &
    local loopCount=0
    until xdpyinfo -display ${DISPLAY} > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            echo "${G_LOG_E} xvfb failed to start."
            exit 1
        fi
    done
}

launch_xephyr() {
    echo "${G_LOG_I} Launching xephyr."
    # Set defaults if the user did not specify envs.
    export DISPLAY=${XVFB_DISPLAY:-:1}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-1280x1024x24}
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either Xvfb to be fully up or we hit the timeout.
    # Xephyr ${DISPLAY} -screen ${screen} ${resolution} &
    Xephyr  &
    local loopCount=0
    until xdpyinfo -display ${DISPLAY} > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            echo "${G_LOG_E} xephyr failed to start."
            exit 1
        fi
    done
}

launch_window_manager() {
    echo "${G_LOG_I} Launching window manager."
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either fluxbox to be fully up or we hit the timeout.
    # fluxbox &
    cinnamon &
    #muffin &
    #openbox &
    #awesome &
    local loopCount=0
    until wmctrl -m > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            echo "${G_LOG_E} window manager failed to start."
            exit 1
        fi
    done
}

run_vnc_server() {
    echo "${G_LOG_I} Launching vnc server."
    local passwordArgument='-nopw'
    local xvncparms='-ncache 10'

    if [ -n "${VNC_PASSWORD}" ]
    then
        local passwordFilePath="${HOME}/x11vnc.pass"
        if ! x11vnc -storepasswd "${VNC_PASSWORD}" "${passwordFilePath}"
        then
            echo "${G_LOG_E} Failed to store x11vnc password."
            exit 1
        fi
        passwordArgument=-"-rfbauth ${passwordFilePath}"
        echo "${G_LOG_I} The VNC server will ask for a password."
    else
        echo "${G_LOG_W} The VNC server will NOT ask for a password."
    fi

    x11vnc -ncache_cr -ncache 10 -display ${DISPLAY} -forever ${passwordArgument} &
    wait $!
}


control_c() {
    echo ""
    exit
}

trap control_c SIGINT SIGTERM SIGHUP

main

exit