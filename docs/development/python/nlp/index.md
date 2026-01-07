---
title: Natural Language Processing with Python
description: Comprehensive guide to natural language processing techniques and libraries in Python
---

## Overview

Natural Language Processing (NLP) is a field of artificial intelligence that focuses on the interaction between computers and human language. Python has become the dominant language for NLP due to its rich ecosystem of libraries and frameworks for text processing, linguistic analysis, and language understanding.

## Key Concepts

- **Tokenization**: Breaking text into words, sentences, or subwords
- **Part-of-Speech Tagging**: Identifying grammatical roles of words
- **Named Entity Recognition**: Extracting entities like people, places, organizations
- **Sentiment Analysis**: Determining emotional tone of text
- **Topic Modeling**: Discovering abstract topics in document collections
- **Language Models**: Predicting and generating natural language text

## Popular NLP Libraries

### Core Libraries

- **NLTK**: Natural Language Toolkit for fundamental NLP tasks
- **spaCy**: Industrial-strength NLP with pre-trained models
- **Transformers**: Hugging Face library for state-of-the-art models
- **Gensim**: Topic modeling and document similarity
- **TextBlob**: Simplified API for common NLP tasks

### Deep Learning Frameworks

- **PyTorch**: Flexible framework for custom NLP models
- **TensorFlow**: Comprehensive ML platform with Keras integration
- **JAX**: High-performance numerical computing

## Getting Started

### Installation

Install the essential NLP libraries:

```bash
# Core NLP libraries
pip install nltk spacy textblob

# Deep learning and transformers
pip install transformers torch

# Topic modeling and similarity
pip install gensim

# Data manipulation
pip install pandas numpy scikit-learn
```

Download required language models:

```python
# Download NLTK data
import nltk
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('maxent_ne_chunker')
nltk.download('words')
nltk.download('stopwords')
nltk.download('wordnet')

# Download spaCy English model
# Run in terminal:
# python -m spacy download en_core_web_sm
```

### Basic Text Processing

Start with fundamental text operations:

```python
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize

# Sample text
text = """Natural language processing (NLP) is a subfield of linguistics, 
computer science, and artificial intelligence. It focuses on the interactions 
between computers and human language."""

# Sentence tokenization
sentences = sent_tokenize(text)
print(f"Sentences: {len(sentences)}")
# Output: Sentences: 2

# Word tokenization
words = word_tokenize(text)
print(f"Words: {len(words)}")
# Output: Words: 28

# Basic statistics
print(f"Characters: {len(text)}")
print(f"Unique words: {len(set(words))}")
```

Simple text cleaning:

```python
import re
import string

def clean_text(text):
    """Clean and normalize text."""
    # Convert to lowercase
    text = text.lower()
    
    # Remove URLs
    text = re.sub(r'http\S+|www\S+', '', text)
    
    # Remove email addresses
    text = re.sub(r'\S+@\S+', '', text)
    
    # Remove punctuation
    text = text.translate(str.maketrans('', '', string.punctuation))
    
    # Remove extra whitespace
    text = ' '.join(text.split())
    
    return text

# Example usage
raw_text = "Check out https://example.com! Email: user@example.com"
cleaned = clean_text(raw_text)
print(cleaned)
# Output: check out email
```

Working with spaCy for advanced processing:

```python
import spacy

# Load English model
nlp = spacy.load("en_core_web_sm")

# Process text
doc = nlp("Apple is looking at buying U.K. startup for $1 billion")

# Extract tokens and their properties
for token in doc:
    print(f"{token.text:12} {token.pos_:8} {token.dep_:10} {token.lemma_}")

# Output:
# Apple        PROPN    nsubj      Apple
# is           AUX      aux        be
# looking      VERB     ROOT       look
# at           ADP      prep       at
# buying       VERB     pcomp      buy
# U.K.         PROPN    dobj       U.K.
# startup      NOUN     dobj       startup
# for          ADP      prep       for
# $            SYM      quantmod   $
# 1            NUM      compound   1
# billion      NUM      pobj       billion
```

## Text Preprocessing

### Cleaning and Normalization

Text normalization ensures consistent formatting:

```python
import re
import unicodedata

def normalize_text(text):
    """Comprehensive text normalization."""
    # Unicode normalization (handle accents, special characters)
    text = unicodedata.normalize('NFKD', text)
    text = text.encode('ascii', 'ignore').decode('utf-8')
    
    # Convert to lowercase
    text = text.lower()
    
    # Remove HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    
    # Replace contractions
    contractions = {
        "n't": " not",
        "'re": " are",
        "'s": " is",
        "'d": " would",
        "'ll": " will",
        "'ve": " have",
        "'m": " am"
    }
    for contraction, replacement in contractions.items():
        text = text.replace(contraction, replacement)
    
    # Normalize whitespace
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text

# Example
text = "We'll visit café & restaurant. It's great!"
normalized = normalize_text(text)
print(normalized)
# Output: we will visit cafe and restaurant it is great
```

Handle special characters and emojis:

```python
def remove_emojis(text):
    """Remove emojis from text."""
    emoji_pattern = re.compile(
        "["
        u"\U0001F600-\U0001F64F"  # emoticons
        u"\U0001F300-\U0001F5FF"  # symbols & pictographs
        u"\U0001F680-\U0001F6FF"  # transport & map symbols
        u"\U0001F1E0-\U0001F1FF"  # flags
        u"\U00002702-\U000027B0"
        u"\U000024C2-\U0001F251"
        "]+",
        flags=re.UNICODE
    )
    return emoji_pattern.sub(r'', text)

# Example
text_with_emoji = "I love Python! 😍 It's amazing! 🚀"
clean_text = remove_emojis(text_with_emoji)
print(clean_text)
# Output: I love Python!  It's amazing!
```

### Tokenization

Breaking text into meaningful units:

```python
from nltk.tokenize import word_tokenize, sent_tokenize, regexp_tokenize
from nltk.tokenize import TweetTokenizer, MWETokenizer

# Word tokenization
text = "Don't forget: NLP is awesome! Visit https://example.com."
words = word_tokenize(text)
print(words)
# Output: ['Do', "n't", 'forget', ':', 'NLP', 'is', 'awesome', '!', 'Visit', 'https', ':', '//example.com', '.']

# Sentence tokenization
text = "Dr. Smith works at U.S. Labs. She studies AI. Her work is groundbreaking!"
sentences = sent_tokenize(text)
print(sentences)
# Output: ['Dr. Smith works at U.S. Labs.', 'She studies AI.', 'Her work is groundbreaking!']

# Tweet tokenization (preserves hashtags, mentions, emoticons)
tweet_tokenizer = TweetTokenizer()
tweet = "@user Check out #NLP! 😊 https://t.co/abc"
tokens = tweet_tokenizer.tokenize(tweet)
print(tokens)
# Output: ['@user', 'Check', 'out', '#NLP', '!', '😊', 'https://t.co/abc']

# Multi-word expression tokenization
mwe = MWETokenizer([('machine', 'learning'), ('natural', 'language')])
text = "machine learning and natural language processing"
tokens = mwe.tokenize(text.split())
print(tokens)
# Output: ['machine_learning', 'and', 'natural_language', 'processing']

# Regular expression tokenization
text = "Phone: 555-1234, Email: user@example.com"
phone_numbers = regexp_tokenize(text, r'\d{3}-\d{4}')
print(phone_numbers)
# Output: ['555-1234']
```

Advanced tokenization with spaCy:

```python
import spacy

nlp = spacy.load("en_core_web_sm")
text = "Apple's CEO Tim Cook announced iPhone 15."

doc = nlp(text)

# Token-level information
for token in doc:
    print(f"{token.text:10} | {token.is_alpha:5} | {token.is_stop:5} | {token.is_punct:5}")

# Output:
# Apple      | True  | False | False
# 's         | False | False | False
# CEO        | True  | False | False
# Tim        | True  | False | False
# Cook       | True  | False | False
# announced  | True  | False | False
# iPhone     | True  | False | False
# 15         | False | False | False
# .          | False | False | True
```

### Stopword Removal

Remove common words that don't carry significant meaning:

```python
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

# Get English stopwords
stop_words = set(stopwords.words('english'))
print(f"Number of stopwords: {len(stop_words)}")
# Output: Number of stopwords: 179

# Filter stopwords
text = "The quick brown fox jumps over the lazy dog"
words = word_tokenize(text.lower())
filtered_words = [w for w in words if w not in stop_words]

print(f"Original: {words}")
print(f"Filtered: {filtered_words}")
# Original: ['the', 'quick', 'brown', 'fox', 'jumps', 'over', 'the', 'lazy', 'dog']
# Filtered: ['quick', 'brown', 'fox', 'jumps', 'lazy', 'dog']

# Custom stopwords
custom_stop_words = stop_words.union({'quick', 'brown'})
filtered_custom = [w for w in words if w not in custom_stop_words]
print(f"Custom filtered: {filtered_custom}")
# Custom filtered: ['fox', 'jumps', 'lazy', 'dog']
```

Using spaCy for stopword removal:

```python
import spacy

nlp = spacy.load("en_core_web_sm")
text = "This is an example sentence demonstrating stopword removal."

doc = nlp(text)
filtered = [token.text for token in doc if not token.is_stop]
print(filtered)
# Output: ['example', 'sentence', 'demonstrating', 'stopword', 'removal', '.']
```

### Stemming and Lemmatization

Reduce words to their base or root form:

```python
from nltk.stem import PorterStemmer, LancasterStemmer, SnowballStemmer
from nltk.stem import WordNetLemmatizer
from nltk.corpus import wordnet

# Stemming - crude heuristic chopping
porter = PorterStemmer()
lancaster = LancasterStemmer()
snowball = SnowballStemmer('english')

words = ['running', 'runs', 'ran', 'runner', 'easily', 'fairly']

print("Porter Stemmer:")
for word in words:
    print(f"{word:10} -> {porter.stem(word)}")
# Output:
# running    -> run
# runs       -> run
# ran        -> ran
# runner     -> runner
# easily     -> easili
# fairly     -> fairli

print("\nLancaster Stemmer (more aggressive):")
for word in words:
    print(f"{word:10} -> {lancaster.stem(word)}")
# Output:
# running    -> run
# runs       -> run
# ran        -> ran
# runner     -> run
# easily     -> easy
# fairly     -> fair

# Lemmatization - dictionary-based reduction
lemmatizer = WordNetLemmatizer()

# Lemmatization requires POS tag
words_with_pos = [
    ('running', 'v'),
    ('runs', 'v'),
    ('ran', 'v'),
    ('runner', 'n'),
    ('better', 'a'),
    ('best', 'a')
]

print("\nLemmatization (with POS tags):")
for word, pos in words_with_pos:
    lemma = lemmatizer.lemmatize(word, pos=pos)
    print(f"{word:10} ({pos}) -> {lemma}")
# Output:
# running    (v) -> run
# runs       (v) -> run
# ran        (v) -> run
# runner     (n) -> runner
# better     (a) -> good
# best       (a) -> good
```

Lemmatization with spaCy (automatic POS detection):

```python
import spacy

nlp = spacy.load("en_core_web_sm")
text = "The striped bats are hanging on their feet for best"

doc = nlp(text)
for token in doc:
    print(f"{token.text:10} -> {token.lemma_:10} ({token.pos_})")
# Output:
# The        -> the        (DET)
# striped    -> stripe     (VERB)
# bats       -> bat        (NOUN)
# are        -> be         (AUX)
# hanging    -> hang       (VERB)
# on         -> on         (ADP)
# their      -> their      (PRON)
# feet       -> foot       (NOUN)
# for        -> for        (ADP)
# best       -> good       (ADJ)
```

Complete preprocessing pipeline:

```python
import spacy
from nltk.corpus import stopwords

nlp = spacy.load("en_core_web_sm")
stop_words = set(stopwords.words('english'))

def preprocess_text(text):
    """Complete preprocessing pipeline."""
    # Process with spaCy
    doc = nlp(text.lower())
    
    # Lemmatize, remove stopwords and punctuation
    tokens = [
        token.lemma_ 
        for token in doc 
        if not token.is_stop 
        and not token.is_punct 
        and token.is_alpha
    ]
    
    return tokens

# Example
text = "The researchers are studying natural language processing techniques."
processed = preprocess_text(text)
print(processed)
# Output: ['researcher', 'study', 'natural', 'language', 'processing', 'technique']
```

## Feature Extraction

### Bag of Words

Convert text to numerical feature vectors based on word frequency:

```python
from sklearn.feature_extraction.text import CountVectorizer
import pandas as pd

# Sample documents
documents = [
    "Natural language processing is fascinating",
    "Machine learning and NLP are related",
    "Deep learning models for NLP",
    "Processing natural language with Python"
]

# Create bag of words
vectorizer = CountVectorizer()
bow_matrix = vectorizer.fit_transform(documents)

# View feature names
feature_names = vectorizer.get_feature_names_out()
print("Feature names:", feature_names)

# Convert to DataFrame for better visualization
df = pd.DataFrame(bow_matrix.toarray(), columns=feature_names)
print(df)

# Output:
#    and  are  deep  fascinating  for  ...  processing  python  related  with
# 0    0    0     0            1    0  ...           1       0        0     0
# 1    1    1     0            0    0  ...           0       0        1     0
# 2    0    0     1            0    1  ...           0       0        0     0
# 3    0    0     0            0    0  ...           1       1        0     1

# Parameters for customization
vectorizer_custom = CountVectorizer(
    max_features=10,        # Keep top 10 features
    min_df=1,              # Minimum document frequency
    max_df=0.8,            # Maximum document frequency (ignore too common words)
    ngram_range=(1, 2),    # Include unigrams and bigrams
    stop_words='english'    # Remove stop words
)

bow_custom = vectorizer_custom.fit_transform(documents)
print("\nCustom features:", vectorizer_custom.get_feature_names_out())
```

