#!/bin/bash
nohup bash port-scan.sh $1 $2 > process.log 2>&1 &
sleep 1s
tail -f -n 200 process.log
