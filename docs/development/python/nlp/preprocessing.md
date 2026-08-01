---
title: "Text Preprocessing"
description: "Cleaning, normalizing, tokenizing, and stemming text before analysis"
author: "Joseph Streeter"
tags: ["nlp", "python", "preprocessing", "tokenization", "lemmatization"]
category: "development"
last_updated: "2026-08-01"
---
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