Binary bag of words (presence/absence):

```python
from sklearn.feature_extraction.text import CountVectorizer

vectorizer_binary = CountVectorizer(binary=True)
binary_matrix = vectorizer_binary.fit_transform(documents)

print("Binary representation:")
print(binary_matrix.toarray())
# Each cell is 1 if word appears, 0 otherwise
```

### TF-IDF

Term Frequency-Inverse Document Frequency weighs word importance:

```python
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np

documents = [
    "The cat sat on the mat",
    "The dog sat on the log",
    "Cats and dogs are animals",
    "The mat is on the floor"
]

# Create TF-IDF vectorizer
tfidf = TfidfVectorizer()
tfidf_matrix = tfidf.fit_transform(documents)

# Get feature names
feature_names = tfidf.get_feature_names_out()

# View TF-IDF scores
df_tfidf = pd.DataFrame(
    tfidf_matrix.toarray(),
    columns=feature_names
)
print(df_tfidf.round(3))

# Find most important words per document
for idx, doc in enumerate(documents):
    print(f"\nDocument {idx}: '{doc}'")
    
    # Get TF-IDF scores for this document
    scores = tfidf_matrix[idx].toarray().flatten()
    
    # Get top 3 terms
    top_indices = np.argsort(scores)[-3:][::-1]
    top_terms = [(feature_names[i], scores[i]) for i in top_indices if scores[i] > 0]
    
    print("Top terms:", top_terms)

# Output example:
# Document 0: 'The cat sat on the mat'
# Top terms: [('cat', 0.447), ('mat', 0.447), ('sat', 0.346)]
```

Advanced TF-IDF configuration:

```python
# Customized TF-IDF
tfidf_custom = TfidfVectorizer(
    max_features=50,           # Limit vocabulary size
    min_df=2,                  # Ignore terms in fewer than 2 documents
    max_df=0.8,               # Ignore terms in more than 80% of documents
    ngram_range=(1, 3),       # Unigrams, bigrams, trigrams
    sublinear_tf=True,        # Use log scaling for term frequency
    use_idf=True,             # Enable IDF weighting
    smooth_idf=True,          # Add 1 to document frequencies
    norm='l2',                # L2 normalization
    stop_words='english'       # Remove English stop words
)

tfidf_custom_matrix = tfidf_custom.fit_transform(documents)
```

Calculate TF-IDF manually:

```python
from sklearn.feature_extraction.text import TfidfTransformer, CountVectorizer

# Step 1: Get term frequencies
count_vectorizer = CountVectorizer()
term_freq = count_vectorizer.fit_transform(documents)

# Step 2: Apply TF-IDF transformation
tfidf_transformer = TfidfTransformer(use_idf=True, smooth_idf=True)
tfidf_manual = tfidf_transformer.fit_transform(term_freq)

print("IDF values:")
feature_names = count_vectorizer.get_feature_names_out()
idf_values = dict(zip(feature_names, tfidf_transformer.idf_))
for term, idf in sorted(idf_values.items(), key=lambda x: x[1], reverse=True)[:5]:
    print(f"{term:15} {idf:.3f}")
```

### Word Embeddings

Dense vector representations that capture semantic relationships:

#### Word2Vec with Gensim

```python
from gensim.models import Word2Vec
from nltk.tokenize import word_tokenize

# Sample corpus
sentences = [
    "Natural language processing is a subfield of AI",
    "Machine learning models can process natural language",
    "Deep learning has revolutionized NLP tasks",
    "Word embeddings capture semantic relationships",
    "Neural networks learn distributed representations"
]

# Tokenize sentences
tokenized_sentences = [word_tokenize(sent.lower()) for sent in sentences]

# Train Word2Vec model
model = Word2Vec(
    sentences=tokenized_sentences,
    vector_size=100,      # Dimensionality of word vectors
    window=5,             # Context window size
    min_count=1,          # Minimum word frequency
    workers=4,            # Number of CPU cores
    sg=0,                 # 0=CBOW, 1=Skip-gram
    epochs=100
)

# Get word vector
vector = model.wv['language']
print(f"Vector for 'language': {vector[:5]}...")  # Show first 5 dimensions

# Find similar words
similar_words = model.wv.most_similar('language', topn=5)
print("\nWords similar to 'language':")
for word, similarity in similar_words:
    print(f"  {word:15} {similarity:.4f}")

# Word arithmetic (semantic relationships)
# King - Man + Woman ≈ Queen
result = model.wv.most_similar(
    positive=['learning', 'neural'],
    negative=['machine'],
    topn=3
)
print("\nlearning - machine + neural:")
for word, score in result:
    print(f"  {word:15} {score:.4f}")

# Compute similarity between words
similarity = model.wv.similarity('learning', 'language')
print(f"\nSimilarity between 'learning' and 'language': {similarity:.4f}")

# Save and load model
model.save("word2vec_model.bin")
loaded_model = Word2Vec.load("word2vec_model.bin")
```

#### Pre-trained Word Embeddings

```python
import gensim.downloader as api

# Load pre-trained GloVe embeddings
glove_vectors = api.load("glove-wiki-gigaword-100")

# Use pre-trained embeddings
vector = glove_vectors['computer']
print(f"Vector shape: {vector.shape}")

# Find similar words
similar = glove_vectors.most_similar('computer', topn=5)
print("\nSimilar to 'computer':")
for word, score in similar:
    print(f"  {word:15} {score:.4f}")

# Available pre-trained models:
# - glove-wiki-gigaword-50/100/200/300
# - word2vec-google-news-300
# - fasttext-wiki-news-subwords-300

# Analogy tasks
result = glove_vectors.most_similar(
    positive=['king', 'woman'],
    negative=['man'],
    topn=1
)
print(f"\nKing - Man + Woman = {result[0][0]}")
```

#### FastText (handles out-of-vocabulary words)

```python
from gensim.models import FastText

# Train FastText model
fasttext_model = FastText(
    sentences=tokenized_sentences,
    vector_size=100,
    window=5,
    min_count=1,
    workers=4,
    sg=1,  # Skip-gram
    epochs=100
)

# Get vector for in-vocabulary word
vector_inv = fasttext_model.wv['language']

# Get vector for out-of-vocabulary word (FastText can handle this!)
vector_oov = fasttext_model.wv['langguage']  # Misspelled word
print(f"OOV vector available: {vector_oov is not None}")

# FastText uses character n-grams to handle OOV words
```

#### Document Embeddings with Doc2Vec

```python
from gensim.models.doc2vec import Doc2Vec, TaggedDocument

# Prepare tagged documents
tagged_docs = [
    TaggedDocument(words=word_tokenize(sent.lower()), tags=[str(i)])
    for i, sent in enumerate(sentences)
]

# Train Doc2Vec model
doc2vec_model = Doc2Vec(
    tagged_docs,
    vector_size=100,
    window=5,
    min_count=1,
    workers=4,
    epochs=100
)

# Get document vector
doc_vector = doc2vec_model.dv['0']
print(f"Document 0 vector shape: {doc_vector.shape}")

# Infer vector for new document
new_doc = word_tokenize("Machine learning for text processing".lower())
new_vector = doc2vec_model.infer_vector(new_doc)
print(f"New document vector shape: {new_vector.shape}")

# Find similar documents
similar_docs = doc2vec_model.dv.most_similar('0', topn=3)
print("\nSimilar documents to document 0:")
for doc_id, similarity in similar_docs:
    print(f"  Document {doc_id}: {similarity:.4f}")
```

#### Using Transformers for Contextual Embeddings

```python
from transformers import AutoTokenizer, AutoModel
import torch

# Load pre-trained model and tokenizer
model_name = "bert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# Encode text
text = "Natural language processing with transformers"
inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True)

# Get embeddings
with torch.no_grad():
    outputs = model(**inputs)
    
# Last hidden state contains token embeddings
embeddings = outputs.last_hidden_state
print(f"Embeddings shape: {embeddings.shape}")
# Output: torch.Size([1, 8, 768]) - [batch, tokens, hidden_size]

# Get sentence embedding (mean pooling)
sentence_embedding = embeddings.mean(dim=1)
print(f"Sentence embedding shape: {sentence_embedding.shape}")
# Output: torch.Size([1, 768])
```

Comparison of embedding methods:

```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

# Compare embeddings for semantic similarity
words = ['king', 'queen', 'man', 'woman', 'computer']

# Using pre-trained GloVe
glove_embeddings = np.array([glove_vectors[word] for word in words])
glove_sim = cosine_similarity(glove_embeddings)

print("Cosine similarity matrix (GloVe):")
df_sim = pd.DataFrame(glove_sim, index=words, columns=words)
print(df_sim.round(3))

# Output shows semantic relationships:
#           king   queen    man   woman  computer
# king     1.000   0.651  0.633   0.513     0.234
# queen    0.651   1.000  0.418   0.632     0.189
# man      0.633   0.418  1.000   0.527     0.243
# woman    0.513   0.632  0.527   1.000     0.197
# computer 0.234   0.189  0.243   0.197     1.000
```

## Core NLP Tasks

### Part-of-Speech Tagging

Identify grammatical roles of words in sentences:

```python
import nltk
from nltk import pos_tag, word_tokenize
from nltk.corpus import brown

# Download required data
nltk.download('averaged_perceptron_tagger')
nltk.download('tagsets')

# Basic POS tagging
text = "The quick brown fox jumps over the lazy dog"
tokens = word_tokenize(text)
pos_tags = pos_tag(tokens)

print("POS Tags:")
for word, tag in pos_tags:
    print(f"{word:10} -> {tag}")

# Output:
# The        -> DT  (Determiner)
# quick      -> JJ  (Adjective)
# brown      -> JJ  (Adjective)
# fox        -> NN  (Noun, singular)
# jumps      -> VBZ (Verb, 3rd person singular present)
# over       -> IN  (Preposition)
# the        -> DT  (Determiner)
# lazy       -> JJ  (Adjective)
# dog        -> NN  (Noun, singular)

# View tag descriptions
nltk.help.upenn_tagset('NN')
nltk.help.upenn_tagset('VB*')  # All verb tags
```

POS tagging with spaCy (more accurate):

```python
import spacy

nlp = spacy.load("en_core_web_sm")
text = "Apple is looking at buying U.K. startup for $1 billion"

doc = nlp(text)

print("spaCy POS Tags:")
for token in doc:
    print(f"{token.text:12} {token.pos_:8} {token.tag_:8} {token.dep_:10}")
    
# Output:
# Apple        PROPN    NNP      nsubj
# is           AUX      VBZ      aux
# looking      VERB     VBG      ROOT
# at           ADP      IN       prep
# buying       VERB     VBG      pcomp
# U.K.         PROPN    NNP      compound
# startup      NOUN     NN       dobj
# for          ADP      IN       prep
# $            SYM      $        quantmod
# 1            NUM      CD       compound
# billion      NUM      CD       pobj
```

Extract words by POS tag:

```python
def extract_by_pos(text, pos_tags):
    """Extract words with specific POS tags."""
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(text)
    
    return [token.text for token in doc if token.pos_ in pos_tags]

text = "The brilliant scientist quickly discovered an amazing breakthrough"

# Extract adjectives
adjectives = extract_by_pos(text, ['ADJ'])
print(f"Adjectives: {adjectives}")
# Output: Adjectives: ['brilliant', 'amazing']

# Extract nouns
nouns = extract_by_pos(text, ['NOUN', 'PROPN'])
print(f"Nouns: {nouns}")
# Output: Nouns: ['scientist', 'breakthrough']

# Extract verbs
verbs = extract_by_pos(text, ['VERB'])
print(f"Verbs: {verbs}")
# Output: Verbs: ['discovered']
```

### Named Entity Recognition

Extract and classify named entities (people, organizations, locations, etc.):

```python
import spacy
from spacy import displacy

nlp = spacy.load("en_core_web_sm")

text = """Apple Inc. was founded by Steve Jobs in Cupertino, California. 
The company released the iPhone on June 29, 2007. Tim Cook became CEO in August 2011."""

doc = nlp(text)

# Extract named entities
print("Named Entities:")
for ent in doc.ents:
    print(f"{ent.text:20} -> {ent.label_:15} ({spacy.explain(ent.label_)})")

# Output:
# Apple Inc.           -> ORG             (Companies, agencies, institutions)
# Steve Jobs           -> PERSON          (People, including fictional)
# Cupertino            -> GPE             (Countries, cities, states)
# California           -> GPE             (Countries, cities, states)
# iPhone               -> PRODUCT         (Objects, vehicles, foods, etc.)
# June 29, 2007        -> DATE            (Absolute or relative dates or periods)
# Tim Cook             -> PERSON          (People, including fictional)
# August 2011          -> DATE            (Absolute or relative dates or periods)

# Visualize entities (in Jupyter notebooks)
displacy.render(doc, style="ent", jupyter=True)

# Save visualization to HTML
html = displacy.render(doc, style="ent", page=True)
with open("entities.html", "w", encoding="utf-8") as f:
    f.write(html)
```

