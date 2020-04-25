#!/bin/bash

function current_time_str() {
	echo $(date "+%Y-%m-%d %H:%M:%S")
}

function format_msg() {
	echo "$(current_time_str): $1"
}
function scan_port() {
	echo $(format_msg "nc -v -w 1 $1 -z $2 2>&1|grep succeed >> scan-result.txt") >> scan.log
	nc -v -w 1 $1 -z $2 2>&1|grep succeed >> scan-result.txt && {
		echo $(format_msg "scan success, ip: $1, range: $2") >> scan-success.log
	} || {
		echo $(format_msg "scan fail, ip: $1, range: $2") >> scan-fail.log
	}
}

ip_addr=39.108.105.130
batch=3
begin=$1
end=$2

tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile      # 新建一个fifo类型的文件
exec 6<>$tmp_fifofile      # 将fd6指向fifo类型
rm $tmp_fifofile

thread=5 # 此处定义线程数
for ((i=0;i<$thread;i++));do 
echo
done >&6 # 事实上就是在fd6中放置了$thread个回车符


for((; $begin<$end && ($end - $begin) > $batch; begin=($begin + $batch)))
do
	read -u6 
{
	scan_port $ip_addr "$begin-$(($begin + $batch - 1))"
	echo >&6
} &
	
done

wait


difference=$(($end - $begin + 1));
remain=$(($difference % $batch))

if [ $remain -gt 0 ]; then
	{
		scan_port $ip_addr "$begin-$(($begin + $remain - 1))"
	} &
fi

echo $(format_msg "扫描完成[$1-$2]")