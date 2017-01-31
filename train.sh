#!/bin/bash
# Copyright 2017 Yong Fu. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This sample assumes you're already setup for using CloudML.  If this is your
# first time with the service, start here:
# https://cloud.google.com/ml/docs/how-tos/getting-set-up

# Now that we are set up, we can start processing some flowers images.
declare -r PROJECT=$(gcloud config list project --format "value(core.project)" 2>/dev/null)
declare -r BUCKET_WORK="gs://${PROJECT}-yfu"
declare -r TASK="fish"
declare -r WORK_PATH="${BUCKET_WORK}"
declare -r JOB_ID="${TASK}_${USER}_$(date +%Y%m%d_%H%M%S)"

work_path=${WORK_PATH}

set -e

help_msg="Train model.
Usage:
  train [-w work_path] [-h|--help]

Options:
  -w work_path: path to store intermediate and final results of preprocessing 
                (default path is gs://oci-analytics-yfu/fish) 
  -h/--help: print this message
"

args=$(getopt -o d:w:h --long help -- "$@")
[ $? -eq 0 ] || {
    echo "Failed parsing options..."
    exit 1
}
eval set -- "$args"

while true; do
    case "$1" in
	-w) work_path=$2; shift ;;
	--) shift; break ;;
	-h|--help) echo "${help_msg}"; shift ;;
	*) break ;;
    esac
done


# Training on CloudML is quick after preprocessing.
gcloud beta ml jobs submit training "$JOB_ID" \
  --module-name trainer.task \
  --package-path trainer \
  --staging-bucket "${BUCKET_WORK}" \
  --region us-central1 \
  -- \
  --output_path "${work_path}/training" \
  --eval_data_paths "${work_path}/preproc/eval*" \
  --train_data_paths "${work_path}/preproc/train*"
# Add config file into training
#  --config=config.yaml \

# Submit job is async, but stream-log will show us the logs and quit when done.
gcloud beta ml jobs stream-logs "$JOB_ID"

