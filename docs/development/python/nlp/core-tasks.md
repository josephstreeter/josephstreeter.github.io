---
title: "Core NLP Tasks"
description: "Part-of-speech tagging, named entity recognition, dependency parsing, and coreference resolution"
author: "Joseph Streeter"
tags: ["nlp", "python", "pos tagging", "ner", "parsing"]
category: "development"
last_updated: "2026-08-01"
---
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
