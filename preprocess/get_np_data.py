# -*- coding: utf-8 -*-
"""
Created on Fri Feb 28 11:38:49 2025

@author: isabell

script to parse the CoNLL-U files and extract relevant features of noun phrases
consider only noun phrases that are not embedded in other noun phrases
noun phrase features to be extracted/determined:
    - sentence ID
    - head noun
    - head noun ID
    - number of dependencies for head noun
    - modification type of noun phrase (pre- or post-modification)
    - syntactic role of noun phrase
    - number of different modifier types
    - givenness (determiner presence)
metadata features to be extracted:
    - text ID
    - year of publication
    - author
    - text type
    - journal
    
note: counting prepositional phrases doesn't work, so it is commented out for now
"""

import csv
import os
from conllu import parse


# special characters
special_ch = r'(\\amp|\\mdash)'


# function to parse sentences and extract NP data
def parse_sents(sentences, np_data):

    # go through each sentence
    for sentence in sentences:

        # go through each token 
        for token in sentence:
            
            # get sentence ID
            sent_id = sentence.metadata['sent_id'] # sentence id
            
            # if token is noun
            if token['upos'] == 'NOUN':
                             
                # determine if noun is not embedded in another NP
                # get head
                head_id = int(token['head'])
                head = sentence[head_id-1]
                
                # if direct head of noun is not another noun
                if head['upos'] != 'NOUN' and head['upos'] != 'PROPN':
                
                    # go through heads until root or another noun is reached
                    # check if next head is neither root nor noun
                    while head['deprel'] != 'root' and head['upos'] != 'NOUN' and head['upos'] != 'PROPN':
                        # get next head
                        head_id = int(head['head']) # new head ID
                        head = sentence[head_id-1] # new head          
                    
                    # if root has been reached without noun head between:
                    # noun is not embedded in an another NP
                    if head['deprel'] == 'root':
                    
                        # get noun form
                        noun = token['form']
                        #print(sent_id, noun)
                        # get token id
                        noun_id = int(token['id'])
                        # get noun dependency relation
                        noun_deprel = token['deprel']
                        # get dependency length
                        dep_len = token['dl']
                        # get sentence length
                        sent_len = token['sl']
                        # get sum of dependencies
                        sum_dep = token['sod']
                        # get average dependency length
                        avg_dep_len = token['adl']
                        # initialize variable for number of dependencies
                        dep_num = 0
                        # initialize variable for definite determiner presence
                        det_def = False
                        # initialize variable for number of prepositions
                        prep_num = 0
                        # initialize variable for number of pre-modifiers
                        pre_mod_num = 0
                        # initialize variable for number of post-modifiers
                        post_mod_num = 0
                        # initialize variables for number of different modifiers
                        relcl_f_num = 0 
                        relcl_nf_num = 0
                        prep_num = 0
                        nmod_num = 0 
                        comp_num = 0 
                        amod_num = 0 
                        advmod_num = 0
                    
                        # get tokens directly dependent on noun        
                        # go through tokens in sentence
                        for other_token in sentence:
                    
                            # if other token is dependent on noun
                            if int(other_token['head']) is noun_id:
                                # increase number of dependencies
                                dep_num += 1
                                #print(noun, ' + ', other_token)
                            
                                # check if other token is determiner and definite
                                if other_token['upos'] == 'DET' and 'Definite=Def' in other_token['ufeat']:
                                    # increase number of determiners
                                    det_def = True
                                    # check if other token is preposition (NP contains embedded PP)
                                    #if other_token['deprel'] == 'case':
                                        # increase number of prepositions
                                        #prep_num += 1
                            
                                # get type of dependent, score for modification type
                                # finite relative clause
                                if other_token['deprel'] == 'acl:relcl':
                                    post_mod_num += 1
                                    relcl_f_num += 1
                                # non-finite relative clause
                                elif other_token['deprel'] == 'acl':
                                    post_mod_num += 1
                                    relcl_nf_num += 1
                                # PP or appositive NP
                                elif other_token['deprel'] == 'nmod':
                                    post_mod_num += 1
                                    nmod_num += (1 - prep_num) # don't consider PPs
                                # compound / pre-modifying noun
                                elif other_token['deprel'] == 'compound':
                                    pre_mod_num += 1
                                    comp_num += 1
                                # adjectival modifier before noun
                                elif other_token['deprel'] == 'amod' and int(other_token['id']) < noun_id:
                                    pre_mod_num += 1
                                    amod_num += 1
                                # adjectival modifier after noun
                                elif other_token['deprel'] == 'amod' and int(other_token['id']) > noun_id:
                                    post_mod_num += 1
                                    amod_num += 1
                                # adverbial modifier
                                elif other_token['deprel'] == 'advmod':
                                    pre_mod_num += 1
                                    advmod_num += 1
                  
                        # add noun and context features  
                        np_data.append({'sent_ID': sent_id, 'noun': noun,
                                    'noun_ID': noun_id, 'dep_len': dep_len,
                                    'dep_num': dep_num, 'sent_len': sent_len,
                                    'sum_dep': sum_dep, 'avg_dep_len': avg_dep_len,
                                    'deprel': noun_deprel, 'pre_mod_num': pre_mod_num,
                                    'post_mod_num': post_mod_num, 'det_def': det_def,
                                    'PP_num': prep_num, 'relcl_f_num': relcl_f_num,
                                    'relcl_nf_num': relcl_nf_num, 'nmod_num': nmod_num,
                                    'compound_num': comp_num, 'adj_num': amod_num,
                                    'adv_num': advmod_num})
                    
                        #print(np_data)

    # return all extracted features
    return np_data
                   

