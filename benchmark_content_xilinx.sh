#!/bin/bash

INSTANCE=$1
QUALITY=$2

BITRATE_HD=(3M 2.5M 2M 1.5M 1M 750K 500K 250K)
BITRATE_4K=(16M 14M 12M 10M 8M 6M 4M 2M)

if [ -z $1 ]; then
    INSTANCE="VT1.3x"
fi

if [ -z $1 ]; then
    QUALITY="default"
fi

for ((i=0;i<${#BITRATE_HD[@]};i++)); do

    source 264to264_benchmark_xilinx.sh 1 ${INSTANCE} ${BITRATE_HD[$i]} ${QUALITY}

done

for ((i=0;i<${#BITRATE_4K[@]};i++)); do

    source 265to265_benchmark_xilinx.sh 2 ${INSTANCE} ${BITRATE_4K[$i]} ${QUALITY}

done