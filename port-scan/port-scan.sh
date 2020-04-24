#!/bin/bash

function scan_port() {
	echo "nc -v -w 1 $1 -z $2 2>&1|grep succeed >> scan-result.txt" >> scan.log
	nc -v -w 1 $1 -z $2 2>&1|grep succeed >> scan-result.txt && {
		echo "scan success, ip: $1, range: $2" >> scan-success.log
	} || {
		echo "scan fail, ip: $1, range: $2" >> scan-fail.log
	}
}

ip_addr=39.108.105.130
batch=100
begin=$1
end=$2

tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile      # 新建一个fifo类型的文件
exec 6<>$tmp_fifofile      # 将fd6指向fifo类型
rm $tmp_fifofile

thread=10 # 此处定义线程数
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

echo "扫描完成[$1-$2]"


