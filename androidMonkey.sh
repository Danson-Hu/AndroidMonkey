#!/bin/bash

LOGS_PATH="logs"
TOOLS_PATH="tools"
SCRIPT_PATH="script"

ANDROID_WORKSPACE="/data/workspace"
ANDROID_TOOLS_PATH="${ANDROID_WORKSPACE}/tools"
ANDROID_SCRIPT_PATH="${ANDROID_WORKSPACE}/script"
ANDROID_LOG_PATH="${ANDROID_WORKSPACE}/androidLog"

function usage() {
    echo_green "Usage:
    Input 0: run monkey
    Input 1: stop monkey
    Input 2: pull log
    "
}

function echo_red() {
    echo -e "\033[31m$1\033[0m"
}

function echo_green() {
    echo -e "\033[32m$1\033[0m"
}

function adb_remount() {
    echo_green "Remount adb..."
    adb root
    adb remount
    adb "wait-for-device"
}

function evn_setup() {
    echo_green "Setup env..."
    adb_remount;
    adb shell "mkdir -p ${ANDROID_TOOLS_PATH}"
    adb shell "mkdir -p ${ANDROID_SCRIPT_PATH}"
    adb push ${TOOLS_PATH}/busybox ${ANDROID_TOOLS_PATH}
    adb push ${SCRIPT_PATH}/captureLog.sh ${ANDROID_SCRIPT_PATH}
    adb shell "chmod 777 ${ANDROID_TOOLS_PATH}/busybox"
    adb shell "chmod 777 ${ANDROID_SCRIPT_PATH}/captureLog.sh"
}

function log_capture() {
    echo_green "Execution captureLog.sh..."
    adb shell "sh ${ANDROID_SCRIPT_PATH}/captureLog.sh &" &
    echo_green "Wait for 10s and check whether the log is being fetched..."
    sleep 10
    adb shell ls -l ${ANDROID_LOG_PATH}
    file_number=$(adb shell ls -l ${ANDROID_LOG_PATH} | wc -l)
    if [ ${file_number} -gt 3 ]
    then
        echo_green "Log fetching,wait for 30s and ls -l ${ANDROID_LOG_PATH}"
        sleep 30
        adb shell ls -l ${ANDROID_LOG_PATH}
    else
        echo_red "Not fetching log,try again..."
        log_capture;
    fi
}

function start_monkey() {
    evn_setup;
    echo_green "Execution monkey command..."
    adb shell monkey -p com.android.calculator2 -v -v -v -s 1500 --throttle 2000 1000 > ${LOGS_PATH}/monkey.log &
    sleep 5
    adb shell ps | grep com.android.commands.monkey
    if [ $? -eq 0 ]
    then
        echo_green "Monkey is running..."
        log_capture;
    else
        echo_red "Monkey not running,try again..."
        run_monkey;
    fi
}

function stop_monkey() {
    adb shell ps | grep com.android.commands.monkey
    if [ $? -eq 0 ]
    then
        monkey_process=$(adb shell ps | grep com.android.commands.monkey | awk '{print $2}')
        echo_green "Stop monkey process..."
        adb shell kill -9 "${monkey_process}"
        sleep 2
        stop_monkey;
    else
        echo_green "Monkey has stopped."
        pull_logs;
    fi
}

function pull_logs() {
    echo_green "Pull android logs..."
    adb_remount;
    adb pull /data/system/dropbox ${LOGS_PATH}
    adb pull ${ANDROID_LOG_PATH} ${LOGS_PATH}
}

usage;
read -p "Please enter what you want to do[0/1/2]? " cmd
if [ ${cmd} -eq 0 ]
then
    start_monkey;
elif [ ${cmd} -eq 1 ]
then
    stop_monkey;
elif [ ${cmd} -eq 2 ]
then
    pull_logs;
else
    echo_red "Please enter 0 or 1 or 2!"
    exit 0
fi