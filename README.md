Solve Kaggle Competition: The Nature Conservancy Fisheries Monitoring by Google CloudML
--------------------------------------------------

## Background

See [The Nature Conservancy Fisheries MonitoringL](https://www.kaggle.com/c/the-nature-conservancy-fisheries-monitoring)
for detail information of the competition. This project is inspired by
[Google CloudML Flower
example](https://github.com/GoogleCloudPlatform/cloudml-samples/tree/master/flowers)
and [MXNet
solution](https://www.kaggle.com/drn01z3/the-nature-conservancy-fisheries-monitoring/mxnet-xgboost-simple-solution/code)

## Data

Raw train and test images are in ```gs://oci-analytics-data/fish```.

## Run

1) Set up [environment](https://cloud.google.com/ml/docs/how-tos/getting-set-up)

2) Set up ```data_path``` and ```work_path``` for images data and working space.
The defaults are ```gs:\\oci-analytics-data\fish``` and
```gs:\\oci-analytics-yfu\fish```. To change default path you could
add option in the following commands

### Generate index

To run CloudML there should be index files which include mapping between image path and its label.
Running ```python create_index.py``` will generate 3 index files (if they are not existed):
  * ```all_set.csv```: the index file for all images (but not include image in test directory)
  * ```train_set.csv```: the index file of images for training
  * ```test_set.csv```: the index file of images for testing

### Preprocessing

Running ```./preproc.sh``` triggers GCP Dataflow to process images (resize, convert format, ...).

### Model training

Running ```./train.sh``` to train model.

### Serving

Running ```./serve.sh``` to start a vm for prediction.

### Submission

Running ```./submit.sh``` to generate a file for submission.

