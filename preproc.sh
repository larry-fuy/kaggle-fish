#!/bin/bash
# Copyright 2017 Yong Fu. All Rights Reserved.
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

# Preprocess images Assuming images are stored in train and test
# dir. Note that images in train dir will be split to train and evalation set.
# An index file including mapping between image path and label is necessary.

declare -r PROJECT=$(gcloud config list project --format "value(core.project)" 2>/dev/null)
declare -r BUCKET_DATA="gs://${PROJECT}-data"
declare -r BUCKET_WORK="gs://${PROJECT}-yfu"
declare -r TASK="fish"
declare -r DATA_PATH="${BUCKET_DATA}/${TASK}"
declare -r WORK_PATH="${BUCKET_WORK}/${TASK}"
declare -r JOB_ID="fish_${USER}_$(date +%Y%m%d_%H%M%S)"

work_path=${WORK_PATH}
data_path=${DATA_PATH}

set -e

help_msg="Preprocessing images.
Usage:
  preproc [-d data_path] [-w work_path] [-h|--help]

Options:
  -d data_path: path to store images data 
                (default path is gs://oci-analytics-data/fish) 
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
	-d) data_path=$2; shift ;;
	-w) work_path=$2; shift ;;
	--) shift; break ;;
	-h|--help) echo "${help_msg}"; shift ;;
	*) break ;;
    esac
done

dict_file="${data_path}/dict.txt"
test_set="${work_path}/test_set.csv"
train_set="${work_path}/train_set.csv"

echo "Using job id: " $JOB_ID

# Takes about 15 minutes to preprocess everything.  We serialize the two
# preprocess.py synchronous calls just for shell scripting ease.  You could use
# --runner DataflowPipelineRunner to run them asynchronously.
echo "Preprocessing test set..."
python trainer/preprocess.py \
  --input_dict "${dict_file}" \
  --input_path "${test_set}" \
  --output_path "${work_path}/preproc/eval" \
  --cloud

echo "Preprocessing train set..."
python trainer/preprocess.py \
  --input_dict "${dict_file}" \
  --input_path "${train_set}" \
  --output_path "${work_path}/preproc/train" \
  --cloud
