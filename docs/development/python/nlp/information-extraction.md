---
title: "Information Extraction"
description: "Extracting entities, relationships, and events from unstructured text"
author: "Joseph Streeter"
tags: ["nlp", "python", "information extraction", "entities", "relations"]
category: "development"
last_updated: "2026-08-01"
---
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