Filter entities by type:

```python
def get_entities_by_type(text, entity_types):
    """Extract entities of specific types."""
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(text)
    
    entities = {}
    for ent_type in entity_types:
        entities[ent_type] = [ent.text for ent in doc.ents if ent.label_ == ent_type]
    
    return entities

text = """Microsoft and Google are competing in AI. 
Bill Gates and Sundar Pichai lead innovation in Seattle and Mountain View."""

entities = get_entities_by_type(text, ['ORG', 'PERSON', 'GPE'])

for ent_type, ent_list in entities.items():
    print(f"{ent_type}: {ent_list}")

# Output:
# ORG: ['Microsoft', 'Google']
# PERSON: ['Bill Gates', 'Sundar Pichai']
# GPE: ['Seattle', 'Mountain View']
```

Custom NER with spaCy:

```python
import spacy
from spacy.training import Example

# Create blank model
nlp = spacy.blank("en")

# Add NER component
ner = nlp.add_pipe("ner")

# Add labels
ner.add_label("PRODUCT")
ner.add_label("BRAND")

# Training data
TRAIN_DATA = [
    ("iPhone 15 Pro is the latest from Apple", {
        "entities": [(0, 12, "PRODUCT"), (32, 37, "BRAND")]
    }),
    ("Samsung Galaxy S23 is a flagship phone", {
        "entities": [(0, 7, "BRAND"), (8, 18, "PRODUCT")]
    })
]

# Train model
optimizer = nlp.initialize()
for epoch in range(10):
    for text, annotations in TRAIN_DATA:
        doc = nlp.make_doc(text)
        example = Example.from_dict(doc, annotations)
        nlp.update([example], sgd=optimizer)

# Test custom NER
test_text = "The new iPhone 15 from Apple is impressive"
doc = nlp(test_text)
for ent in doc.ents:
    print(f"{ent.text} -> {ent.label_}")
```

### Dependency Parsing

Analyze grammatical structure and relationships:

```python
import spacy
from spacy import displacy

nlp = spacy.load("en_core_web_sm")
text = "The cat sat on the mat"

doc = nlp(text)

# Display dependency relationships
print("Dependencies:")
for token in doc:
    print(f"{token.text:10} <- {token.dep_:10} <- {token.head.text}")

# Output:
# The        <- det        <- cat
# cat        <- nsubj      <- sat
# sat        <- ROOT       <- sat
# on         <- prep       <- sat
# the        <- det        <- mat
# mat        <- pobj       <- on

# Visualize dependency tree
displacy.render(doc, style="dep", jupyter=True)

# Extract subject-verb-object triples
def extract_svo(text):
    """Extract Subject-Verb-Object triples."""
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(text)
    
    triples = []
    for token in doc:
        if token.pos_ == "VERB":
            subject = None
            obj = None
            
            for child in token.children:
                if child.dep_ in ["nsubj", "nsubjpass"]:
                    subject = child.text
                elif child.dep_ in ["dobj", "attr", "pobj"]:
                    obj = child.text
            
            if subject and obj:
                triples.append((subject, token.text, obj))
    
    return triples

text = "The dog chased the cat. The cat climbed the tree."
triples = extract_svo(text)
print("\nSubject-Verb-Object triples:")
for subj, verb, obj in triples:
    print(f"{subj} -> {verb} -> {obj}")

# Output:
# dog -> chased -> cat
# cat -> climbed -> tree
```

Noun phrase extraction:

```python
def extract_noun_phrases(text):
    """Extract noun phrases from text."""
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(text)
    
    return [chunk.text for chunk in doc.noun_chunks]

text = "The quick brown fox jumps over the lazy dog in the park"
noun_phrases = extract_noun_phrases(text)

print("Noun phrases:")
for np in noun_phrases:
    print(f"  - {np}")

# Output:
# Noun phrases:
#   - The quick brown fox
#   - the lazy dog
#   - the park
```

### Coreference Resolution

Identify when different expressions refer to the same entity:

```python
# Install neuralcoref: pip install neuralcoref
import spacy
import neuralcoref

# Load spaCy model
nlp = spacy.load("en_core_web_sm")

# Add coreference resolution to pipeline
neuralcoref.add_to_pipe(nlp)

text = """
John went to the store. He bought milk and bread. 
Mary saw him there. She waved at John.
"""

doc = nlp(text)

# Print coreferences
print("Coreferences:")
if doc._.has_coref:
    for cluster in doc._.coref_clusters:
        print(f"{cluster.main} -> {cluster.mentions}")

# Output example:
# John -> [John, He, him, John]
# Mary -> [Mary, She]

# Resolve coreferences
resolved_text = doc._.coref_resolved
print("\nResolved text:")
print(resolved_text)
```

Alternative using AllenNLP:

```python
# Install: pip install allennlp allennlp-models
from allennlp.predictors.predictor import Predictor

predictor = Predictor.from_path(
    "https://storage.googleapis.com/allennlp-public-models/coref-spanbert-large-2021.03.10.tar.gz"
)

text = "Paul Allen was born in Seattle. He founded Microsoft with Bill Gates."

prediction = predictor.predict(document=text)

print("Coreference clusters:")
for cluster in prediction['clusters']:
    mentions = [' '.join(prediction['document'][start:end+1]) 
                for start, end in cluster]
    print(f"  {mentions}")

# Output:
#   ['Paul Allen', 'He']
#   ['Seattle']
#   ['Microsoft']
#   ['Bill Gates']
```

## Text Classification

### Sentiment Analysis

Determine the emotional tone or opinion expressed in text:

```python
from textblob import TextBlob
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer

# Simple sentiment with TextBlob
def analyze_sentiment_textblob(text):
    """Analyze sentiment using TextBlob."""
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity  # -1 to 1
    subjectivity = blob.sentiment.subjectivity  # 0 to 1
    
    if polarity > 0:
        sentiment = "Positive"
    elif polarity < 0:
        sentiment = "Negative"
    else:
        sentiment = "Neutral"
    
    return {
        'sentiment': sentiment,
        'polarity': polarity,
        'subjectivity': subjectivity
    }

# Test examples
reviews = [
    "This product is absolutely amazing! I love it!",
    "Terrible quality. Waste of money.",
    "It's okay, nothing special.",
]

for review in reviews:
    result = analyze_sentiment_textblob(review)
    print(f"Review: {review}")
    print(f"Result: {result}\n")

# Output:
# Review: This product is absolutely amazing! I love it!
# Result: {'sentiment': 'Positive', 'polarity': 0.625, 'subjectivity': 0.7}
```

VADER sentiment analysis (better for social media):

```python
# Download VADER lexicon
nltk.download('vader_lexicon')

sia = SentimentIntensityAnalyzer()

def analyze_sentiment_vader(text):
    """Analyze sentiment using VADER."""
    scores = sia.polarity_scores(text)
    
    # Compound score: -1 (most negative) to 1 (most positive)
    if scores['compound'] >= 0.05:
        sentiment = 'Positive'
    elif scores['compound'] <= -0.05:
        sentiment = 'Negative'
    else:
        sentiment = 'Neutral'
    
    return {
        'sentiment': sentiment,
        'scores': scores
    }

# Test with social media text
tweets = [
    "I love this product! 😍 #amazing",
    "This is terrible 😡 Very disappointed!!!",
    "It's okay I guess...",
    "BEST PURCHASE EVER!!!"
]

for tweet in tweets:
    result = analyze_sentiment_vader(tweet)
    print(f"Tweet: {tweet}")
    print(f"Sentiment: {result['sentiment']}")
    print(f"Scores: {result['scores']}\n")
```

Machine learning-based sentiment analysis:

```python
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
import pandas as pd

# Sample dataset
data = {
    'text': [
        "This movie is fantastic! Best I've seen",
        "Absolutely loved it. Highly recommend",
        "Great acting and storyline",
        "Terrible movie, waste of time",
        "Boring and predictable",
        "Worst movie ever made",
        "It was okay, not great not bad",
        "Mediocre at best"
    ],
    'sentiment': ['positive', 'positive', 'positive', 'negative', 
                  'negative', 'negative', 'neutral', 'neutral']
}

df = pd.DataFrame(data)

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    df['text'], df['sentiment'], test_size=0.2, random_state=42
)

# Vectorize text
vectorizer = TfidfVectorizer(max_features=100)
X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# Train classifier
classifier = MultinomialNB()
classifier.fit(X_train_vec, y_train)

# Predict
y_pred = classifier.predict(X_test_vec)

# Evaluate
print(f"Accuracy: {accuracy_score(y_test, y_pred):.2f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Predict new text
new_reviews = ["This is an excellent product!", "I hate this so much"]
new_vec = vectorizer.transform(new_reviews)
predictions = classifier.predict(new_vec)

for review, pred in zip(new_reviews, predictions):
    print(f"Review: {review}")
    print(f"Predicted sentiment: {pred}\n")
```

Deep learning sentiment analysis with transformers:

```python
from transformers import pipeline

# Load pre-trained sentiment analysis model
sentiment_analyzer = pipeline(
    "sentiment-analysis",
    model="distilbert-base-uncased-finetuned-sst-2-english"
)

# Analyze sentiment
texts = [
    "I absolutely love this product!",
    "This is the worst thing I've ever bought.",
    "It's alright, I guess."
]

results = sentiment_analyzer(texts)

for text, result in zip(texts, results):
    print(f"Text: {text}")
    print(f"Sentiment: {result['label']} (confidence: {result['score']:.4f})\n")

# Output:
# Text: I absolutely love this product!
# Sentiment: POSITIVE (confidence: 0.9998)
#
# Text: This is the worst thing I've ever bought.
# Sentiment: NEGATIVE (confidence: 0.9997)
```

### Spam Detection

Classify messages as spam or legitimate:

```python
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import pandas as pd

# Sample spam dataset
spam_data = {
    'message': [
        "Congratulations! You've won $1000. Click here to claim",
        "Hi, can we meet for coffee tomorrow?",
        "URGENT: Your account will be suspended. Verify now!",
        "Thanks for your help yesterday",
        "FREE MONEY!!! Click now to get rich quick!!!",
        "Meeting at 3pm in conference room B",
        "Act now! Limited time offer. Buy now!",
        "Happy birthday! Hope you have a great day",
    ],
    'label': ['spam', 'ham', 'spam', 'ham', 'spam', 'ham', 'spam', 'ham']
}

df = pd.DataFrame(spam_data)

# Feature engineering
def extract_features(text):
    """Extract features for spam detection."""
    features = {
        'length': len(text),
        'num_caps': sum(1 for c in text if c.isupper()),
        'num_exclamation': text.count('!'),
        'num_question': text.count('?'),
        'has_currency': any(symbol in text for symbol in ['$', '£', '€']),
        'num_words': len(text.split())
    }
    return features

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    df['message'], df['label'], test_size=0.25, random_state=42
)

# Vectorize with TF-IDF
vectorizer = TfidfVectorizer(
    max_features=500,
    min_df=1,
    max_df=0.8,
    stop_words='english',
    ngram_range=(1, 2)
)

X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# Train classifier
spam_classifier = MultinomialNB(alpha=0.1)
spam_classifier.fit(X_train_vec, y_train)

# Predict
y_pred = spam_classifier.predict(X_test_vec)

# Evaluate
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# Predict new messages
new_messages = [
    "You've won a free iPhone! Click here!",
    "See you at the meeting tomorrow"
]

new_vec = vectorizer.transform(new_messages)
predictions = spam_classifier.predict(new_vec)
probabilities = spam_classifier.predict_proba(new_vec)

for msg, pred, proba in zip(new_messages, predictions, probabilities):
    print(f"\nMessage: {msg}")
    print(f"Prediction: {pred}")
    print(f"Probability: {proba}")
```

### Intent Classification

Classify user intents in conversational AI:

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline
import numpy as np

# Intent training data
intent_data = {
    'text': [
        "What's the weather like today?",
        "Tell me the weather forecast",
        "Is it going to rain?",
        "Set an alarm for 7am",
        "Wake me up at 6:30",
        "Create an alarm for tomorrow morning",
        "Play some music",
        "I want to listen to jazz",
        "Play my favorite playlist",
        "What time is it?",
        "Tell me the current time",
        "What's the time right now?"
    ],
    'intent': [
        'weather', 'weather', 'weather',
        'set_alarm', 'set_alarm', 'set_alarm',
        'play_music', 'play_music', 'play_music',
        'get_time', 'get_time', 'get_time'
    ]
}

df_intents = pd.DataFrame(intent_data)

# Create pipeline
intent_classifier = Pipeline([
    ('tfidf', TfidfVectorizer(ngram_range=(1, 2))),
    ('clf', SVC(kernel='linear', probability=True))
])

# Train model
intent_classifier.fit(df_intents['text'], df_intents['intent'])

