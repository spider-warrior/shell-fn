#!/bin/bash

start_process_shell=/home/yj/atlassian/atlassian-confluence-7.4.8/bin/start-confluence.sh
log_file=/var/log/process-monitor/confluence-monitor.log;
key_word="atlassian-confluence-7.4.8";
#key_word="6934";
lock_file=/tmp/start-process-lock
lock_timeout_in_seconds=120
#pids=($(pgrep -f $key_word));
pids=($(ps -ef |grep -v grep | grep $key_word | awk '{print $2}'));

function format_msg() {
 echo "`date '+%Y-%m-%d %H:%M:%S'`[$1]: $2" >>$log_file
}

function info_msg() {
 format_msg "info" "$1";
}

function error_msg() {
 format_msg "error" "$1";
}


function check_process() {
 if [[ ${#pids[@]} == 0 ]];
 then process_already_exit;
 else process_still_exist;
 fi;
}

function try_lock() {
  if [[ ! -e $lock_file ]];
  then try_lock_success
  return 1;
  else
    local lock_timestamp=`sed -n '1,1p' $lock_file`;
    local now_timestamp=`date +%s`;
    local total_lock_time=`expr $now_timestamp - $lock_timestamp`;
    info_msg "total_lock_time(${total_lock_time}s) = now_timestamp(${now_timestamp}s) - lock_timestamp(${lock_timestamp}s)";
    if [[ $total_lock_time -gt $lock_timeout_in_seconds ]];
      then
      try_lock_success
      return 1;
      else
      return 0;
    fi
  fi
}

function try_lock_success() {
  echo "`date +%s`" >$lock_file;
}

function process_still_exist() {
  info_msg "进程存活, key_word: ${key_word}, 相关进程数量: ${#pids[@]}";
 for pid in "${pids[@]}"
 do
  info_msg "pid: $pid"
 done
}

function start_process() {
    ($start_process_shell) &
    rm -f $lock_file;
    info_msg "进程启动成功: $start_process_shell";
}

function process_already_exit() {
  error_msg "进程不存在, key_word: ${key_word}";
  if [[ ! -e $start_process_shell ]];
    then error_msg "启动shell不存在: $start_process_shell";
    return 0;
  fi
  try_lock
  if [[ $? -eq 1 ]];
    then info_msg "抢占锁成功, 即将启动程序";
     start_process;
    else
      info_msg "抢占锁失败, 进程正在启动中";
  fi
}

check_process