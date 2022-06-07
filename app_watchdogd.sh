#
# app_watchdogd.sh is used to automatically relaunch an Android APP which is killed or crashed
#
# $1 pkg_or_kill: pkg e.g. `com.domain.appname` means enable watchdogd; or just `kill` means disable watchdogd
# $2 activity: e.g. `MainActivity` if pkg; null if kill
# $3 timeout_sec: e.g. `5` if pkg; null if kill
#
# homepage
# https://github.com/flyskywhy/app_watchdogd
#
# app_watchdogd.sh can be run in /data/data/com.domain.appname/files/ or /system/xbin/
#
# if run without `su -c` , `adb shell cat /proc/WATCHDOG_PID/oom_adj` will not be -17 but 0,
# so you need `su -c /data/data/com.domain.appname/files/app_watchdogd.sh &`
#

pkg_or_kill=$1

if [ -z $pkg_or_kill ]; then exit; fi

# if kill, disable all watchdogd and exit
# caution: at the moment of enable, it is pipe_wait, then be poll_sched, so do not run disable very close after enable
if [ $pkg_or_kill == kill ]
then
    ps | grep /system/bin/sh | grep poll_sched | sed "s/ 1 .*$//" | sed "s/^root *//" | sed "s/ *//" | xargs kill -9
    exit
fi

# if not kill, enable watchdogd if not running
pkg=$pkg_or_kill
activity=$2
intent="$pkg/.$activity" #com.domain.appname/.MainActivity
timeout_sec=$3

if [ -z $activity ]; then exit; fi
if [ -z $timeout_sec ]; then exit; fi

if [ $(ps | grep /system/bin/sh | grep -c poll_sched) != 0 ]
then
    # if this watchdog is already running
    exit
fi

while :
do
    sleep $timeout_sec
    if [ $(ps | grep -c $pkg) == 0 ]
    then
        # if APP is not running
        am start $intent
    fi
done