# Test intent classification
test_queries = [
    "Will it be sunny tomorrow?",
    "Set alarm for 8am please",
    "Put on some rock music",
    "What is the time?"
]

for query in test_queries:
    predicted_intent = intent_classifier.predict([query])[0]
    probabilities = intent_classifier.predict_proba([query])[0]
    confidence = max(probabilities)
    
    print(f"\nQuery: {query}")
    print(f"Intent: {predicted_intent}")
    print(f"Confidence: {confidence:.4f}")
```

Multi-label classification:

```python
from sklearn.multioutput import MultiOutputClassifier
from sklearn.ensemble import RandomForestClassifier

# Multi-label data (text can have multiple categories)
multilabel_data = {
    'text': [
        "Machine learning tutorial for beginners",
        "Python data science and visualization",
        "Web development with React and Node.js",
        "Deep learning for computer vision",
    ],
    'category_ml': [1, 1, 0, 1],      # Machine Learning
    'category_python': [1, 1, 0, 1],   # Python
    'category_web': [0, 0, 1, 0],      # Web Development
    'category_viz': [0, 1, 0, 0]       # Data Visualization
}

df_multi = pd.DataFrame(multilabel_data)

# Prepare features and labels
X = df_multi['text']
y = df_multi[['category_ml', 'category_python', 'category_web', 'category_viz']]

# Vectorize
vectorizer = TfidfVectorizer()
X_vec = vectorizer.fit_transform(X)

# Train multi-label classifier
multi_clf = MultiOutputClassifier(RandomForestClassifier())
multi_clf.fit(X_vec, y)

# Predict
test_text = ["Python tutorial on neural networks"]
test_vec = vectorizer.transform(test_text)
predictions = multi_clf.predict(test_vec)

print(f"Text: {test_text[0]}")
print("Predicted categories:")
categories = ['Machine Learning', 'Python', 'Web Development', 'Data Visualization']
for cat, pred in zip(categories, predictions[0]):
    if pred == 1:
        print(f"  - {cat}")
```

## Information Extraction

### Entity Extraction

Extract structured information from unstructured text:

```python
import spacy
import re
from collections import defaultdict

nlp = spacy.load("en_core_web_sm")

def extract_entities(text):
    """Extract entities with their types."""
    doc = nlp(text)
    
    entities = defaultdict(list)
    for ent in doc.ents:
        entities[ent.label_].append(ent.text)
    
    return dict(entities)

text = """
Apple Inc. announced that Tim Cook will lead the keynote at WWDC 2024 
in San Francisco. The company expects to unveil iOS 18 with new AI features.
Shares traded at $185.50 on May 15, 2024.
"""

entities = extract_entities(text)

for entity_type, entity_list in entities.items():
    print(f"\n{entity_type}:")
    for entity in entity_list:
        print(f"  - {entity}")

# Output:
# ORG:
#   - Apple Inc.
# PERSON:
#   - Tim Cook
# EVENT:
#   - WWDC 2024
# GPE:
#   - San Francisco
# PRODUCT:
#   - iOS 18
# MONEY:
#   - $185.50
# DATE:
#   - May 15, 2024
```

Extract contact information:

```python
import re

def extract_contact_info(text):
    """Extract emails, phones, and URLs."""
    
    # Email pattern
    emails = re.findall(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
        text
    )
    
    # Phone pattern (various formats)
    phones = re.findall(
        r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b',
        text
    )
    
    # URL pattern
    urls = re.findall(
        r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
        text
    )
    
    return {
        'emails': emails,
        'phones': phones,
        'urls': urls
    }

text = """
Contact us at support@example.com or call (555) 123-4567.
Visit our website: https://www.example.com
Alternative contact: +1-555-987-6543 or info@company.org
"""

contacts = extract_contact_info(text)

for contact_type, values in contacts.items():
    print(f"\n{contact_type.title()}:")
    for value in values:
        print(f"  - {value}")
```

### Relationship Extraction

Identify relationships between entities:

```python
import spacy
from spacy.matcher import Matcher

nlp = spacy.load("en_core_web_sm")

def extract_relationships(text):
    """Extract entity relationships."""
    doc = nlp(text)
    
    relationships = []
    
    # Find relationships using dependency parsing
    for token in doc:
        if token.pos_ == "VERB":
            subject = None
            obj = None
            
            # Find subject
            for child in token.children:
                if child.dep_ in ["nsubj", "nsubjpass"]:
                    subject = child
            
            # Find object
            for child in token.children:
                if child.dep_ in ["dobj", "pobj", "attr"]:
                    obj = child
            
            if subject and obj:
                # Get full noun phrases
                subj_phrase = " ".join([w.text for w in subject.subtree])
                obj_phrase = " ".join([w.text for w in obj.subtree])
                
                relationships.append({
                    'subject': subj_phrase,
                    'relation': token.lemma_,
                    'object': obj_phrase
                })
    
    return relationships

text = """
Steve Jobs founded Apple in 1976. Tim Cook succeeded him as CEO in 2011.
Microsoft acquired LinkedIn for $26 billion. 
Elon Musk leads Tesla and SpaceX.
"""

relations = extract_relationships(text)

print("Extracted Relationships:")
for rel in relations:
    print(f"  {rel['subject']} --[{rel['relation']}]--> {rel['object']}")

# Output:
# Extracted Relationships:
#   Steve Jobs --[found]--> Apple
#   Tim Cook --[succeed]--> him
#   Microsoft --[acquire]--> LinkedIn
#   Elon Musk --[lead]--> Tesla
```

Pattern-based relationship extraction:

```python
from spacy.matcher import Matcher

nlp = spacy.load("en_core_web_sm")
matcher = Matcher(nlp.vocab)

# Define patterns for relationships
patterns = [
    # "X is CEO of Y"
    [{"POS": "PROPN"}, {"LEMMA": "be"}, {"LOWER": "ceo"}, {"LOWER": "of"}, {"POS": "PROPN"}],
    # "X founded Y"
    [{"POS": "PROPN"}, {"LEMMA": "found"}, {"POS": "PROPN"}],
    # "X acquired Y"
    [{"POS": "PROPN"}, {"LEMMA": "acquire"}, {"POS": "PROPN"}],
]

matcher.add("RELATION", patterns)

text = "Satya Nadella is CEO of Microsoft. Facebook acquired Instagram."
doc = nlp(text)

matches = matcher(doc)
for match_id, start, end in matches:
    span = doc[start:end]
    print(f"Match: {span.text}")
```

### Event Extraction

Identify events and their participants:

```python
import spacy
from datetime import datetime
import re

nlp = spacy.load("en_core_web_sm")

def extract_events(text):
    """Extract events with time, location, and participants."""
    doc = nlp(text)
    
    events = []
    
    # Find sentences with event indicators
    event_verbs = ['meet', 'conference', 'launch', 'release', 'announce', 'hold']
    
    for sent in doc.sents:
        sent_doc = nlp(sent.text)
        
        # Check if sentence contains event verb
        has_event = any(token.lemma_ in event_verbs for token in sent_doc)
        
        if has_event:
            event = {
                'text': sent.text,
                'action': None,
                'participants': [],
                'location': None,
                'time': None
            }
            
            for token in sent_doc:
                # Extract action (verb)
                if token.pos_ == "VERB" and token.lemma_ in event_verbs:
                    event['action'] = token.lemma_
                
                # Extract participants (people, organizations)
                for ent in sent_doc.ents:
                    if ent.label_ in ['PERSON', 'ORG']:
                        event['participants'].append(ent.text)
                    elif ent.label_ == 'GPE':
                        event['location'] = ent.text
                    elif ent.label_ == 'DATE':
                        event['time'] = ent.text
            
            events.append(event)
    
    return events

text = """
Apple will hold a product launch on September 12 in Cupertino.
Tim Cook will announce the new iPhone lineup.
The developer conference starts next week in San Francisco.
"""

events = extract_events(text)

for i, event in enumerate(events, 1):
    print(f"\nEvent {i}:")
    print(f"  Text: {event['text']}")
    print(f"  Action: {event['action']}")
    print(f"  Participants: {event['participants']}")
    print(f"  Location: {event['location']}")
    print(f"  Time: {event['time']}")
```

## Topic Modeling

### Latent Dirichlet Allocation

Discover abstract topics in document collections:

```python
from gensim import corpora
from gensim.models import LdaModel
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
import string

# Sample documents
documents = [
    "Machine learning is a subset of artificial intelligence",
    "Deep learning uses neural networks with multiple layers",
    "Natural language processing helps computers understand text",
    "Computer vision enables machines to interpret images",
    "Reinforcement learning trains agents through rewards",
    "Supervised learning requires labeled training data",
    "Unsupervised learning finds patterns in unlabeled data",
    "Neural networks are inspired by biological neurons"
]

# Preprocess documents
stop_words = set(stopwords.words('english'))

def preprocess(text):
    # Tokenize and clean
    tokens = word_tokenize(text.lower())
    # Remove punctuation and stopwords
    tokens = [t for t in tokens if t not in stop_words and t not in string.punctuation]
    return tokens

processed_docs = [preprocess(doc) for doc in documents]

# Create dictionary and corpus
dictionary = corpora.Dictionary(processed_docs)
print(f"Dictionary size: {len(dictionary)}")

# Convert to bag-of-words
corpus = [dictionary.doc2bow(doc) for doc in processed_docs]

# Train LDA model
num_topics = 3
lda_model = LdaModel(
    corpus=corpus,
    id2word=dictionary,
    num_topics=num_topics,
    random_state=42,
    passes=10,
    alpha='auto',
    per_word_topics=True
)

# Print topics
print("\nDiscovered Topics:")
for idx, topic in lda_model.print_topics(-1):
    print(f"\nTopic {idx}:")
    print(topic)

# Get topic distribution for a document
test_doc = "Neural networks use deep learning algorithms"
test_bow = dictionary.doc2bow(preprocess(test_doc))
topic_dist = lda_model.get_document_topics(test_bow)

print(f"\nTopic distribution for: '{test_doc}'")
for topic_id, prob in topic_dist:
    print(f"  Topic {topic_id}: {prob:.4f}")

# Get most representative documents for each topic
for topic_id in range(num_topics):
    print(f"\nTopic {topic_id} - Representative documents:")
    doc_topics = [(i, lda_model.get_document_topics(corpus[i])) 
                  for i in range(len(documents))]
    
    # Sort by topic probability
    sorted_docs = sorted(doc_topics, 
                        key=lambda x: dict(x[1]).get(topic_id, 0), 
                        reverse=True)
    
    for doc_id, _ in sorted_docs[:2]:
        print(f"  - {documents[doc_id]}")
```

Visualize topics with pyLDAvis:

```python
import pyLDAvis
import pyLDAvis.gensim_models as gensimvis

# Prepare visualization
vis_data = gensimvis.prepare(lda_model, corpus, dictionary)

# Save to HTML
pyLDAvis.save_html(vis_data, 'lda_visualization.html')

# Display in Jupyter notebook
pyLDAvis.display(vis_data)
```

### Non-negative Matrix Factorization

Alternative topic modeling approach:

```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import NMF
import numpy as np
import pandas as pd

documents = [
    "Machine learning algorithms learn from data",
    "Deep learning models use neural networks",
    "Natural language processing analyzes text",
    "Computer vision processes images and video",
    "Data science combines statistics and programming",
    "Python is popular for data analysis",
    "Neural networks have multiple hidden layers",
    "Text mining extracts information from documents"
]

# Create TF-IDF matrix
vectorizer = TfidfVectorizer(
    max_features=100,
    stop_words='english',
    max_df=0.8,
    min_df=1
)

tfidf_matrix = vectorizer.fit_transform(documents)
feature_names = vectorizer.get_feature_names_out()

# Apply NMF
num_topics = 3
nmf_model = NMF(
    n_components=num_topics,
    random_state=42,
    max_iter=500
)

W = nmf_model.fit_transform(tfidf_matrix)  # Document-topic matrix
H = nmf_model.components_  # Topic-term matrix

# Display topics
print("Topics discovered by NMF:")
num_top_words = 5

for topic_idx, topic in enumerate(H):
    top_indices = topic.argsort()[-num_top_words:][::-1]
    top_words = [feature_names[i] for i in top_indices]
    print(f"\nTopic {topic_idx}: {', '.join(top_words)}")

# Get topic distribution for documents
print("\n\nDocument-Topic Distribution:")
df_topics = pd.DataFrame(
    W,
    columns=[f'Topic_{i}' for i in range(num_topics)],
    index=[f'Doc_{i}' for i in range(len(documents))]
)

print(df_topics.round(3))

# Find dominant topic for each document
for doc_idx, doc in enumerate(documents):
    dominant_topic = W[doc_idx].argmax()
    print(f"\nDoc {doc_idx}: {doc}")
    print(f"Dominant topic: Topic_{dominant_topic}")
```

Compare LDA vs NMF:

```python
from sklearn.decomposition import LatentDirichletAllocation
from sklearn.feature_extraction.text import CountVectorizer
import matplotlib.pyplot as plt

# Prepare data
vectorizer = CountVectorizer(max_features=100, stop_words='english')
count_matrix = vectorizer.fit_transform(documents)

