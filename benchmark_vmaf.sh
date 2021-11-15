#!/bin/bash

INPUT_FILE=$1
INSTANCE=$2
MODEL=$3
INPUT_BUCKET=s3://zhixue.vt1.ffmpeg/input/
OUTPUT_BUCKET=s3://zhixue.vt1.ffmpeg/output/
RESULT_BUCKET=s3://zhixue.vt1.ffmpeg/reports/${INSTANCE}/
INPUT_FOLDER=`pwd`/input
OUTPUT_FOLDER=`pwd`/output/${INSTANCE}
LOGS_FOLDER=`pwd`/logs/${INSTANCE}
TEMP_FOLDER=`pwd`/temp

VCPU=`nproc`

if [ -z $1 ]; then
    INPUT_FILE=bbb_sunflower_1080p_30fps_normal.mp4
fi

if [ -z $2 ]; then
    INSTANCE="C5.4x"
fi

if [ -z $3 ]; then
    MODEL="HD"
fi

vmaf_process() {

    echo "please waiting for the vmaf jobs complete..."

    input_name=${INPUT_FILE%.*}
    RESULT_FILE=${LOGS_FOLDER}/results_${input_name}.csv
    LOG_FILE=${LOGS_FOLDER}/vmaf_${input_name}.log

    echo "File,VMAF" > ${RESULT_FILE}

    for file in ${OUTPUT_FOLDER}/${input_name}*.mp4; do

        name=$(basename "$file" ".mp4")
        temp_log=${LOGS_FOLDER}/temp/${name}.log
        echo -n "${name}," >> ${RESULT_FILE}

        echo "vmaf job of ${name}.mp4 started..."

        if [ "$MODEL" = "4K" ]; then
            ffmpeg -i ${file} -i ${INPUT_FOLDER}/${INPUT_FILE} -lavfi "[0:v]scale=3840x2160:flags=bicubic[main];[main][1:v]libvmaf=model_path=/usr/local/share/model/vmaf_4k_v0.6.1.json:n_threads=${VCPU}" -f null - > ${temp_log} 2>&1
        else
            ffmpeg -i ${file} -i ${INPUT_FOLDER}/${INPUT_FILE} -lavfi "[0:v]scale=1920x1080:flags=bicubic[main];[main][1:v]libvmaf=model_path=/usr/local/share/model/vmaf_v0.6.1.json:n_threads=${VCPU}" -f null - > ${temp_log} 2>&1
        fi

        cat ${temp_log} | awk  '/VMAF score:/ {print $NF}' >> ${RESULT_FILE}
        cat ${temp_log} >> ${LOG_FILE}
        cat ${temp_log} | grep "VMAF score:"

    done

    echo "vmaf jobs complete..."

}

wait_for_cpu_idle() {
    current=$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')
    echo "cpu usage: $current%"
    while [ $(echo "$current>25" | bc) -eq 1 ]; do
        current=$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')
        echo "cpu usage: $current%, the latest transcoding job may not finished yet"
        sleep 5
    done
}

## step 1 - download input (reference) file

mkdir -p ${INPUT_FOLDER} ${OUTPUT_FOLDER} ${LOGS_FOLDER} ${TEMP_FOLDER} ${LOGS_FOLDER}/temp
FILE=${INPUT_FOLDER}/${INPUT_FILE}
NAME=${INPUT_FILE%.*}

if [ -f "$FILE" ]; then
    echo "$INPUT_FILE exists, no need to download again."
else
    echo "$INPUT_FILE doesn't exist, start to download from S3."
    aws s3 sync ${INPUT_BUCKET} ${INPUT_FOLDER}
fi

## step 2 - download output (distorted) file

echo "start to download distored files from S3."

aws s3 sync ${OUTPUT_BUCKET}${INSTANCE}/ ${OUTPUT_FOLDER} --exclude "*" --include "${NAME}*"

## step 3 - calculate the VMAF scores

vmaf_process 

## step 4 upload results

echo "Upload result to S3."

aws s3 cp ${RESULT_FILE} ${RESULT_BUCKET}

## step 5 clean jobs
rm -rf ${TEMP_FOLDER}