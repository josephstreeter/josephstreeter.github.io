---
title: "Topic Modeling"
description: "Discovering latent topics with LDA and non-negative matrix factorization"
author: "Joseph Streeter"
tags: ["nlp", "python", "topic modeling", "lda", "nmf"]
category: "development"
last_updated: "2026-08-01"
---
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