# Train both models
lda = LatentDirichletAllocation(n_components=3, random_state=42)
nmf = NMF(n_components=3, random_state=42)

lda_topics = lda.fit_transform(count_matrix)
nmf_topics = nmf.fit_transform(count_matrix)

# Compare coherence
def display_topics(model, feature_names, num_top_words):
    topics = []
    for topic_idx, topic in enumerate(model.components_):
        top_indices = topic.argsort()[-num_top_words:][::-1]
        top_words = [feature_names[i] for i in top_indices]
        topics.append(top_words)
    return topics

feature_names = vectorizer.get_feature_names_out()

print("LDA Topics:")
lda_topic_words = display_topics(lda, feature_names, 5)
for idx, words in enumerate(lda_topic_words):
    print(f"  Topic {idx}: {', '.join(words)}")

print("\nNMF Topics:")
nmf_topic_words = display_topics(nmf, feature_names, 5)
for idx, words in enumerate(nmf_topic_words):
    print(f"  Topic {idx}: {', '.join(words)}")
```

## Language Models

### N-gram Models

Statistical language models based on word sequences:

```python
from nltk import ngrams
from nltk.tokenize import word_tokenize
from collections import Counter, defaultdict
import random

# Sample text corpus
text = """
Natural language processing is a subfield of artificial intelligence.
Machine learning algorithms learn from data and improve over time.
Deep learning models use neural networks with multiple layers.
Natural language understanding is a key component of NLP.
"""

# Tokenize
tokens = word_tokenize(text.lower())

# Generate n-grams
bigrams = list(ngrams(tokens, 2))
trigrams = list(ngrams(tokens, 3))

print("Sample Bigrams:")
for bg in bigrams[:10]:
    print(f"  {bg}")

print("\nSample Trigrams:")
for tg in trigrams[:10]:
    print(f"  {tg}")

# Build n-gram model
class NGramModel:
    def __init__(self, n):
        self.n = n
        self.ngram_freq = Counter()
        self.context_freq = Counter()
        
    def train(self, tokens):
        """Train n-gram model on tokens."""
        for i in range(len(tokens) - self.n + 1):
            ngram = tuple(tokens[i:i + self.n])
            context = ngram[:-1]
            
            self.ngram_freq[ngram] += 1
            self.context_freq[context] += 1
    
    def probability(self, ngram):
        """Calculate probability of n-gram."""
        if len(ngram) != self.n:
            raise ValueError(f"Expected {self.n}-gram")
        
        context = ngram[:-1]
        
        if self.context_freq[context] == 0:
            return 0
        
        return self.ngram_freq[ngram] / self.context_freq[context]
    
    def generate_next(self, context, num_words=5):
        """Generate next words given context."""
        candidates = []
        
        for ngram, count in self.ngram_freq.items():
            if ngram[:-1] == context:
                candidates.append((ngram[-1], count))
        
        if not candidates:
            return None
        
        # Sort by frequency
        candidates.sort(key=lambda x: x[1], reverse=True)
        return [word for word, _ in candidates[:num_words]]

# Train bigram model
bigram_model = NGramModel(2)
bigram_model.train(tokens)

# Calculate probabilities
test_bigrams = [('natural', 'language'), ('machine', 'learning'), ('deep', 'learning')]

print("\nBigram Probabilities:")
for bg in test_bigrams:
    prob = bigram_model.probability(bg)
    print(f"  P({bg[1]}|{bg[0]}) = {prob:.4f}")

# Generate next words
context = ('natural',)
next_words = bigram_model.generate_next(context)
print(f"\nPossible words after '{context[0]}': {next_words}")

# Text generation
def generate_text(model, start_word, length=10):
    """Generate text using n-gram model."""
    result = [start_word]
    
    for _ in range(length - 1):
        context = tuple(result[-(model.n-1):])
        next_words = model.generate_next(context)
        
        if not next_words:
            break
        
        result.append(next_words[0])
    
    return ' '.join(result)

generated = generate_text(bigram_model, 'natural', length=15)
print(f"\nGenerated text: {generated}")
```

Smoothing for better probability estimates:

```python
import math

class SmoothedNGramModel:
    """N-gram model with Laplace smoothing."""
    
    def __init__(self, n, vocabulary_size, smoothing=1.0):
        self.n = n
        self.vocabulary_size = vocabulary_size
        self.smoothing = smoothing  # Laplace smoothing parameter
        self.ngram_freq = Counter()
        self.context_freq = Counter()
    
    def train(self, tokens):
        for i in range(len(tokens) - self.n + 1):
            ngram = tuple(tokens[i:i + self.n])
            context = ngram[:-1]
            self.ngram_freq[ngram] += 1
            self.context_freq[context] += 1
    
    def probability(self, ngram):
        """Calculate smoothed probability."""
        context = ngram[:-1]
        
        numerator = self.ngram_freq[ngram] + self.smoothing
        denominator = self.context_freq[context] + (self.smoothing * self.vocabulary_size)
        
        return numerator / denominator
    
    def perplexity(self, test_tokens):
        """Calculate perplexity on test data."""
        log_prob_sum = 0
        n = 0
        
        for i in range(len(test_tokens) - self.n + 1):
            ngram = tuple(test_tokens[i:i + self.n])
            prob = self.probability(ngram)
            
            if prob > 0:
                log_prob_sum += math.log2(prob)
                n += 1
        
        if n == 0:
            return float('inf')
        
        return 2 ** (-log_prob_sum / n)

# Train with smoothing
vocab_size = len(set(tokens))
smoothed_model = SmoothedNGramModel(2, vocab_size, smoothing=1.0)
smoothed_model.train(tokens)

# Compare probabilities
test_bg = ('natural', 'language')
prob_unsmoothed = bigram_model.probability(test_bg)
prob_smoothed = smoothed_model.probability(test_bg)

print(f"\nUnsmoothed P({test_bg}): {prob_unsmoothed:.4f}")
print(f"Smoothed P({test_bg}): {prob_smoothed:.4f}")
```

### Transformer Models

State-of-the-art neural language models:

```python
from transformers import AutoTokenizer, AutoModel, AutoModelForCausalLM
import torch

# Load pre-trained transformer
model_name = "gpt2"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)

# Generate text
def generate_text(prompt, max_length=50, temperature=0.7):
    """Generate text using transformer model."""
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            temperature=temperature,
            num_return_sequences=1,
            no_repeat_ngram_size=2,
            do_sample=True,
            top_k=50,
            top_p=0.95
        )
    
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return generated_text

prompt = "Natural language processing is"
generated = generate_text(prompt, max_length=50)
print(f"Prompt: {prompt}")
print(f"Generated: {generated}")

# Calculate perplexity
def calculate_perplexity(text):
    """Calculate perplexity of text under model."""
    encodings = tokenizer(text, return_tensors="pt")
    
    max_length = model.config.n_positions
    stride = 512
    
    nlls = []
    for i in range(0, encodings.input_ids.size(1), stride):
        begin_loc = max(i + stride - max_length, 0)
        end_loc = min(i + stride, encodings.input_ids.size(1))
        trg_len = end_loc - i
        
        input_ids = encodings.input_ids[:, begin_loc:end_loc]
        target_ids = input_ids.clone()
        target_ids[:, :-trg_len] = -100
        
        with torch.no_grad():
            outputs = model(input_ids, labels=target_ids)
            neg_log_likelihood = outputs.loss * trg_len
        
        nlls.append(neg_log_likelihood)
    
    ppl = torch.exp(torch.stack(nlls).sum() / end_loc)
    return ppl.item()

test_text = "The quick brown fox jumps over the lazy dog"
perplexity = calculate_perplexity(test_text)
print(f"\nPerplexity of '{test_text}': {perplexity:.2f}")
```

### BERT and Variants

Bidirectional encoder for language understanding:

```python
from transformers import BertTokenizer, BertModel, BertForMaskedLM
import torch
import numpy as np

# Load BERT
model_name = "bert-base-uncased"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertModel.from_pretrained(model_name)

# Get contextualized embeddings
def get_bert_embeddings(text):
    """Get BERT embeddings for text."""
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True)
    
    with torch.no_grad():
        outputs = model(**inputs)
    
    # Use [CLS] token embedding as sentence representation
    cls_embedding = outputs.last_hidden_state[:, 0, :]
    
    # Or use mean pooling
    mean_embedding = outputs.last_hidden_state.mean(dim=1)
    
    return {
        'cls': cls_embedding.numpy(),
        'mean': mean_embedding.numpy(),
        'all_tokens': outputs.last_hidden_state.numpy()
    }

text = "Natural language processing with BERT"
embeddings = get_bert_embeddings(text)

print(f"CLS embedding shape: {embeddings['cls'].shape}")
print(f"Mean embedding shape: {embeddings['mean'].shape}")

# Masked language modeling
masked_lm_model = BertForMaskedLM.from_pretrained(model_name)

def predict_masked_word(text):
    """Predict masked word in text."""
    inputs = tokenizer(text, return_tensors="pt")
    mask_token_index = torch.where(inputs["input_ids"] == tokenizer.mask_token_id)[1]
    
    with torch.no_grad():
        outputs = masked_lm_model(**inputs)
    
    logits = outputs.logits
    mask_token_logits = logits[0, mask_token_index, :]
    
    # Get top predictions
    top_tokens = torch.topk(mask_token_logits, 5, dim=1).indices[0].tolist()
    
    predictions = [tokenizer.decode([token]) for token in top_tokens]
    return predictions

masked_text = "The capital of France is [MASK]."
predictions = predict_masked_word(masked_text)

print(f"\nText: {masked_text}")
print(f"Top predictions: {predictions}")

# Sentence similarity
from sklearn.metrics.pairwise import cosine_similarity

def calculate_similarity(text1, text2):
    """Calculate semantic similarity between texts."""
    emb1 = get_bert_embeddings(text1)['cls']
    emb2 = get_bert_embeddings(text2)['cls']
    
    similarity = cosine_similarity(emb1, emb2)[0][0]
    return similarity

sentences = [
    "The cat sits on the mat",
    "A feline rests on a rug",
    "Dogs are playing in the park"
]

print("\nSentence Similarities:")
for i, sent1 in enumerate(sentences):
    for j, sent2 in enumerate(sentences):
        if i < j:
            sim = calculate_similarity(sent1, sent2)
            print(f"  '{sent1}' <-> '{sent2}': {sim:.4f}")
```

### GPT Models

Generative pre-trained transformers:

```python
from transformers import GPT2LMHeadModel, GPT2Tokenizer, pipeline
import torch

# Load GPT-2
model_name = "gpt2"
tokenizer = GPT2Tokenizer.from_pretrained(model_name)
model = GPT2LMHeadModel.from_pretrained(model_name)

# Text generation with control
def generate_with_control(prompt, max_length=100, temperature=0.8, top_p=0.9):
    """Generate text with generation parameters."""
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            temperature=temperature,  # Higher = more random
            top_p=top_p,  # Nucleus sampling
            do_sample=True,
            num_return_sequences=3  # Generate multiple outputs
        )
    
    generated_texts = [tokenizer.decode(output, skip_special_tokens=True)
                      for output in outputs]
    return generated_texts

prompt = "In the future, artificial intelligence will"
generated_texts = generate_with_control(prompt, max_length=50)

print(f"Prompt: {prompt}\n")
for i, text in enumerate(generated_texts, 1):
    print(f"Generation {i}:")
    print(f"{text}\n")

# Using pipeline for convenience
generator = pipeline('text-generation', model='gpt2')
results = generator(
    "Natural language processing is",
    max_length=50,
    num_return_sequences=2,
    temperature=0.7
)

print("\nPipeline Results:")
for i, result in enumerate(results, 1):
    print(f"{i}. {result['generated_text']}")

# Conditional generation
def generate_continuation(context, next_phrase, max_length=50):
    """Generate text conditioned on context."""
    prompt = f"{context} {next_phrase}"
    inputs = tokenizer(prompt, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            num_beams=5,  # Beam search
            early_stopping=True,
            no_repeat_ngram_size=3
        )
    
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

context = "Machine learning is a field of study that"
continuation = generate_continuation(context, "focuses on")
print(f"\nContext: {context}")
print(f"Continuation: {continuation}")
```

Compare language model performance:

```python
import matplotlib.pyplot as plt
from transformers import pipeline

# Load multiple models
models = {
    'GPT-2 Small': 'gpt2',
    'GPT-2 Medium': 'gpt2-medium',
    'DistilGPT-2': 'distilgpt2'
}

prompt = "Artificial intelligence is\"

print("Comparing Language Models:")

for model_name, model_id in models.items():
    generator = pipeline('text-generation', model=model_id)
    result = generator(prompt, max_length=30, num_return_sequences=1)[0]
    
    print(f"{model_name}:")
    print(f"  {result['generated_text']}")
```

## Sequence-to-Sequence Tasks

### Machine Translation

Translate text between languages:

```python
from transformers import MarianMTModel, MarianTokenizer
import torch

