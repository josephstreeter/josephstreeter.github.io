---
title: "Working with Libraries"
description: "Practical usage of spaCy, Hugging Face Transformers, and NLTK"
author: "Joseph Streeter"
tags: ["nlp", "python", "spacy", "transformers", "nltk"]
category: "development"
last_updated: "2026-08-01"
---
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
