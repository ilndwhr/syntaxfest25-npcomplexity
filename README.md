# rsc-np_complexity_mod_type
Corpus Analysis on RSC: Interplay of NP Complexity and Modification Type

This repository contains code and (preprocessed data) of a corpus analysis on the Royal Society Corpus (RSC, Fischer et al. 2020), a corpus containing the publications of the *Philosophical Transactions of the Royal Society of London*. We investigated the role of noun phrase (NP) complexity on modification type (post-modification vs. pre-modification).

## Research Question
Are more complex noun phrases (NPs) more likely to be post-modified than pre-modified?

## Data
RSC version 6.0.3 ("good sentences" version), parsed for Universal Dependencies (de Marneffe et al. 2021, Nivre et al. 2017), using the Python package *stanza* (Qi et al. 2020).

## Procedure
1. Stratified sampling using *preprocess/split_corpus_into_batches.py*: Split the corpus into 10 batches while preserving the distribution of files per year.
2. Extract NPs and their features (e.g. modification type, number of dependents, syntactic role, distance to head) as well as metadata (e.g. author, publication year, text type) from the first corpus batch, resulting in the data file *noun_data_b1_v3.csv*.
3. Analyze the NPs using *analysis_20250304_d.R* (mixed-effects logistic regression model).