class Translator:
    """Machine translation using MarianMT models."""
    
    def __init__(self, source_lang, target_lang):
        model_name = f'Helsinki-NLP/opus-mt-{source_lang}-{target_lang}'
        self.tokenizer = MarianTokenizer.from_pretrained(model_name)
        self.model = MarianMTModel.from_pretrained(model_name)
    
    def translate(self, texts, max_length=512):
        """Translate texts from source to target language."""
        if isinstance(texts, str):
            texts = [texts]
        
        # Tokenize
        inputs = self.tokenizer(texts, return_tensors="pt", padding=True, truncation=True)
        
        # Generate translations
        with torch.no_grad():
            translated = self.model.generate(**inputs, max_length=max_length)
        
        # Decode
        translations = [self.tokenizer.decode(t, skip_special_tokens=True) 
                       for t in translated]
        
        return translations if len(translations) > 1 else translations[0]

# English to French
en_fr_translator = Translator('en', 'fr')

english_texts = [
    "Hello, how are you?",
    "Natural language processing is fascinating.",
    "Machine learning models can translate text."
]

french_translations = en_fr_translator.translate(english_texts)

for en, fr in zip(english_texts, french_translations):
    print(f"EN: {en}")
    print(f"FR: {fr}\n")

# English to German
en_de_translator = Translator('en', 'de')
german = en_de_translator.translate("Machine learning is powerful.")
print(f"EN: Machine learning is powerful.")
print(f"DE: {german}")

# Back translation for data augmentation
fr_en_translator = Translator('fr', 'en')
back_translated = fr_en_translator.translate(french_translations)

print("\nBack Translation:")
for original, back in zip(english_texts, back_translated):
    print(f"Original:  {original}")
    print(f"Back:      {back}\n")
```

Using the translation pipeline:

```python
from transformers import pipeline

# Create translation pipeline
translator = pipeline("translation", model="Helsinki-NLP/opus-mt-en-es")

# Translate
results = translator([
    "Hello, world!",
    "How are you today?",
    "Machine learning is amazing."
], max_length=100)

for result in results:
    print(result['translation_text'])

# Output:
# ¡Hola mundo!
# ¿Cómo estás hoy?
# El aprendizaje automático es increíble.
```

### Text Summarization

Generate concise summaries of long texts:

```python
from transformers import pipeline

# Extractive summarization (selects important sentences)
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lsa import LsaSummarizer
from sumy.summarizers.luhn import LuhnSummarizer

def extractive_summarization(text, sentence_count=3):
    """Extract key sentences from text."""
    parser = PlaintextParser.from_string(text, Tokenizer("english"))
    summarizer = LsaSummarizer()
    summary = summarizer(parser.document, sentence_count)
    
    return ' '.join([str(sentence) for sentence in summary])

long_text = """
Artificial intelligence (AI) is intelligence demonstrated by machines, 
in contrast to natural intelligence displayed by animals including humans. 
AI research has been defined as the field of study of intelligent agents, 
which refers to any system that perceives its environment and takes actions 
that maximize its chance of achieving its goals. The term "artificial intelligence" 
was coined by John McCarthy in 1956. AI applications include advanced web search 
engines, recommendation systems, understanding human speech, self-driving cars, 
automated decision-making, and competing at the highest level in strategic game 
systems. As machines become increasingly capable, tasks considered to require 
intelligence are often removed from the definition of AI, a phenomenon known as 
the AI effect. Deep learning has dramatically improved the performance of programs 
in many important subfields of artificial intelligence.
"""

extract_summary = extractive_summarization(long_text, sentence_count=2)
print("Extractive Summary:")
print(extract_summary)

# Abstractive summarization (generates new text)
summarizer = pipeline("summarization", model="facebook/bart-large-cnn")

def abstractive_summarization(text, max_length=130, min_length=30):
    """Generate abstractive summary."""
    summary = summarizer(text, max_length=max_length, min_length=min_length, do_sample=False)
    return summary[0]['summary_text']

abstract_summary = abstractive_summarization(long_text)
print("\nAbstractive Summary:")
print(abstract_summary)

# Summarize articles
article = """
Machine learning is a method of data analysis that automates analytical model building. 
It is a branch of artificial intelligence based on the idea that systems can learn from data, 
identify patterns and make decisions with minimal human intervention. Machine learning algorithms 
are used in a wide variety of applications, such as in medicine, email filtering, speech recognition, 
and computer vision, where it is difficult or unfeasible to develop conventional algorithms to perform 
the needed tasks. The learning process begins with observations or data, such as examples, direct 
experience, or instruction, in order to look for patterns in data and make better decisions in the 
future based on the examples that we provide.
"""

summary_result = summarizer(
    article,
    max_length=50,
    min_length=25,
    do_sample=False
)

print("\nArticle Summary:")
print(summary_result[0]['summary_text'])
```

Custom summarization with T5:

```python
from transformers import T5Tokenizer, T5ForConditionalGeneration

model_name = "t5-small"
tokenizer = T5Tokenizer.from_pretrained(model_name)
model = T5ForConditionalGeneration.from_pretrained(model_name)

def t5_summarize(text, max_length=150):
    """Summarize using T5 model."""
    # T5 requires task prefix
    input_text = f"summarize: {text}"
    inputs = tokenizer(input_text, return_tensors="pt", max_length=512, truncation=True)
    
    with torch.no_grad():
        summary_ids = model.generate(
            inputs['input_ids'],
            max_length=max_length,
            num_beams=4,
            length_penalty=2.0,
            early_stopping=True
        )
    
    summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)
    return summary

t5_summary = t5_summarize(long_text)
print("\nT5 Summary:")
print(t5_summary)
```

### Question Answering

Build systems that answer questions from context:

```python
from transformers import pipeline

# Load QA pipeline
qa_pipeline = pipeline(
    "question-answering",
    model="distilbert-base-cased-distilled-squad"
)

context = """
The Transformer is a deep learning model introduced in 2017, used primarily in 
the field of natural language processing. Like recurrent neural networks, 
transformers are designed to handle sequential data, such as natural language, 
for tasks such as translation and text summarization. However, unlike RNNs, 
transformers do not require that the sequential data be processed in order. 
The Transformer was proposed in the paper "Attention Is All You Need" by 
Vaswani et al. from Google Brain.
"""

questions = [
    "When was the Transformer model introduced?",
    "What is the Transformer used for?",
    "Who proposed the Transformer?",
    "What is the main difference from RNNs?"
]

print("Question Answering:")
for question in questions:
    result = qa_pipeline(question=question, context=context)
    print(f"\nQ: {question}")
    print(f"A: {result['answer']}")
    print(f"   Confidence: {result['score']:.4f}")

# Output:
# Q: When was the Transformer model introduced?
# A: 2017
#    Confidence: 0.9842
#
# Q: What is the Transformer used for?
# A: natural language processing
#    Confidence: 0.5321
```

Multiple-choice QA:

```python
from transformers import AutoTokenizer, AutoModelForMultipleChoice
import torch

def answer_multiple_choice(question, context, choices):
    """Answer multiple choice question."""
    model_name = "bert-base-uncased"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForMultipleChoice.from_pretrained(model_name)
    
    # Format inputs
    inputs = []
    for choice in choices:
        prompt = f"{question} {choice}"
        inputs.append(tokenizer(prompt, context, return_tensors="pt", 
                               padding=True, truncation=True))
    
    # Get predictions
    with torch.no_grad():
        outputs = [model(**inp).logits for inp in inputs]
        scores = torch.cat(outputs, dim=0)
        predicted_idx = scores.argmax().item()
    
    return choices[predicted_idx], predicted_idx

question = "What is the capital of France?"
context = "France is a country in Europe. Paris is its capital and largest city."
choices = ["London", "Paris", "Berlin", "Madrid"]

answer, idx = answer_multiple_choice(question, context, choices)
print(f"Question: {question}")
print(f"Answer: {answer}")
```

Open-domain QA (no context provided):

```python
from transformers import pipeline

# Using RAG (Retrieval-Augmented Generation)
qa_system = pipeline("question-answering", 
                     model="deepset/roberta-base-squad2")

# Questions without specific context
questions = [
    "What is Python?",
    "Who invented the transformer architecture?",
    "When was BERT released?"
]

# Note: For true open-domain QA, you'd need a retrieval system
# to fetch relevant context first
general_context = """
Python is a high-level programming language. BERT was released by Google in 2018.
The Transformer architecture was invented by researchers at Google in 2017.
"""

for question in questions:
    result = qa_system(question=question, context=general_context)
    print(f"\nQ: {question}")
    print(f"A: {result['answer']}")
```

## Advanced Topics

### Transfer Learning

Leverage pre-trained models for new tasks:

```python
from transformers import BertTokenizer, BertForSequenceClassification
from transformers import Trainer, TrainingArguments
import torch
from torch.utils.data import Dataset
import pandas as pd

class TextClassificationDataset(Dataset):
    """Custom dataset for text classification."""
    
    def __init__(self, texts, labels, tokenizer, max_length=128):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length
    
    def __len__(self):
        return len(self.texts)
    
    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        
        encoding = self.tokenizer(
            text,
            max_length=self.max_length,
            padding='max_length',
            truncation=True,
            return_tensors='pt'
        )
        
        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'labels': torch.tensor(label, dtype=torch.long)
        }

# Sample data
texts = [
    "This product is amazing!",
    "Terrible experience, very disappointed.",
    "Good quality for the price.",
    "Waste of money, do not buy."
]
labels = [1, 0, 1, 0]  # 1=positive, 0=negative

# Load pre-trained model
model_name = "bert-base-uncased"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertForSequenceClassification.from_pretrained(
    model_name,
    num_labels=2  # Binary classification
)

# Create dataset
dataset = TextClassificationDataset(texts, labels, tokenizer)

# Training arguments
training_args = TrainingArguments(
    output_dir='./results',
    num_train_epochs=3,
    per_device_train_batch_size=8,
    warmup_steps=100,
    weight_decay=0.01,
    logging_dir='./logs',
)

# Create trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset
)

# Train (fine-tune)
trainer.train()

# Predict
test_text = "This is fantastic!"
inputs = tokenizer(test_text, return_tensors="pt", padding=True, truncation=True)

with torch.no_grad():
    outputs = model(**inputs)
    prediction = torch.argmax(outputs.logits, dim=1).item()

print(f"Text: {test_text}")
print(f"Prediction: {'Positive' if prediction == 1 else 'Negative'}")
```

### Fine-tuning Pre-trained Models

Adapt models to specific domains:

```python
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer
)
from datasets import load_dataset
import numpy as np
from sklearn.metrics import accuracy_score, f1_score

# Load dataset
dataset = load_dataset("imdb")

# Load model and tokenizer
model_name = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(
    model_name,
    num_labels=2
)

# Tokenize dataset
def tokenize_function(examples):
    return tokenizer(
        examples['text'],
        padding='max_length',
        truncation=True,
        max_length=512
    )

tokenized_datasets = dataset.map(tokenize_function, batched=True)

# Prepare train and validation sets
train_dataset = tokenized_datasets['train'].shuffle(seed=42).select(range(1000))
eval_dataset = tokenized_datasets['test'].shuffle(seed=42).select(range(500))

# Define metrics
def compute_metrics(eval_pred):
    predictions, labels = eval_pred
    predictions = np.argmax(predictions, axis=1)
    
    return {
        'accuracy': accuracy_score(labels, predictions),
        'f1': f1_score(labels, predictions, average='weighted')
    }

# Training arguments
training_args = TrainingArguments(
    output_dir='./results',
    evaluation_strategy='epoch',
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=3,
    weight_decay=0.01,
    save_strategy='epoch',
    load_best_model_at_end=True,
)

# Initialize trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    compute_metrics=compute_metrics,
)

# Fine-tune
trainer.train()

# Evaluate
eval_results = trainer.evaluate()
print(f"Evaluation Results: {eval_results}")

# Save model
model.save_pretrained('./fine_tuned_model')
tokenizer.save_pretrained('./fine_tuned_model')
```

### Multi-lingual NLP

Work with multiple languages:

```python
from transformers import pipeline, AutoTokenizer, AutoModel
import torch

# Multilingual BERT
model_name = "bert-base-multilingual-cased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModel.from_pretrained(model_name)

# Process multiple languages
texts = {
    'English': "Hello, how are you?",
    'Spanish': "Hola, ¿cómo estás?",
    'French': "Bonjour, comment allez-vous?",
    'German': "Hallo, wie geht es dir?",
    'Chinese': "你好，你好吗？"
}

print("Multilingual Embeddings:")
for lang, text in texts.items():
    inputs = tokenizer(text, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs)
    embedding = outputs.last_hidden_state.mean(dim=1)
    print(f"{lang:10} -> Embedding shape: {embedding.shape}")

# Cross-lingual NER
ner_pipeline = pipeline(
    "ner",
    model="xlm-roberta-large-finetuned-conll03-english",
    aggregation_strategy="simple"
)

multilingual_texts = [
    "Apple Inc. was founded by Steve Jobs in California.",
    "Apple Inc. fue fundada por Steve Jobs en California.",
    "Apple Inc. a été fondée par Steve Jobs en Californie."
]

for text in multilingual_texts:
    entities = ner_pipeline(text)
    print(f"\nText: {text}")
    for ent in entities:
        print(f"  {ent['word']} -> {ent['entity_group']} ({ent['score']:.4f})")
```

### Low-Resource Languages

Techniques for languages with limited data:

```python
from transformers import MarianMTModel, MarianTokenizer

