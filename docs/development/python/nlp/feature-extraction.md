---
title: "Feature Extraction"
description: "Turning text into numeric features: bag of words, TF-IDF, and word embeddings"
author: "Joseph Streeter"
tags: ["nlp", "python", "features", "tf-idf", "embeddings"]
category: "development"
last_updated: "2026-08-01"
---
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

## Related Topics

- [NLP Overview](index.md)
- [Text Preprocessing](preprocessing.md)
- [Feature Extraction](feature-extraction.md)
- [Core NLP Tasks](core-tasks.md)
- [Text Classification](text-classification.md)
- [Information Extraction](information-extraction.md)
- [Topic Modeling](topic-modeling.md)
- [Language Models](language-models.md)
- [Sequence-to-Sequence Tasks](seq2seq.md)
- [Advanced Topics](advanced-topics.md)
- [Working with Libraries](libraries.md)
- [Performance and Best Practices](performance-and-practices.md)
- [Real-World Applications](applications.md)
