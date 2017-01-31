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

# This script builds index files for training and testing data and
# dictionary necessary for classification.

# index file (all_set, train_set, test_set) - URI to csv file, using format:
# gs://image_uri1,labela,labelb,labelc
# gs://image_uri2,labela,labeld
# ...

# dictionary - URI to a text file listing all labels (one label per line):
# labela
# labelb
# labelc

# TODO: implemented through Beam

import os
import shutil
import csv
import argparse
import random
import subprocess
import sys

# TODO: fetch project from cloud api
DATA_DIR = "gs://kaggle-157221-yfu-data"
WORK_DIR = "gs://kaggle-157221-yfu"
TASK = "fish"
DATA_PATH = os.path.join(DATA_DIR, TASK)
WORK_PATH = os.path.join(WORK_DIR, TASK)
DICT_FILE = 'dict.txt'
ALL_SET = 'all_set.csv'
TRAIN_SET = 'train_set.csv'
TEST_SET = 'test_set.csv'
RATIO = 20


def parse_args():
    """Handle the command line arguments.

    Returns:
    Output of argparse.ArgumentParser.parse_args.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument('-r', '--ratio', type=int, default=RATIO,
                        help='Ratio of image number in train and test')
    parser.add_argument('-w', '--work_path', default=WORK_PATH,
                        help='The path to store intermediate and final results')
    parser.add_argument('-d', '--data_path', default=DATA_PATH,
                        help='The path to store original images')
    args = parser.parse_args()
    return args


def exist_file_gs(f):
    """ Scan data and generate index
    Arguments:
        f: 'string'. The file for testing

    Returns:
        exist: 'boolean'. True if files exists otherwise false.
    """
    if f.startswith("gs://"):
        stats = ['gsutil', '-q', 'stat', f]
        exist = subprocess.call(stats)
    else:
        print "%s is not a valid GS path..." % f
        sys.exit()
    return not exist
    

def cp_file_gs(f, gs):
    """ Copy file to GCP storage
    Arguments:
        f: 'string'. File.
        gs: 'string'. Loaction of GCP storage.

    Returns:
        success: 'boolean'. True if copy successed.
    """
    if gs.startswith("gs://"):
        cp = ['gsutil', 'cp', f, gs]
        success = subprocess.call(cp)
    else:
        print "%s is not a valid GS path..." % gs
        sys.exit()

    return success


def cp_gs_file(gs, loc):
    """ Copy file to GCP storage
    Arguments:
        gs: 'string'. File loaction of GCP storage.
        loc: 'string'. Local location to store the file.

    Returns:
        success: 'boolean'. True if copy successed.
    """
    if gs.startswith("gs://"):
        cp = ['gsutil', 'cp', gs, loc]
        success = subprocess.call(cp)
    else:
        print "%s is not a valid GS path..." % gs
        sys.exit()

    return success


def gen_all_set(data_path):
    """ Scan data and generate index
    Arguments:
        data_path: 'string'. The path storing images data

    Returns:
    """
    tmp_dir = './tmp'
    images_path = os.path.join(data_path, 'train')
    if os.path.isdir(tmp_dir):
        shutil.rmtree(tmp_dir)
    os.mkdir(tmp_dir)
    cp = ['gsutil', '-m', 'cp', '-r', images_path, tmp_dir]
    subprocess.call(cp)
    
    label_files = scan_data(tmp_dir)
    with open(os.path.join(tmp_dir, ALL_SET), 'w') as f:
        csv_writer = csv.writer(f)
        for label, files in label_files.items():
            for f in files:
                csv_writer.writerow((os.path.join(images_path, f), label))

    cp_file_gs(os.path.join(tmp_dir, ALL_SET), data_path)
    shutil.rmtree(tmp_dir)

    
def scan_data(root):
    """ Scan data and generate index
    Arguments:
        root: 'string'. Root directory of image data.

    Returns:
        label_files: 'dictionary'. Labels and images belond to the same label.
    """
    label_files = {}
    for directory, subdir, files in os.walk(root):
        print directory
        if (directory != root):
            label = os.path.basename(directory)
            label_files[label] = [os.path.join(label, f) for f in files]

    return label_files


def scan_all_set_file(data_path):
    """ Scan all set file to generate index (assuming all set file exists)
    Arguments:
        data_path: 'string'. The path to store all set file

    Returns:
        label_files: 'dictionary'. Labels and images belond to the same label.
    """
    label_files = {}
    cp_gs_file(os.path.join(data_path, ALL_SET), '.')
    
    with open(ALL_SET, 'r') as f:
        csv_reader = csv.reader(f)
        for row in csv_reader:
            if row[1] not in label_files:
                label_files[row[1]] = [row[0]]
            else:
                label_files[row[1]].append(row[0])

    os.remove(ALL_SET)
    return label_files

    
def split_set(data_path, work_path, ratio):
    """ Generate file to map file name and label
    Arguments:
        data_path: 'string'. The path to store all set file
        work_path: The path to store train and test set file
        ratio: Train/test data ratio.

    Returns:
    """
    label_files = scan_all_set_file(data_path)
    with open(TRAIN_SET, 'w') as train_set:
        with open(TEST_SET, 'w') as test_set:
            train_writer = csv.writer(train_set)
            test_writer = csv.writer(test_set)
            for label in label_files.iterkeys():
                files = label_files[label]
                l = len(files)
                for f in files:
                    if (random.randint(1, l) >= l * float(ratio) / 100):
                        train_writer.writerow((f, label))
                    else:
                        test_writer.writerow((f, label))
                    
    cp_file_gs(TRAIN_SET, work_path)
    cp_file_gs(TEST_SET, work_path)
    os.remove(TRAIN_SET)
    os.remove(TEST_SET)


def gen_dict(data_path):
    """ Generate dictionary
    Arguments:
        data_path: 'string'. The path to store all set file

    Returns:
    """
    dict_file = os.path.join(DICT_FILE)
    label_files = scan_all_set_file(data_path)
    labels = [l for l in label_files.iterkeys()]
    labels.sort()
    with open(dict_file, 'w') as dict:
        for e in labels:
            dict.write(e + "\n")

    cp_file_gs(dict_file, data_path)
    os.remove(dict_file)
    

def main():
    args = parse_args()
    work_path = args.work_path
    data_path = args.data_path
    ratio = args.ratio

    if not exist_file_gs(os.path.join(data_path, ALL_SET)):
        print 'generate all set file...'
        gen_all_set(data_path)

    if (args.ratio
        or (not exist_file_gs(os.path.join(work_path, TRAIN_SET)))
        or (not exist_file_gs(os.path.join(work_path, TEST_SET)))):
        print 'split all set file...'
        split_set(data_path, work_path, ratio)

    if not exist_file_gs(os.path.join(data_path, DICT_FILE)):
        print 'generate dictionary...'
        gen_dict(data_path)
        
    
if __name__ == '__main__':
    main()