# Back-translation for data augmentation
def back_translate(text, src_lang='en', pivot_lang='fr'):
    """Augment data using back-translation."""
    # Translate to pivot language
    forward_model = f'Helsinki-NLP/opus-mt-{src_lang}-{pivot_lang}'
    fwd_tokenizer = MarianTokenizer.from_pretrained(forward_model)
    fwd_model = MarianMTModel.from_pretrained(forward_model)
    
    inputs = fwd_tokenizer(text, return_tensors="pt", padding=True)
    with torch.no_grad():
        translated = fwd_model.generate(**inputs)
    pivot_text = fwd_tokenizer.decode(translated[0], skip_special_tokens=True)
    
    # Translate back to source
    back_model = f'Helsinki-NLP/opus-mt-{pivot_lang}-{src_lang}'
    back_tokenizer = MarianTokenizer.from_pretrained(back_model)
    back_model = MarianMTModel.from_pretrained(back_model)
    
    inputs = back_tokenizer(pivot_text, return_tensors="pt", padding=True)
    with torch.no_grad():
        back_translated = back_model.generate(**inputs)
    final_text = back_tokenizer.decode(back_translated[0], skip_special_tokens=True)
    
    return final_text, pivot_text

original = "Machine learning is fascinating"
back_translated, pivot = back_translate(original)

print(f"Original:        {original}")
print(f"Pivot (French):  {pivot}")
print(f"Back-translated: {back_translated}")

# Cross-lingual transfer
print("\nCross-lingual transfer example:")
print("Train on high-resource language (English)")
print("Test on low-resource language using multilingual model")
```

## Working with Libraries

### spaCy

Industrial-strength NLP library:

```python
import spacy
from spacy.matcher import Matcher, PhraseMatcher
from spacy.tokens import Span

# Load model
nlp = spacy.load("en_core_web_sm")

# Custom pipeline components
@spacy.Language.component("custom_component")
def custom_component(doc):
    """Add custom attributes to tokens."""
    for token in doc:
        # Add custom attribute
        token._.set("is_tech_term", 
                   token.text.lower() in ['ai', 'ml', 'nlp', 'python'])
    return doc

# Register custom attribute
if not spacy.tokens.Token.has_extension("is_tech_term"):
    spacy.tokens.Token.set_extension("is_tech_term", default=False)

# Add component to pipeline
nlp.add_pipe("custom_component", last=True)

text = "AI and ML are transforming NLP with Python."
doc = nlp(text)

print("Tech terms:")
for token in doc:
    if token._.is_tech_term:
        print(f"  {token.text}")

# Pattern matching
matcher = Matcher(nlp.vocab)

# Define patterns
patterns = [
    [{"LOWER": "machine"}, {"LOWER": "learning"}],
    [{"LOWER": "natural"}, {"LOWER": "language"}, {"LOWER": "processing"}],
    [{"LOWER": "deep"}, {"LOWER": "learning"}]
]

matcher.add("TECH_TERMS", patterns)

text = "Machine learning and natural language processing are deep learning applications."
doc = nlp(text)

matches = matcher(doc)
print("\nMatched phrases:")
for match_id, start, end in matches:
    span = doc[start:end]
    print(f"  {span.text}")

# Phrase matching
phrase_matcher = PhraseMatcher(nlp.vocab, attr="LOWER")
terms = ["artificial intelligence", "neural network", "transformer model"]
patterns = [nlp.make_doc(text) for text in terms]
phrase_matcher.add("AI_TERMS", patterns)

text = "The Transformer model uses neural networks for artificial intelligence tasks."
doc = nlp(text)

matches = phrase_matcher(doc)
print("\nPhrase matches:")
for match_id, start, end in matches:
    print(f"  {doc[start:end].text}")

# Custom entity recognition
from spacy.training import Example

def create_training_data():
    """Create training examples."""
    TRAIN_DATA = [
        ("iPhone 15 is Apple's latest phone", {
            "entities": [(0, 9, "PRODUCT"), (13, 18, "ORG")]
        }),
        ("Samsung Galaxy is popular", {
            "entities": [(0, 14, "PRODUCT")]
        })
    ]
    return TRAIN_DATA

# Document similarity
def calculate_doc_similarity(text1, text2):
    """Calculate similarity between documents."""
    doc1 = nlp(text1)
    doc2 = nlp(text2)
    return doc1.similarity(doc2)

doc1_text = "Machine learning is a subset of AI"
doc2_text = "Artificial intelligence includes machine learning"
doc3_text = "I like pizza and pasta"

print(f"\nSimilarity between docs 1 and 2: {calculate_doc_similarity(doc1_text, doc2_text):.4f}")
print(f"Similarity between docs 1 and 3: {calculate_doc_similarity(doc1_text, doc3_text):.4f}")

# Rule-based matching
from spacy.matcher import DependencyMatcher

dep_matcher = DependencyMatcher(nlp.vocab)

# Match "X owns Y" patterns
pattern = [
    {
        "RIGHT_ID": "verb",
        "RIGHT_ATTRS": {"LEMMA": "own"}
    },
    {
        "LEFT_ID": "verb",
        "REL_OP": ">",
        "RIGHT_ID": "subject",
        "RIGHT_ATTRS": {"DEP": "nsubj"}
    },
    {
        "LEFT_ID": "verb",
        "REL_OP": ">",
        "RIGHT_ID": "object",
        "RIGHT_ATTRS": {"DEP": "dobj"}
    }
]

dep_matcher.add("OWNS", [pattern])

text = "Microsoft owns GitHub. Google owns YouTube."
doc = nlp(text)
matches = dep_matcher(doc)

print("\nOwnership relationships:")
for match_id, token_ids in matches:
    for token_id in token_ids:
        print(f"  {doc[token_id].text}", end=" ")
    print()
```

### Transformers

Hugging Face Transformers library:

```python
from transformers import (
    AutoTokenizer,
    AutoModel,
    AutoModelForSequenceClassification,
    pipeline
)
import torch

# Model hub exploration
from huggingface_hub import list_models

# Find models for specific task
models = list_models(filter="fill-mask", limit=5)
print("Fill-mask models:")
for model in models:
    print(f"  {model.modelId}")

# Zero-shot classification
zero_shot_classifier = pipeline(
    "zero-shot-classification",
    model="facebook/bart-large-mnli"
)

text = "This is a tutorial about natural language processing."
candidate_labels = ["education", "politics", "sports", "technology"]

result = zero_shot_classifier(text, candidate_labels)

print("\nZero-shot classification:")
for label, score in zip(result['labels'], result['scores']):
    print(f"  {label:12} {score:.4f}")

# Feature extraction
feature_extractor = pipeline(
    "feature-extraction",
    model="bert-base-uncased"
)

text = "Extract features from this text"
features = feature_extractor(text)
feature_tensor = torch.tensor(features)

print(f"\nFeature shape: {feature_tensor.shape}")

# Text generation with control
generator = pipeline(
    "text-generation",
    model="gpt2"
)

generated = generator(
    "The future of AI is",
    max_length=50,
    num_return_sequences=2,
    temperature=0.7,
    top_k=50,
    top_p=0.95,
    do_sample=True
)

print("\nGenerated texts:")
for i, gen in enumerate(generated, 1):
    print(f"{i}. {gen['generated_text']}\n")

# Custom model loading
class CustomClassifier:
    """Custom classifier using transformers."""
    
    def __init__(self, model_name, num_labels=2):
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)
        self.model = AutoModelForSequenceClassification.from_pretrained(
            model_name,
            num_labels=num_labels
        )
        self.model.eval()
    
    def predict(self, texts, batch_size=8):
        """Predict labels for texts."""
        if isinstance(texts, str):
            texts = [texts]
        
        predictions = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            inputs = self.tokenizer(
                batch,
                return_tensors="pt",
                padding=True,
                truncation=True
            )
            
            with torch.no_grad():
                outputs = self.model(**inputs)
                batch_predictions = torch.argmax(outputs.logits, dim=1)
                predictions.extend(batch_predictions.tolist())
        
        return predictions

classifier = CustomClassifier("distilbert-base-uncased")
texts = ["This is great!", "This is terrible."]
predictions = classifier.predict(texts)
print(f"\nPredictions: {predictions}")
```

### NLTK

Natural Language Toolkit fundamentals:

```python
import nltk
from nltk.corpus import brown, wordnet, stopwords
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk import pos_tag, ne_chunk
from nltk.stem import WordNetLemmatizer
from nltk.probability import FreqDist
from nltk.collocations import BigramCollocationFinder, BigramAssocMeasures

# Download required resources
resources = [
    'brown', 'wordnet', 'averaged_perceptron_tagger',
    'maxent_ne_chunker', 'words', 'stopwords'
]

for resource in resources:
    try:
        nltk.download(resource, quiet=True)
    except:
        pass

# Corpus statistics
print("Brown Corpus Statistics:")
print(f"  Categories: {len(brown.categories())}")
print(f"  Words: {len(brown.words())}")
print(f"  Sentences: {len(brown.sents())}")

# Frequency analysis
words = [w.lower() for w in brown.words() if w.isalpha()]
fdist = FreqDist(words)

print("\nMost common words:")
for word, freq in fdist.most_common(10):
    print(f"  {word:12} {freq}")

# Collocation detection
text = " ".join(brown.words()[:10000])
tokens = word_tokenize(text.lower())

bigram_finder = BigramCollocationFinder.from_words(tokens)
bigram_measures = BigramAssocMeasures()

# Remove stopwords
stop_words = set(stopwords.words('english'))
bigram_finder.apply_word_filter(lambda w: w in stop_words or len(w) < 3)

print("\nTop collocations:")
for bigram, score in bigram_finder.score_ngrams(bigram_measures.pmi)[:10]:
    print(f"  {bigram[0]:12} {bigram[1]:12} {score:.4f}")

# WordNet usage
lemmatizer = WordNetLemmatizer()

def get_wordnet_info(word):
    """Get WordNet information for word."""
    synsets = wordnet.synsets(word)
    
    if not synsets:
        return None
    
    info = {
        'word': word,
        'synsets': [],
        'synonyms': set(),
        'antonyms': set()
    }
    
    for synset in synsets:
        info['synsets'].append({
            'name': synset.name(),
            'definition': synset.definition(),
            'examples': synset.examples()
        })
        
        # Get synonyms and antonyms
        for lemma in synset.lemmas():
            info['synonyms'].add(lemma.name())
            if lemma.antonyms():
                for ant in lemma.antonyms():
                    info['antonyms'].add(ant.name())
    
    return info

word_info = get_wordnet_info('good')
if word_info:
    print(f"\nWordNet info for '{word_info['word']}':")
    print(f"  Synonyms: {list(word_info['synonyms'])[:5]}")
    print(f"  Antonyms: {list(word_info['antonyms'])[:5]}")
    print(f"  Definitions:")
    for syn in word_info['synsets'][:3]:
        print(f"    - {syn['definition']}")

# Semantic similarity
def word_similarity(word1, word2):
    """Calculate similarity between words using WordNet."""
    synsets1 = wordnet.synsets(word1)
    synsets2 = wordnet.synsets(word2)
    
    if not synsets1 or not synsets2:
        return 0.0
    
    # Compare first synsets
    return synsets1[0].path_similarity(synsets2[0]) or 0.0

print("\nWord similarities:")
word_pairs = [('dog', 'cat'), ('dog', 'computer'), ('car', 'automobile')]
for w1, w2 in word_pairs:
    sim = word_similarity(w1, w2)
    print(f"  {w1:10} <-> {w2:10} : {sim:.4f}")

# Parse tree visualization
from nltk.tree import Tree

sentence = "The quick brown fox jumps"
tokens = word_tokenize(sentence)
tagged = pos_tag(tokens)
named_entities = ne_chunk(tagged)

print("\nNamed Entity Tree:")
print(named_entities)
```

## Performance Optimization

Optimize NLP pipelines for speed and efficiency:

```python
import time
import multiprocessing as mp
from functools import partial
import torch

# Batch processing
def process_texts_batch(texts, model, tokenizer, batch_size=32):
    """Process texts in batches for better performance."""
    results = []
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True)
        
        with torch.no_grad():
            outputs = model(**inputs)
        
        results.extend(outputs.logits.argmax(dim=1).tolist())
    
    return results

# Parallel processing with spaCy
import spacy

nlp = spacy.load("en_core_web_sm")

def process_parallel(texts, n_process=4):
    """Process texts in parallel."""
    results = []
    
    for doc in nlp.pipe(texts, n_process=n_process, batch_size=50):
        results.append({
            'text': doc.text,
            'entities': [(ent.text, ent.label_) for ent in doc.ents],
            'tokens': len(doc)
        })
    
    return results

# Test parallel processing
texts = [f"This is test document number {i}" for i in range(1000)]

# Serial processing
start = time.time()
for text in texts:
    doc = nlp(text)
serial_time = time.time() - start

# Parallel processing
start = time.time()
results = process_parallel(texts, n_process=4)
parallel_time = time.time() - start

print(f"Serial processing: {serial_time:.2f}s")
print(f"Parallel processing: {parallel_time:.2f}s")
print(f"Speedup: {serial_time/parallel_time:.2f}x")

# Model quantization
from transformers import AutoModelForSequenceClassification, AutoTokenizer

