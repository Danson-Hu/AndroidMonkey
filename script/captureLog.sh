#!/system/bin/sh

start_date=$(date "+%Y-%m-%d %H:%M:%S")
start_timestamp=$(date +%s)

WORKSPACE="/data/workspace"
GREP="busybox grep"
AWK="busybox awk"
HEAD="busybox head"
TAIL="busybox tail"
SED="busybox sed"

logPath=$WORKSPACE/androidLog
mkdir -p $logPath

function killLog() {
    killProcess logcat
    killProcess top
    killProcess kmsg
    killProcess procrank
}

function killProcess() {
  ps | $GREP "$1" | $AWK '{print $2}' > $logPath/tmp.txt
  while read line
  do
    kill -9 "$line"
  done < $logPath/tmp.txt
  rm $logPath/tmp.txt
}

function removeLog() {
  rm -rf /data/anr/*
  rm -rf /data/crash/*
  rm -rf /data/tombstones/*
  rm -rf /data/system/dropbox/*
}

function logcatLog() {
  getprop > $logPath/getprop.log
  pm list packages > $logPath/packageList.log
  cat /dev/kmsg > $logPath/kmsg.log &
  cat /proc/meminfo > $logPath/meminfo.log
  du -d 1 -h /data/data/ > $logPath/dataspace_start.log
  mkdir -p $logPath/logcat
  while true
  do
    stampTmp=$(date +%Y%m%d%H%M%S)
    logcat -G 2M
    logcat -v threadtime > $logPath/logcat/logcat_"$stampTmp".log &
    sleep 1800
    killProcess logcat
    gzip $logPath/logcat/logcat_"$stampTmp".log &
    gzip $logPath/logcat/logcat_mcu_"$stampTmp".log &
  done &
}

function captureLog() {
    echo "Timestamp,Name,PID,Vss(KB),Rss(KB),Pss(KB),Uss(KB)" > $logPath/memoryruntime.csv
    echo "Timestamp,PID,PR,CPU%,S,#THR,VSS,RSS,PCY,UID,Name" > $logPath/top.csv
    while true;do
      ps | $GREP monkey
      if [ $? -eq 0 ];then
        echo "monkey start time: ${start_date} (${start_timestamp}s)" > $logPath/monkeytime.log
        echo "monkey stop time: $(date "+%Y-%m-%d %H:%M:%S") ($(date +%s)s)" >> $logPath/monkeytime.log
        stop_timestamp=$(date +%s)
        durationTime=$((${stop_timestamp}-${start_timestamp}))
        echo "monkey duration time: "$((durationTime/60))" (min)" >> $logPath/monkeytime.log
      else
        killLog;
        break
      fi
      ps | $GREP procrank
      if [ $? -ne 0 ];then
        procrank > /data/meminfo.log
        cat /data/meminfo.log | $SED '/------/,$d' | $TAIL -n +2 | $AWK '{print $6"K,"$1"K,"$2","$3","$4","$5","}' | $AWK -F "K," '{print $1","$2","$3","$4","$5","$6}' |  $SED 's/^/'"$(date "+%c") ,"'&/g'  >> $logPath/memoryruntime.csv
        cat /data/meminfo.log | $TAIL -n -1 | $SED 's/^/'"$(date "+%c") ,"'&/g'  >> $logPath/totalMEM.csv
      fi
      ps | $GREP top
      if [ $? -ne 0 ];then
      top -n 1 > /data/top.log
        cat /data/top.log | $AWK '{if (NF==10) {print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10}}' | $SED 's/^/'"$(date "+%c") ,"'&/g' | $SED "1d" >> $logPath/top.csv
        cat /data/top.log | $HEAD -n 4 | $TAIL -n -1 | $SED 's/^/'"$(date "+%c") ,"'&/g' >> $logPath/totalCPU.csv
      fi
      sleep 30
  done > /dev/null 2>&1 &
}

function backupLog() {
  while true;do
    sleep 43200
    cp -rn /data/system/dropbox $logPath/
    sync
  done > /dev/null 2>&1 &
}

killLog;
removeLog;
#logcatLog;
captureLog;
#backupLog;
