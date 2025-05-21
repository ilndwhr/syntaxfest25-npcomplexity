# -*- coding: utf-8 -*-
"""
Created on Fri Feb 28 12:09:21 2025

@author: isabell

script to split corpus files into batches (here: 10 batches)
using Stratified Shuffle Split:
    - random shuffle
    - but original proportions of years are preserved
"""


import os
import re
import shutil
import numpy as np
from collections import defaultdict
from sklearn.model_selection import StratifiedShuffleSplit

# define input and output directories
input_folder = "C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/data/rsc-ud212-analyzed/analyzed"
output_folder = "C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20250228/data"
os.makedirs(output_folder, exist_ok=True)

# get list of files from input folder
files = [f for f in os.listdir(input_folder) if f.endswith(".conllu")]

# define regex pattern for file names
year_pattern = re.compile(r'rs[a-z][a-z]_(\d{4})_.+\.conllu$')

# create list for grouping files by year
file_groups = defaultdict(list)

# go through all files from input folder
for file in files:
    # if file name matches regex pattern
    match = year_pattern.match(file) 
    if match:
        year = match.group(1) # get year from file name
        file_groups[year].append(file) # group file per year
    else:
        print(f"Skipping file: {file}") # skip files not matching regex patttern

# flatten data into (filename, year) pairs
all_files = []
# go through all (year, file) tuples in file_groups
for year, files in file_groups.items():
    # then go through all files in files
    for file in files:
        all_files.append((file, year)) # create (file, year) tuples
# get tuple with all filenames and tuple with all years
filenames, years = zip(*all_files) 

# convert years to a NumPy array for stratified splitting
years = np.array(years)

# create stratified shuffle split
num_batches = 10
sss = StratifiedShuffleSplit(n_splits=num_batches, test_size=None, train_size=1/num_batches, random_state=42)

batches = [[] for _ in range(num_batches)]

# generate 10 stratified splits
for batch_idx, (train_index, _) in enumerate(sss.split(filenames, years)):
    for idx in train_index:
        batches[batch_idx].append(filenames[idx])

# save batches into subfolders
# go through all batches
for i, batch in enumerate(batches):
    batch_folder = os.path.join(output_folder, f"batch_{i+1}")
    os.makedirs(batch_folder, exist_ok=True) # create subfolder for current batch
    # go through all files in current batch
    for file in batch:
        src = os.path.join(input_folder, file) # source path
        dst = os.path.join(batch_folder, file) # destination path
        shutil.copy(src, dst) # copy file from source to destination folder

# print batch results
for i, batch in enumerate(batches):
    print(f"Batch {i+1}: {batch}")
