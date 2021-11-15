#!/bin/bash

BATCH_SIZE=$1
INSTANCE=$2
BITRATE=$3
INPUT_BUCKET=s3://zhixue.vt1.ffmpeg/input/
OUTPUT_BUCKET=s3://zhixue.vt1.ffmpeg/output/
INPUT_FILE=bbb_sunflower_1080p_30fps_normal.mp4
INPUT_FOLDER=`pwd`/input
OUTPUT_FOLDER=`pwd`/output/${INSTANCE}
LOGS_FOLDER=`pwd`/logs/${INSTANCE}
LOG_FILE=${LOGS_FOLDER}/results.log
TEMP_FOLDER=`pwd`/temp

PROFILE="high"
CODEC="h264"

if [ -z $1 ]; then
    BATCH_SIZE=5
fi

if [ -z $2 ]; then
    INSTANCE="G4dn.x"
fi

if [ -z $3 ]; then
    BITRATE=3M
fi

#ffmpeg -y -c:v h264_cuvid -i $i -c:a copy -c:v hevc_nvenc -pix_fmt yuv420p -preset:v $PRESET -profile:v main -rc:v cbr -rc-lookahead:v 0 -refs:v 16 -b:v 4M -bf:v 2 -b_ref_mode:v middle out.mp4

batch_transcoding_process() {

    name=${INPUT_FILE%.*}
    output="${name}-${CODEC}-${INSTANCE}-${BITRATE}"
    temp_log=${LOGS_FOLDER}/temp/${output}

    for ((n=0;n<$BATCH_SIZE;n++)); do
        echo "batch job id $n start..."
        if [ $n -eq $((BATCH_SIZE-1)) ]; then
            echo "please waiting for the transcoding jobs complete..."
            nohup bash -c "(time ffmpeg -y -c:v ${CODEC}_cuvid -i ${INPUT_FOLDER}/${INPUT_FILE} -c:a copy -c:v ${CODEC}_nvenc -pix_fmt yuv420p -profile:v ${PROFILE} -preset p4 -rc:v cbr -rc-lookahead:v 0 -refs:v 16 -b:v ${BITRATE} -bf:v 2 -b_ref_mode:v middle ${TEMP_FOLDER}/${output}_$n.mp4 2>&1 ) > ${temp_log}_$n.log 2>&1" >/dev/null 2>&1
        else
            nohup bash -c "(time ffmpeg -y -c:v ${CODEC}_cuvid -i ${INPUT_FOLDER}/${INPUT_FILE} -c:a copy -c:v ${CODEC}_nvenc -pix_fmt yuv420p -profile:v ${PROFILE} -preset p4 -rc:v cbr -rc-lookahead:v 0 -refs:v 16 -b:v ${BITRATE} -bf:v 2 -b_ref_mode:v middle ${TEMP_FOLDER}/${output}_$n.mp4 2>&1 ) > ${temp_log}_$n.log 2>&1 &" >/dev/null 2>&1
        fi
    done

    echo "transcoding jobs complete..."
    sleep 3

    fps_total=0
    cpu_usage_total=0

    for ((n=0;n<$BATCH_SIZE;n++)); do

        # Get ffmpeg transcoding frames per second 
        fps=`cat ${temp_log}_$n.log | awk -F'=' '/fps=/ {print $(NF-7)}' | awk '{print $1}'`
        fps_total=`echo "$fps_total+$fps" | bc`
        # Get CPU usage
        #user=`cat ${temp_log}_$n.log | awk '/user/ {print $2}' | awk -F'm' '{printf 60*int($1*100)/100+int($2*100)/100}'`
        #real=`cat ${temp_log}_$n.log | awk '/real/ {print $2}' | awk -F'm' '{printf 60*int($1*100)/100+int($2*100)/100}'`
        #cpu_usage=`echo "scale=4;$user/$real/$VCPU*100;" | bc`
        #cpu_usage_total=`echo "$cpu_usage_total+$cpu_usage" | bc`
        # Log cpu_usage and fps
        echo "${output} trancode job #$n fps:${fps} frames per second"
        echo "${output} trancode job #$n fps:${fps} frames per second" >> ${LOG_FILE}

    done

    echo "${output} trancode jobs total fps:${fps_total} frames per second"
    echo "${output} trancode jobs total fps:${fps_total} frames per second" >> ${LOG_FILE}

}

## step 1 - download input files

mkdir -p ${INPUT_FOLDER} ${OUTPUT_FOLDER} ${LOGS_FOLDER} ${TEMP_FOLDER} ${LOGS_FOLDER}/temp

FILE=${INPUT_FOLDER}/${INPUT_FILE}
if [ -f "$FILE" ]; then
    echo "$INPUT_FILE exists, no need to download again."
else
    echo "$INPUT_FILE doesn't exist, start to download from S3."
    aws s3 sync ${INPUT_BUCKET} ${INPUT_FOLDER}
fi

## step 2 - transcoding input files

echo "======================================================" >> ${LOG_FILE}
batch_transcoding_process 

## step 3 upload results
cp ${TEMP_FOLDER}/${output}_0.mp4 ${OUTPUT_FOLDER}/"${INPUT_FILE%.*}_${CODEC}_${BITRATE}.mp4"
aws s3 sync ${OUTPUT_FOLDER} ${OUTPUT_BUCKET}${INSTANCE}

## step 4 clean jobs
rm -rf ${TEMP_FOLDER}