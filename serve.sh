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

MODEL_NAME=fish
VERSION_NAME=v1
MODEL_PATH=gs://kaggle-157221-yfu
gcloud beta ml models create "$MODEL_NAME"

gcloud beta ml versions create "$VERSION_NAME" \
  --model "$MODEL_NAME" \
  --origin "${MODEL_PATH}/training/model"

# Models do not need a default version, but its a great way move your production
# service from one version to another with a single gcloud command.
output=$(gcloud beta ml versions set-default "$VERSION_NAME" --model "$MODEL_NAME")
if [[$? -eq 0]]; then
    sleep 10m
    echo "Done. $MODEL_NAME is set up..."
else
    echo "$output"
fi


