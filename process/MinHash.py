import hashlib
import itertools
import pandas as pd
import random
import numpy as np
import scipy.optimize as opt
import math
from collections import defaultdict

def shingle_document(string, k):
  # initialize set data structure
  shingle_set = set()
  
  # for each position in string,
  for i in range(len(string)-k):
    # extract substring of length k
    substr = string[i:i + k]
    
    # hash substring into 32-bit integer using crc32
    hashed = hashlib.sha1(substr).hexdigest()
    
    # insert into set
    shingle_set.add(hashed)
    
  # return set
  return(shingle_set)


def jaccard(a, b):
  # compute union size
  union = a | b
  
  # compute intersection size
  intersection = a & b
  
  # return ratio of union and intersection
  return(float(len(intersection))/float(len(union)))


def invert_shingles(shingled_documents):
  # initialize list for tuples
  inverted_shingles = []
  
  # initialize list for document ids
  document_ids = []
  
  # for each document in input
  for doc in shingled_documents:
    # append document id to list
    document_ids.append(doc[0])
    
    # for each item in document
    for item in doc[1]:
      # append (item, docid) tuple
      inverted_shingles.append((item, doc[0]))
  
  # sort tuple list
  inverted_shingles.sort(key=lambda x: x[0])
  
  # return sorted tuple list, and document list
  return inverted_shingles, document_ids


def make_random_hash_fn(p=2**33-355, m=4294967295):
    a = random.randint(1,p-1)
    b = random.randint(0, p-1)
    return lambda x: ((a * x + b) % p) % m


def make_hashes(num_hash):
    function_list = []
    
    for i in range(num_hash):
        function_list.append(make_random_hash_fn())
    
    return function_list


def make_minhash_signature(shingled_data, num_hashes):
    inv_index, docids = invert_shingles(shingled_data)
    num_docs = len(docids)
    
    # initialize the signature matrix with infinity in every entry
    sigmatrix = np.full([num_hashes, num_docs], np.inf)
    
    # generate hash functions
    hash_funcs = make_hashes(num_hashes)
    
    # iterate over each non-zero entry of the characteristic matrix
    for row, docid in inv_index:
        doc_ind = docids.index(docid)
        
        # update signature matrix if needed
        for h in range(num_hashes):
            hsh = hash_funcs[h](row)
            
            if hsh < sigmatrix[h, doc_ind]:
                sigmatrix[h, doc_ind] = hsh
    
    return sigmatrix, docids


def minhash_similarity(id1, id2, minhash_sigmat, docids):
    id1_ind = docids.index(id1)
    id2_ind = docids.index(id2)
    
    id1_column = minhash_sigmat[ : , id1_ind]
    id2_column = minhash_sigmat[ : , id2_ind]
    
    matches = 0
    for i in range(len(id1_column)):
        if id1_column[i] == id2_column[i]:
            matches += 1
    
    return float(matches)/len(id1_column)



def minhash_pair_similarity(shingled_documents, num_hashes):
    sigmat, docids = make_minhash_signature(shingled_documents, num_hashes)
    
    tups = []
    for comb in itertools.combinations(docids, 2):
        id1 = comb[0]
        id2 = comb[1]
      
        sim = minhash_similarity(id1, id2, sigmat, docids)
      
        tups.append((id1, id2, sim))
    
    return tups



def _choose_nbands(t, n):
    def _error_fun(x):
        cur_t = (1/x[0])**(x[0]/n)
        return (t-cur_t)**2
    
    opt_res = opt.minimize(_error_fun, x0=(10), method='Nelder-Mead')
    b = int(math.ceil(opt_res['x'][0]))
    r = int(n / b)
    final_t = (1/b)**(1/r)
    return b, final_t

def _make_vector_hash(num_hashes, m=4294967295):
    hash_fns = make_hashes(num_hashes)
    def _f(vec):
      acc = 0
      for i in range(len(vec)):
        h = hash_fns[i]
        acc += h(vec[i])
      return acc % m
    return _f


def do_lsh(minhash_sigmatrix, numhashes, docids, threshold):
    # choose the number of bands, and rows per band to use in LSH
    b, _ = _choose_nbands(threshold, numhashes)
    r = int(numhashes / b)
    
    narticles = len(docids)
    
    # generate a random hash function that takes vectors of lenght r as input
    hash_func = _make_vector_hash(r)
    
    # setup the list of hashtables, will be populated with one hashtable per band
    buckets = []
    
    # fill hash tables for each band
    for band in range(b):
        # figure out which rows of minhash signature matrix to hash for this band
        start_index = int(band * r)
        end_index = min(start_index + r, numhashes)
        
        # initialize hashtable for this band
        cur_buckets = defaultdict(list)
        
        for j in range(narticles):
            # THIS IS WHAT YOU NEED TO IMPLEMENT
            hashed = hash_func(minhash_sigmatrix[start_index:end_index, j])
            
            cur_buckets[hashed].append(docids[j])
        
        # add this hashtable to the list of hashtables
        buckets.append(cur_buckets)
        
    return buckets


def candidate_article_pairs(buckets):
    pairs = []
    for band in buckets:
        for hash in band:
            if len(band[hash]) > 1:
                for comb in itertools.combinations(band[hash], 2):
                    if (comb) not in pairs:
                        pairs.append((comb))
    return pairs


hash_size = 4

abstacts = pd.read_csv('abstracts.csv')

dat = zip(range(abstacts.shape[0]), abstacts['text'])

shingled_documents = []
for comb in dat:
  shingled_documents.append((comb[0], shingle_document(comb[1], hash_size)))

minhash_sigmatrix, docids = make_minhash_signature(shingled_documents, hash_size)



mpldf = pd.DataFrame()
for t in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
    print(t)
    
    buckets = do_lsh(minhash_sigmatrix, hash_size, docids, t)

    pairs = candidate_article_pairs(buckets)

    truth = open('articles_' + str(n) + '.truth').read().splitlines()
    truth = list(map(lambda x: tuple(x.split(' ')), truth))

    tp = len([pairs for p in pairs if p in truth])
    fn = len([truth for t in truth if t not in pairs])
    fp = len([pairs for p in pairs if p not in truth])
    tn = n**2 - (fp + fn + tp)
    
    temp = pd.DataFrame.from_dict({'threshold': [t], 'sensitivity': [tp/(tp + fn)], 'specificity': [tn/(tn + fp)]})

    mpldf = mpldf.append(temp)