# function to parse metadata file and extract relevant information
def parse_metadata(metadata_file, metadata):
    with open(metadata_file, 'r', encoding = 'utf-8') as file:
    
        lines = []
        
        for line in file:
            # add each line to the list of metadata lines
            lines.append(line.strip())
        
        # go through metadata line by line
        for line in lines:
            content = line
        
            # extract relevant metadata
            # extract text id
            id_start = content.find('id="')
            if id_start != -1:
                # extract the value of 'id'
                id_end = content.find('"', id_start + 4)
                text_id = content[id_start + 4:id_end]
            else:
                text_id = None
            
            # extract publication year
            year_start = content.find('year="')
            if id_start != -1:
                # extract the value of 'id'
                year_end = content.find('"', year_start + 6)
                year = content[year_start + 6:year_end]
            else:
                year = None
             
            # extract author name(s)
            author_start = content.find('author="')
            if author_start != -1:
                # extract the value of 'id'
                author_end = content.find('"', author_start + 8)
                author = content[author_start + 8:author_end]
            else:
                author = None
     
            # extract text type
            type_start = content.find('type="')
            if type_start != -1:
                # extract the value of 'id'
                type_end = content.find('"', type_start + 6)
                text_type = content[type_start + 6:type_end]
            else:
                text_type = None
        
            # extract journal name
            journal_start = content.find('jrnl="')
            if journal_start != -1:
                # extract the value of 'id'
                journal_end = content.find('"', journal_start + 6)
                journal = content[journal_start + 6:journal_end]
            else:
                journal = None   
               
            # add to metadata
            metadata.append({'text_id': text_id,
                             'year': year,
                             'author': author,
                             'type': text_type,
                             'journal': journal})
            
        #print(metadata)
    
    # return all extracted metadata
    return metadata


# function to write output to csv file
def write_to_csv(current_metadata, np_data, output_file):
    with open(output_file, 'a', newline = '', encoding = 'utf-8') as csv_file:
        # names for header
        fieldnames = ['text_ID', 'year', 'author', 'text_type', 'journal',
                      'sent_ID', 'noun', 'noun_ID', 'dep_len', 'dep_num',
                      'sent_len', 'sum_dep', 'avg_dep_len', 'deprel', 'pre_mod_num',
                      'post_mod_num', 'det_def', 'PP_num', 'relcl_f_num', 'relcl_nf_num',
                      'nmod_num', 'compound_num', 'adj_num', 'adv_num']
        writer = csv.DictWriter(csv_file, fieldnames = fieldnames)
        
        # add header if output file is empty
        if os.path.getsize(output_file) == 0:
            writer.writeheader()
            
        # initialize list for metadata and noun data combined
        all_data = []    
        
        # combine each line of noun data with current metadata
        for np_data_row in np_data:
            all_data.append({**current_metadata, **np_data_row})
          
        # write metadata and noun data to csv, line by line
        for data_row in all_data:
            writer.writerow(data_row)

          
# function to extract and parse sentences and tokens from CoNLL-U files as nested dictionaries
def process_conllu(data_folder, metadata_folder, metadata_file, output_file):
    # get metadata file path
    metadata_path = os.path.join(metadata_folder, metadata_file)
    # extract relevant metadata from file
    metadata = []
    metadata = parse_metadata(metadata_path, metadata)
    
    # go through all conllu files in data folder
    for file in os.listdir(data_folder):
        
        # get text ID
        #text_id = os.path.splitext(file)[0]
        
        # get path of conllu file
        data_path = os.path.join(data_folder, file)
        # open and read conllu file
        data = open(data_path, 'r', encoding = 'utf-8').read()
        # get sentences as nested dictionary
        sentences = parse(data, fields=["id", "form", "lemma", "upos", "pos", "ufeat", "head", "deprel", "empty", "s/e char", "dl", "sl", "sod", "adl"])
        # get tree structure of sentences
        #tree_data = open(data_path, 'r', encoding = 'utf-8')
        #trees = parse_tree(tree_data)
        
        # parse sentences
        np_data = [] # initialize dict for noun data
        np_data = parse_sents(sentences, np_data)
        
        
        # initialize variables for metadata
        current_text_id = ''
        current_year = ''
        current_author = ''
        current_text_type = ''
        current_journal = ''
        current_metadata = []
        
        #print(os.path.splitext(file)[0])
        
        # get metadata for current file
        for list_item in metadata:
            if list_item['text_id'] == os.path.splitext(file)[0]:
                #print('here')
                current_text_id = list_item['text_id']
                current_year = list_item['year']
                current_author = list_item['author']
                current_text_type = list_item['type']
                current_journal = list_item['journal']
                
                current_metadata = {'text_ID': current_text_id, 'year': current_year, 'author': current_author, 'text_type': current_text_type, 'journal': current_journal}
                
                #print(current_metadata)
        
                
        # write to output file
        write_to_csv(current_metadata, np_data, output_file)
                
        print("Processing " + file + "...")
               
    return None


# main function  
if __name__ == "__main__":

    # folder with conllu data files
    data_folder = 'C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20250228/data/batch_1'
    #data_folder = 'C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20240408/data/test'
    
    # folder containing metadata file
    metadata_folder = 'C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20250228/data'
    # file containing metadata
    metadata_file = 'C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20250228/data/rsc_surp_dep.metadata'
    
    # output file
    output_file = 'C:/Users/isabell/Documents/UdS/Corpus_Analysis/RSC/LMM/analysis_20250228/data/noun_data_b1_v3.csv'
    
    process_conllu(data_folder, metadata_folder, metadata_file, output_file)
    

    print('Done.')
    
    
    

