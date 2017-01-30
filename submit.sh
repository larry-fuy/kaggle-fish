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

# Assuming you're already setup for using CloudML, otherwise see
# sample.sh for how to setup model.

# Not this is not an optimized solution but a tentative method since
# it needs store the evaluation images locally and loop over to make
# online prediction, which is costly than a batch method

IMG_DIR=raw_data/tmp/test/*
SUBMISSION="submission_$(date +%Y%m%d_%H%M%S).csv"

if [[ -f request.json ]]; then
    rm request.json
fi

echo "image,ALB,BET,DOL,LAG,NoF,OTHER,SHARK,YFT" > $SUBMISSION

# loop over test files and upload the image for prediction
for f in $IMG_DIR; do
    # encode the JPEG string first.
    echo "$f" >> files.txt
    python -c 'import base64, sys, json; img = base64.b64encode(open(sys.argv[1], "rb").read()); print json.dumps({"key":"0", "image_bytes": {"b64": img}})' "$f" > request.json
    echo "make prediction for $f..."
    # only store the last 8 (fish category) scores
    score=$(gcloud beta ml predict --model fish --json-instances request.json | sed -n 's/.*\[\(.*\)\]/\1/p' | sed 's/^[^,]*,//g')
    echo "$(basename $f)", "$score" >> $SUBMISSION
done