# Load model
model_name = "distilbert-base-uncased"
model = AutoModelForSequenceClassification.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Dynamic quantization (reduce model size)
quantized_model = torch.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8
)

print(f"\nOriginal model size: {sum(p.numel() for p in model.parameters()) / 1e6:.2f}M parameters")
print(f"Quantized model size: {sum(p.numel() for p in quantized_model.parameters()) / 1e6:.2f}M parameters")

# Caching for repeated operations
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_tokenize(text):
    """Cache tokenization results."""
    return tokenizer(text, return_tensors="pt")

# GPU acceleration
if torch.cuda.is_available():
    device = torch.device("cuda")
    model = model.to(device)
    print(f"\nUsing GPU: {torch.cuda.get_device_name(0)}")
else:
    device = torch.device("cpu")
    print("\nUsing CPU")

# Efficient memory management
def process_large_dataset(texts, batch_size=32):
    """Process large datasets efficiently."""
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        inputs = tokenizer(batch, return_tensors="pt", padding=True, truncation=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = model(**inputs)
        
        # Process batch and clear memory
        predictions = outputs.logits.argmax(dim=1).cpu().numpy()
        
        # Explicitly delete to free memory
        del inputs, outputs
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
        
        yield predictions

# Model pruning
from torch.nn.utils import prune

def prune_model(model, amount=0.3):
    """Prune model weights."""
    for name, module in model.named_modules():
        if isinstance(module, torch.nn.Linear):
            prune.l1_unstructured(module, name='weight', amount=amount)
    return model

# Vocabulary optimization
def optimize_vocabulary(tokenizer, texts, top_k=10000):
    """Reduce vocabulary size based on frequency."""
    from collections import Counter
    
    # Count token frequencies
    token_freq = Counter()
    for text in texts:
        tokens = tokenizer.tokenize(text)
        token_freq.update(tokens)
    
    # Keep most frequent tokens
    top_tokens = [token for token, _ in token_freq.most_common(top_k)]
    
    return top_tokens
```

## Best Practices

Guidelines for production NLP systems:

```python
import logging
from typing import List, Dict, Optional
from dataclasses import dataclass
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Type annotations and data classes
@dataclass
class ProcessedDocument:
    """Structured document representation."""
    text: str
    tokens: List[str]
    entities: List[Dict[str, str]]
    sentiment: Optional[str] = None
    metadata: Dict = None

class NLPPipeline:
    """Production-ready NLP pipeline."""
    
    def __init__(self, model_name: str):
        """Initialize pipeline with model."""
        self.model_name = model_name
        self.model = None
        self.tokenizer = None
        self._load_model()
    
    def _load_model(self) -> None:
        """Load model with error handling."""
        try:
            from transformers import AutoModelForSequenceClassification, AutoTokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForSequenceClassification.from_pretrained(self.model_name)
            logger.info(f"Successfully loaded model: {self.model_name}")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise
    
    def process(self, text: str) -> ProcessedDocument:
        """Process single document."""
        if not text or not isinstance(text, str):
            raise ValueError("Input must be non-empty string")
        
        try:
            # Tokenize
            tokens = self.tokenizer.tokenize(text)
            
            # Process
            result = ProcessedDocument(
                text=text,
                tokens=tokens,
                entities=[],
                metadata={'processed_by': self.model_name}
            )
            
            logger.debug(f"Processed document with {len(tokens)} tokens")
            return result
            
        except Exception as e:
            logger.error(f"Error processing document: {e}")
            raise
    
    def process_batch(self, texts: List[str], batch_size: int = 32) -> List[ProcessedDocument]:
        """Process multiple documents efficiently."""
        results = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            try:
                batch_results = [self.process(text) for text in batch]
                results.extend(batch_results)
            except Exception as e:
                logger.error(f"Error processing batch {i//batch_size}: {e}")
                continue
        
        return results

# Input validation
def validate_text_input(text: str, max_length: int = 512) -> bool:
    """Validate text input."""
    if not text or not isinstance(text, str):
        return False
    
    if len(text) > max_length:
        logger.warning(f"Text exceeds max length: {len(text)} > {max_length}")
        return False
    
    return True

# Error handling
class NLPError(Exception):
    """Base exception for NLP errors."""
    pass

class TokenizationError(NLPError):
    """Error during tokenization."""
    pass

class ModelError(NLPError):
    """Error related to model operations."""
    pass

def safe_process(text: str, processor) -> Optional[Dict]:
    """Process text with error handling."""
    try:
        return processor(text)
    except TokenizationError as e:
        logger.error(f"Tokenization failed: {e}")
        return None
    except ModelError as e:
        logger.error(f"Model error: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return None

# Configuration management
class Config:
    """Configuration management."""
    
    def __init__(self, config_path: str):
        self.config = self._load_config(config_path)
    
    def _load_config(self, path: str) -> Dict:
        """Load configuration from file."""
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning(f"Config file not found: {path}. Using defaults.")
            return self._default_config()
    
    def _default_config(self) -> Dict:
        """Default configuration."""
        return {
            'model_name': 'bert-base-uncased',
            'max_length': 512,
            'batch_size': 32,
            'device': 'cpu'
        }
    
    def get(self, key: str, default=None):
        """Get configuration value."""
        return self.config.get(key, default)

# Testing
import unittest

class TestNLPPipeline(unittest.TestCase):
    """Test NLP pipeline."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.pipeline = NLPPipeline('distilbert-base-uncased')
    
    def test_process_valid_text(self):
        """Test processing valid text."""
        text = "This is a test."
        result = self.pipeline.process(text)
        self.assertIsInstance(result, ProcessedDocument)
        self.assertEqual(result.text, text)
    
    def test_process_empty_text(self):
        """Test processing empty text."""
        with self.assertRaises(ValueError):
            self.pipeline.process("")
    
    def test_batch_processing(self):
        """Test batch processing."""
        texts = ["Text 1", "Text 2", "Text 3"]
        results = self.pipeline.process_batch(texts)
        self.assertEqual(len(results), len(texts))

# Documentation
def process_document(text: str, 
                    options: Dict[str, any] = None) -> ProcessedDocument:
    """
    Process a text document through NLP pipeline.
    
    Args:
        text (str): Input text to process
        options (Dict[str, any], optional): Processing options
            - max_length (int): Maximum text length
            - include_entities (bool): Extract named entities
            - include_sentiment (bool): Analyze sentiment
    
    Returns:
        ProcessedDocument: Processed document with annotations
    
    Raises:
        ValueError: If text is empty or invalid
        ModelError: If model processing fails
    
    Examples:
        >>> doc = process_document("Hello world")
        >>> print(doc.tokens)
        ['hello', 'world']
    """
    pass
```

## Real-World Applications

Practical NLP applications:

```python
# Customer Support Chatbot
from transformers import pipeline

class SupportChatbot:
    """Customer support chatbot."""
    
    def __init__(self):
        self.intent_classifier = pipeline(
            "zero-shot-classification",
            model="facebook/bart-large-mnli"
        )
        self.qa_system = pipeline(
            "question-answering",
            model="deepset/roberta-base-squad2"
        )
        
        self.intents = [
            "technical_support",
            "billing_inquiry",
            "product_information",
            "complaint",
            "general_inquiry"
        ]
    
    def classify_intent(self, message: str) -> str:
        """Classify user intent."""
        result = self.intent_classifier(message, self.intents)
        return result['labels'][0]
    
    def answer_question(self, question: str, context: str) -> str:
        """Answer question from knowledge base."""
        result = self.qa_system(question=question, context=context)
        return result['answer']
    
    def respond(self, message: str) -> Dict[str, str]:
        """Generate response to user message."""
        intent = self.classify_intent(message)
        
        # Route to appropriate handler
        if intent == "technical_support":
            response = "I'll connect you with our technical team."
        elif intent == "billing_inquiry":
            response = "Let me help you with billing information."
        else:
            response = "How can I assist you today?"
        
        return {
            'intent': intent,
            'response': response
        }

# Content Recommendation System
class ContentRecommender:
    """Recommend similar content based on text."""
    
    def __init__(self):
        from transformers import AutoTokenizer, AutoModel
        import torch
        
        self.tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
        self.model = AutoModel.from_pretrained("bert-base-uncased")
        self.content_embeddings = {}
    
    def add_content(self, content_id: str, text: str):
        """Add content to recommendation system."""
        embedding = self._get_embedding(text)
        self.content_embeddings[content_id] = embedding
    
    def _get_embedding(self, text: str):
        """Get BERT embedding for text."""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True)
        with torch.no_grad():
            outputs = self.model(**inputs)
        return outputs.last_hidden_state.mean(dim=1).numpy()
    
    def recommend(self, query: str, top_k: int = 5) -> List[str]:
        """Recommend similar content."""
        from sklearn.metrics.pairwise import cosine_similarity
        
        query_embedding = self._get_embedding(query)
        
        similarities = {}
        for content_id, embedding in self.content_embeddings.items():
            sim = cosine_similarity(query_embedding, embedding)[0][0]
            similarities[content_id] = sim
        
        # Sort by similarity
        sorted_content = sorted(similarities.items(), key=lambda x: x[1], reverse=True)
        return [content_id for content_id, _ in sorted_content[:top_k]]

# Email Classification
class EmailClassifier:
    """Classify and prioritize emails."""
    
    def __init__(self):
        from transformers import pipeline
        
        self.classifier = pipeline(
            "text-classification",
            model="distilbert-base-uncased"
        )
        self.sentiment_analyzer = pipeline(
            "sentiment-analysis",
            model="distilbert-base-uncased-finetuned-sst-2-english"
        )
    
    def classify_email(self, subject: str, body: str) -> Dict:
        """Classify email content."""
        full_text = f"{subject} {body}"
        
        # Determine urgency
        urgent_keywords = ['urgent', 'immediate', 'asap', 'critical']
        is_urgent = any(keyword in full_text.lower() for keyword in urgent_keywords)
        
        # Analyze sentiment
        sentiment = self.sentiment_analyzer(body[:512])[0]
        
        return {
            'urgent': is_urgent,
            'sentiment': sentiment['label'],
            'confidence': sentiment['score']
        }

# Document Search Engine
class DocumentSearchEngine:
    """Semantic search for documents."""
    
    def __init__(self):
        from transformers import AutoTokenizer, AutoModel
        import torch
        import numpy as np
        
        self.tokenizer = AutoTokenizer.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
        self.model = AutoModel.from_pretrained("sentence-transformers/all-MiniLM-L6-v2")
        self.documents = []
        self.embeddings = []
    
    def index_documents(self, documents: List[str]):
        """Index documents for search."""
        self.documents = documents
        self.embeddings = [self._encode(doc) for doc in documents]
    
    def _encode(self, text: str):
        """Encode text to embedding."""
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
        with torch.no_grad():
            outputs = self.model(**inputs)
        return outputs.last_hidden_state.mean(dim=1).numpy()
    
    def search(self, query: str, top_k: int = 5) -> List[Dict]:
        """Search for relevant documents."""
        from sklearn.metrics.pairwise import cosine_similarity
        
        query_embedding = self._encode(query)
        
        results = []
        for idx, doc_embedding in enumerate(self.embeddings):
            similarity = cosine_similarity(query_embedding, doc_embedding)[0][0]
            results.append({
                'document': self.documents[idx],
                'score': similarity,
                'rank': idx
            })
        
        # Sort by similarity
        results.sort(key=lambda x: x['score'], reverse=True)
        return results[:top_k]

# Social Media Monitoring
class SocialMediaMonitor:
    """Monitor and analyze social media content."""
    
    def __init__(self):
        from transformers import pipeline
        
        self.sentiment_analyzer = pipeline("sentiment-analysis")
        self.emotion_classifier = pipeline(
            "text-classification",
            model="j-hartmann/emotion-english-distilroberta-base"
        )
    
    def analyze_post(self, text: str) -> Dict:
        """Analyze social media post."""
        sentiment = self.sentiment_analyzer(text)[0]
        emotion = self.emotion_classifier(text)[0]
        
        # Extract hashtags and mentions
        import re
        hashtags = re.findall(r'#\w+', text)
        mentions = re.findall(r'@\w+', text)
        
        return {
            'sentiment': sentiment,
            'emotion': emotion,
            'hashtags': hashtags,
            'mentions': mentions,
            'engagement_score': self._calculate_engagement(text)
        }
    
    def _calculate_engagement(self, text: str) -> float:
        """Calculate engagement score."""
        # Simple heuristic based on length and special characters
        score = min(len(text) / 280, 1.0)  # Normalize by typical post length
        score += 0.1 * (text.count('!') + text.count('?'))
        return min(score, 1.0)

print("Real-world NLP applications ready for deployment!")
```

## See Also

- [Python Overview](../index.md)
- [Machine Learning](../machine-learning/index.md)
- [Neural Networks](../algorithms/neural-networks.md)
- [Deep Learning](../deep-learning/index.md)

## Resources

- [spaCy Documentation](https://spacy.io/)
- [Hugging Face Transformers](https://huggingface.co/docs/transformers/)
- [NLTK Documentation](https://www.nltk.org/)
- [Stanford NLP Course](https://web.stanford.edu/class/cs224n/)
