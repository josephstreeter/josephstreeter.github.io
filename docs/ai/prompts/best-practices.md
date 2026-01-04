---
title: "AI Prompting Guide"
description: "A practical reference guide for writing effective AI prompts, covering core principles, advanced techniques, and comprehensive prompt templates"
author: "Joseph Streeter"
ms.date: "2025-12-15"
ms.topic: "guide"
keywords: ["ai", "prompting", "chatgpt", "claude", "llm", "artificial intelligence", "prompt engineering", "best practices"]
uid: docs.ai.prompts
---

A practical reference guide for writing effective AI prompts. Synthesized from multiple sources including video tutorials, leadership frameworks, and official AI provider documentation.[^intro]

[^intro]: Primary sources include NetworkChuck's "Mastering AI Prompting in 2025" video tutorial, Geoff Woods' "The AI-Driven Leader" framework, and official prompting guides from Anthropic, OpenAI, and Google. See [References](#references) for complete citations.

---

## Contents

- [Quick Start](#quick-start-5-minutes)
- [The Core Principle](#the-core-principle)
- [The Four Pillars](#the-four-pillars-of-effective-prompts)
  - [Persona](#1-persona-who)
  - [Context](#2-context-what)
  - [Format](#3-format-how)
  - [Examples](#4-examples-show)
- [Working with Prompts](#working-with-prompts)
  - [Two-Prompt System](#the-two-prompt-system)
  - [Single vs Multi-Turn](#single-prompt-vs-multi-turn-conversations)
  - [Attachments & Files](#working-with-attachments--files)
  - [Using AI to Improve Prompts](#using-ai-to-improve-your-prompts)
- [Advanced Techniques](#advanced-techniques)
  - [Chain of Thought](#chain-of-thought-cot)
  - [Tree of Thought](#tree-of-thought-tot)
  - [Battle of the Bots](#battle-of-the-bots-adversarial-validation)
  - [Interview Pattern](#the-interview-pattern)
  - [Role-Play & Simulation](#role-play--simulation)
- [Prompt Templates](#prompt-templates)
- [The Meta-Skill: Clarity of Thought](#the-meta-skill-clarity-of-thought)
- [Troubleshooting Bad Results](#troubleshooting-bad-results)
- [AI Limitations & When to Stop](#ai-limitations--when-to-stop)
- [Verifying AI Output](#verifying-ai-output)
- [Common Mistakes](#common-mistakes-to-avoid)
- [Quick Reference](#quick-reference)
- [Prompt Library](#prompt-library)
  - [Getting Started](#getting-started-prompts)
  - [Creative & Brainstorming](#creative--brainstorming-prompts)
  - [Personal & Life](#personal--life-prompts)
  - [Learning & Research](#learning--research-prompts)
  - [Strategic Planning](#strategic-planning-prompts)
  - [Decision Making](#decision-making-prompts)
  - [People & Leadership](#people--leadership-prompts)
  - [Communication](#communication-prompts)
  - [Prioritization](#prioritization--time-management-prompts)
  - [Technical & IT](#technical--it-leadership-prompts)
  - [Coding & Development](#coding--development-prompts)
  - [Individual Contributor](#individual-contributor-prompts)
  - [Wellness](#wellness--sustainability-prompts)
- [References](#references)

---

## The Core Principle

> "A prompt is a call to action to the large language model. You aren't asking the AI, you're programming it with words."[^core]

LLMs are **prediction engines**, not thinking machines. They work like advanced auto-complete, predicting the most likely next words based on patterns.[^predict] Your job is to set up a clear pattern that leads to the output you want.

[^core]: Adapted from NetworkChuck's "Mastering AI Prompting in 2025" (2024).
[^predict]: This conceptual model, while simplified, helps users understand why specificity matters. For technical details on how LLMs actually work, see Anthropic's documentation on Claude's architecture.

**Key insight:** Vague patterns = vague results. Focused patterns = better results.

---

## Quick Start (5 Minutes)

If you only remember three things:

1. **Be specific** - Vague prompts get vague results
2. **Provide context** - Everything AI doesn't know, it will make up
3. **Specify format** - Tell AI exactly what output should look like

**Minimum viable prompt:**

```text
You are a [role with relevant expertise].

I need help with [specific task].

Context:
- [Key fact 1]
- [Key fact 2]
- [Constraint or requirement]

Please provide [specific output format, e.g., "a bullet-point list" or "under 200 words"].
```

**Example - Bad vs Good:**

| Bad | Good |
| --- | --- |
| "Write a marketing email" | "You're a B2B SaaS copywriter. Write a 150-word email announcing our new API feature to technical decision-makers. Tone: professional but not stiff. Include one clear CTA." |

**Ready for more?** Read on for the complete framework, or jump to the [Prompt Library](#prompt-library) for ready-to-use prompts.

---

## The Four Pillars of Effective Prompts

Every good prompt contains some combination of these four elements:

### 1. Persona (Who)

Tell the AI who it should be when responding.

**Why it works:** Narrows the AI's focus to relevant knowledge and expertise.

**Template:**

```text
You are a [role] with expertise in [domain]. You have [years] of experience in [specific area].
```

**Examples:**

| Bad | Good |
| --- | --- |
| "Write an email" | "You're a senior site reliability engineer at a major cloud provider writing to technical customers" |
| "Explain databases" | "You're a patient database instructor teaching someone with no technical background" |
| "Review my code" | "You're a security-focused code reviewer who prioritizes finding vulnerabilities" |

**API/Developer note:** When building apps with AI APIs, personas typically go in the **system prompt** (which persists across the conversation) rather than the user prompt. In consumer apps like ChatGPT or Claude.ai, include the persona at the start of your message since you don't control the system prompt. See [The Two-Prompt System](#the-two-prompt-system) for more details.

---

### 2. Context (What)

Provide all necessary details and information. This is the **most important** technique.

**Why it works:** Whatever context you don't include, the AI will fill in itself (hallucination).

**The ABC Rule:** Always Be Contexting

**Template:**

```text
Background: [situation/problem]
Relevant details: [specific facts, constraints, requirements]
What I've tried: [previous attempts, if applicable]
Goal: [what success looks like]
```

**Examples:**

| Bad | Good |
| --- | --- |
| "Birthday present ideas, $30 budget" | "Birthday present ideas. Budget: $30. Recipient: 29-year-old who loves winter sports, recently switched from snowboarding to skiing, lives in Colorado" |
| "Debug this code" | "Debug this Python function. It should return a sorted list but returns None. Python 3.11, running on Linux. Error occurs on line 15." |

**Power Phrases:**

- Give permission to fail: "If you don't know, say 'I don't know'"
- Enable tools: "You can use web search to get current information"
- Set boundaries: "Only use information I've provided"

---

### 3. Format (How)

Tell the AI exactly how you want the output to look.

**Why it works:** Standardizes output and reduces variability. Often forgotten but extremely powerful.

**Template:**

```text
Format requirements:
- Length: [word count or scope]
- Structure: [bullet points, numbered list, paragraphs, table]
- Tone: [professional, casual, technical, friendly]
- Include: [specific elements to include]
- Exclude: [things to avoid]
```

**Common format instructions:**

- "Keep it under 200 words"
- "Use bullet points for the main ideas"
- "Format as a table with columns for X, Y, Z"
- "Tone: professional but approachable, no corporate jargon"
- "Start with a one-sentence summary"
- "End with three actionable next steps"

---

### 4. Examples (Show)

Show the AI what you want instead of just describing it. This is called **Few-Shot Prompting**.[^fewshot]

**Why it works:** Demonstrates the pattern you want the AI to continue.

[^fewshot]: Few-shot prompting is well-documented in OpenAI's prompt engineering guide and has been shown to significantly improve output consistency, especially for tasks requiring specific formats or styles.

**Template:**

```text
Here are examples of what I'm looking for:

Example 1:
Input: [example input]
Output: [example output]

Example 2:
Input: [example input]
Output: [example output]

Now do the same for:
Input: [your actual input]
```

**When to use few-shot:**

- Specific writing style or tone
- Unusual formatting requirements
- Domain-specific terminology
- Consistent structure across multiple outputs

---

## Working with Prompts

### The Two-Prompt System

Most AI interfaces use two types of prompts:

| Prompt Type | Purpose | Who Sets It | Persistence |
| --- | --- | --- | --- |
| **System Prompt** | Defines who the AI is and how it behaves | Developer/App | Stays constant across conversation |
| **User Prompt** | What you're asking the AI to do | You | Changes with each message |

**In consumer apps (ChatGPT, Claude.ai):**

- System prompt is set by the app (you don't control it)
- Custom instructions/preferences act like a partial system prompt
- Your messages are user prompts

**In API/developer contexts:**

- You control both system and user prompts
- Personas typically go in the system prompt
- Task-specific instructions go in the user prompt

**Example API structure:**

```text
System: You are a senior software architect who gives concise,
practical advice. You prioritize simplicity over cleverness.

User: Review this database schema for a todo app with 10K users.
[schema here]
```

**Why it matters:** Understanding this helps you:

- Know where to put persistent instructions (custom instructions/system prompt)
- Understand why the same prompt works differently in different apps
- Debug when AI "forgets" your preferences (system prompt was overridden)

---

### Single Prompt vs Multi-Turn Conversations

Knowing when to use one prompt vs a conversation saves time and gets better results.

**Use a single prompt when:**

- Task is well-defined and self-contained
- You have all the context upfront
- Output format is clear
- You want reproducible results

**Use multi-turn conversation when:**

- Exploring a complex problem
- You need to iterate on output
- Context needs to be gathered (interview pattern)
- Building on previous responses

**Multi-turn best practices:**

- Reference previous responses: "In your last response, you mentioned X..."
- Build incrementally: "Good. Now expand on point 3..."
- Course-correct early: "That's not quite right. I meant..."
- Summarize periodically: "So far we've established..."

**Conversation starters for exploration:**

```text
Let's work through this together. I'll describe my situation,
and you ask clarifying questions before we dive into solutions.
```

```text
I want to think through [topic] with you. Start by asking me
what I already know about it, then help me fill in the gaps.
```

---

### Working with Attachments & Files

When prompting with documents, images, or code files, structure matters.

**General template for file analysis:**

```text
I'm attaching [type of file] that contains [brief description].

Context:
- Purpose of this file: [why it exists]
- What I need from you: [specific task]
- Focus areas: [what to pay attention to]

Please [specific action] and format your response as [format].
```

**Document-specific tips:**

| File Type | Key Instructions |
| --- | --- |
| **PDFs/Docs** | "Focus on pages X-Y" or "Skip the appendix" |
| **Code files** | Specify language, mention dependencies |
| **Spreadsheets** | Describe column meanings, note any formulas |
| **Images** | Describe what you're looking for, ask specific questions |
| **Long files** | Ask for summary first, then drill into sections |

**For large documents:**

```text
This is a [length] document about [topic].

First, provide a 3-sentence summary.
Then, extract the key points related to [your focus].
Finally, answer: [specific question].

If you need me to clarify any section, ask before proceeding.
```

**Handling multiple files:**

```text
I'm attaching [N] files:
1. [filename] - [what it is]
2. [filename] - [what it is]

Compare these files and identify [what you're looking for].
```

---

### Using AI to Improve Your Prompts

AI can help you write better prompts. Use this when stuck or when you want to level up.

**Prompt enhancement request:**

```text
I want to write a prompt for [task]. Here's my current attempt:

[your draft prompt]

Help me improve this prompt by:
1. Identifying what's unclear or missing
2. Suggesting better structure
3. Adding specificity where needed
4. Rewriting it using best practices

Explain your changes so I can learn.
```

**From vague idea to clear prompt:**

```text
I want AI to help me with [vague goal].

Ask me questions to understand:
- What specifically I'm trying to accomplish
- What context the AI would need
- What format would be most useful
- Any constraints or requirements

Then write an optimized prompt I can use.
```

**Prompt debugging:**

```text
This prompt isn't giving me good results:

[your prompt]

The output I'm getting: [describe the problem]
What I actually want: [describe desired output]

Diagnose why this prompt isn't working and fix it.
```

---

## Advanced Techniques

### Chain of Thought (COT)

Tell the AI to think step-by-step before answering.[^cot]

**When to use:** Complex problems, math, logic, multi-step reasoning.

**When it helps less:** Simple factual questions, creative writing, tasks where process doesn't matter—only the output does.

**Template:**

```text
Before answering, think through this step by step:
1. First, identify [key elements]
2. Then, consider [relevant factors]
3. Finally, synthesize [your conclusion]

Show your reasoning, then provide the final answer.
```

**Simple version:** Just add "Let's think step by step" or "Think through this carefully before responding."

**Note:** Many AI providers now have built-in "Extended Thinking" or "Reasoning" modes (Claude's extended thinking, ChatGPT's reasoning mode, Gemini's thinking mode) that apply chain-of-thought automatically. For complex reasoning tasks, enabling these modes often outperforms manual COT prompting.[^mollick]

[^cot]: Wei, J., et al. (2022). "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models." The original research demonstrated significant accuracy improvements on math and reasoning tasks when models were prompted to show their work.
[^mollick]: Ethan Mollick, Wharton professor and AI researcher, notes that "95% of all practical problems can be solved by turning on extended thinking."

---

### Tree of Thought (TOT)

Explore multiple solution paths simultaneously.[^tot]

**When to use:** Creative problems, strategy decisions, when the first idea might not be best.

[^tot]: Yao, S., et al. (2023). "Tree of Thoughts: Deliberate Problem Solving with Large Language Models." This technique extends Chain of Thought by exploring multiple reasoning paths rather than a single linear chain.

**Template:**

```text
Brainstorm three distinct approaches to this problem:
1. Approach A: [perspective/angle]
2. Approach B: [different perspective]
3. Approach C: [contrasting perspective]

For each approach:
- Outline the solution
- List pros and cons
- Identify risks

Then synthesize the best elements into a final recommendation.
```

---

### Battle of the Bots (Adversarial Validation)

Generate competing options from different perspectives, critique them, then synthesize.

**When to use:** Important communications, complex decisions, when you need the best possible output.

**Template:**

```text
Round 1 - Generate competing versions:
- Persona A [description]: Write version 1
- Persona B [description]: Write version 2

Round 2 - Critique:
- Persona C [critical perspective]: Evaluate both versions. What works? What doesn't? Be harsh.

Round 3 - Synthesize:
- Combine the best elements from both versions based on the critique.
- Produce the final output.
```

**Example personas for an apology email:**

- Persona A: PR crisis manager (reputation-focused)
- Persona B: Technical engineer (accuracy-focused)
- Persona C: Angry customer (recipient perspective)

---

### The Interview Pattern

Have AI gather information by interviewing you before producing output.[^interview]

**Why it works:** Instead of you trying to anticipate what AI needs, let AI ask for what it needs. This results in better context and dramatically better output. It also transforms AI from a task executor into a thinking partner.

[^interview]: This pattern is central to Geoff Woods' "AI-Driven Leader" framework, which emphasizes treating AI as a "Thought Partner" rather than a task executor. The "one question at a time" constraint prevents AI from overwhelming users and ensures thorough context gathering.

**Template:**

```text
Interview me by asking ONE question at a time to understand
[what you want AI to learn].

Once you have enough information, [what you want AI to produce].
```

**Examples:**

```text
Interview me by asking one question at a time to understand my
business situation. Once you have enough information, help me
identify the top 3 priorities I should focus on this quarter.
```

```text
Act as my Thought Partner. Interview me one question at a time
to understand the decision I'm facing. After gathering context,
help me evaluate my options and identify what I might be missing.
```

**When to use:**

- Complex situations that are hard to explain upfront
- When you're not sure what context matters
- Strategic thinking and planning
- When you want AI to challenge your assumptions
- Anytime you'd benefit from talking through a problem

**The Three Essential Personas for Interview Pattern:**

| Persona | Purpose | Use When |
| --- | --- | --- |
| **The Interviewer** | Gathers information through questions before acting | You need to explain a complex situation |
| **The Communicator** | Crafts clear, compelling messages for specific audiences | You need to persuade or inform others |
| **The Challenger** | Stress-tests your thinking and finds blind spots | You need your ideas pressure-tested |

**Interviewer prompt:**

```text
Act as the Interviewer. Ask me one question at a time to
understand [topic]. Once you have enough information, [task].
```

**Challenger prompt:**

```text
Act as the Challenger. Your job is to find weaknesses in my
thinking. Challenge my assumptions about [topic]. Ask tough
questions I might be avoiding. After our discussion, summarize
what you think I'm missing.
```

---

### Role-Play & Simulation

Have AI adopt a specific persona to practice conversations or get feedback from different perspectives.

**Why it works:** AI can simulate how stakeholders, customers, or critics might respond, helping you prepare for real conversations and identify weaknesses in your approach.

**Simulate a Stakeholder:**

```text
Role-play as [person/role - describe their priorities, concerns,
communication style].

I'll present [what you're presenting]. Respond as they would -
push back where they'd push back, ask questions they'd ask.

After we finish, break character and give me feedback on:
1. What I did well
2. Where I lost them
3. Specific changes to improve my approach
```

**Simulate a Customer:**

```text
You are my ideal customer: [describe persona, role, company type,
priorities, typical concerns, decision-making style].

Review this [proposal/pitch/product]. Tell me:
- What you like about it
- What concerns you or doesn't make sense
- What questions you'd ask before deciding
- What would make you say yes
- What would make you say no
```

**When to use:**

- Preparing for difficult conversations
- Testing proposals before presenting
- Practicing negotiations or pitches
- Getting feedback from different perspectives
- Anticipating objections

---

## Prompt Templates

### General Purpose Template

```text
**Role:** You are a [persona with relevant expertise].

**Context:**
- Background: [situation]
- Goal: [what you want to achieve]
- Constraints: [limitations, requirements]
- Audience: [who will read/use this]

**Task:** [Specific action you want the AI to take]

**Format:**
- Length: [target length]
- Structure: [format requirements]
- Tone: [desired tone]

**Additional instructions:**
- [Any other specific requirements]
- If you're unsure about something, ask for clarification rather than guessing.
- If you don't have enough information to answer well, say so.
```

---

### Writing Task Template

```text
Write a [type of content] about [topic].

**Audience:** [who will read this]
**Purpose:** [what it should accomplish]
**Tone:** [how it should sound]
**Length:** [target word count or scope]

**Must include:**
- [Required element 1]
- [Required element 2]

**Must avoid:**
- [Thing to exclude 1]
- [Thing to exclude 2]

**Example of desired style:**
[Paste an example if available]
```

---

### Analysis/Review Template

```text
Analyze [thing to analyze] for [purpose].

**Context:** [relevant background]

**Focus areas:**
1. [Aspect 1]
2. [Aspect 2]
3. [Aspect 3]

**Output format:**
- Summary (2-3 sentences)
- Key findings (bullet points)
- Recommendations (numbered list)
- Risks/concerns (if applicable)

**Evaluation criteria:**
- [Criterion 1]
- [Criterion 2]
```

---

### Problem-Solving Template

```text
I need help with [problem description].

**Current situation:**
[Describe what's happening]

**Desired outcome:**
[Describe what success looks like]

**What I've tried:**
[List previous attempts]

**Constraints:**
- [Limitation 1]
- [Limitation 2]

**Questions:**
1. [Specific question 1]
2. [Specific question 2]

Think through this step by step before providing recommendations.
```

---

## The Meta-Skill: Clarity of Thought

> "If you can't explain it clearly yourself, you can't prompt it."[^clarity]

All prompting techniques are fundamentally about **clarity**:

[^clarity]: This insight appears across multiple prompt engineering resources. Daniel Miessler (creator of Fabric) advises: "Before working on any prompt, sit down and describe exactly how you want it to work. Red team it from different angles."

| Technique | Forces you to think about |
| --- | --- |
| Personas | Who should answer this? What perspective matters? |
| Context | What are the facts? What does it need to know? |
| Format | What does "good" look like? |
| Chain of Thought | How would I describe this process? |
| Few-Shot | Can I show an example? |

**The truth:** These techniques don't make the AI smarter—they make **you** clearer.

---

## Troubleshooting Bad Results

When AI output isn't what you wanted:

### The Skill Issue Mindset

> "Treat everything as a personal skill issue. If the AI's response is bad, I didn't explain it well enough."[^thacker]

[^thacker]: Attributed to Joseph Thacker (@rez0__), security researcher and prompt engineering practitioner. While this mindset is valuable for improving prompts, see [AI Limitations & When to Stop](#ai-limitations--when-to-stop) for cases where the task itself may be impossible for AI.

### Diagnostic Questions

1. **Did I provide enough context?** Would a human have enough info to do this task?
2. **Did I specify the format?** Does the AI know what "good" looks like?
3. **Did I give a persona?** Does the AI know what perspective to take?
4. **Did I show examples?** Would an example clarify what I want?
5. **Am I clear on what I want?** Can I explain it without AI?

### The Reset Method

When struggling:

1. Stop prompting
2. Open a blank document
3. Write out exactly what you want to accomplish
4. Describe what "good" would look like
5. List all relevant facts and constraints
6. **Then** write your prompt

---

## AI Limitations & When to Stop

Not every problem is a prompting problem. Sometimes AI genuinely can't do what you need.

### What AI Cannot Do Well

| Task Type | Why It Fails | What To Do Instead |
| --- | --- | --- |
| **Real-time information** | Knowledge has a cutoff date | Enable web search or check manually |
| **Complex math** | Makes arithmetic errors, especially multi-step | Use a calculator or code execution |
| **Precise counting** | Can't reliably count words, characters, items | Count manually or use code |
| **Guaranteed accuracy** | Probabilistic, not deterministic | Always verify critical facts |
| **True randomness** | Patterns emerge, not truly random | Use proper random generators |
| **Physical world tasks** | No embodiment, can't take real actions | It can only advise, not do |
| **Accessing your files/systems** | Can't see what you don't share | Paste or upload relevant content |
| **Remembering past conversations** | Limited memory, sessions are mostly fresh | Re-provide important context |

### Exit Criteria: When to Stop Prompting

If you've tried 3-4 different approaches and still aren't getting good results, ask yourself:

1. **Is this task actually possible for AI?** (Check the table above)
2. **Would a human need special tools or access I haven't provided?**
3. **Am I asking for precision AI can't guarantee?**
4. **Is the cost of more iteration worth it vs doing it manually?**

**Signs to give up and try another approach:**

- AI keeps making the same type of error despite corrections
- Output quality plateaus despite adding more detail
- You're on iteration 5+ with no improvement
- The task requires real-time data or calculations you can't verify

**The uncomfortable truth:** Sometimes the fastest path is doing it yourself or using a different tool. AI is powerful but not universal.

---

## Verifying AI Output

AI can sound confident while being wrong. Build verification into your workflow.

### Hallucination Red Flags

Watch for these warning signs:

- **Overly specific details** you didn't provide (dates, statistics, quotes)
- **Confident assertions** about recent events or niche topics
- **Citations** that look plausible but you haven't verified
- **Technical details** that seem right but you can't confirm
- **Unanimous agreement** when you expected nuance

### Verification Strategies

| Output Type | How to Verify |
| --- | --- |
| **Facts/statistics** | Cross-reference with authoritative sources |
| **Code** | Run it, test edge cases, review logic |
| **Advice** | Get second opinion (human or different AI) |
| **Summaries** | Spot-check key claims against source |
| **Creative work** | Check for plagiarism if publishing |

### Prompts That Reduce Hallucination

Add these to high-stakes prompts:

```text
If you're not confident about something, say so explicitly.
Distinguish between facts you're certain of and inferences you're making.
If I need to verify anything externally, flag it.
```

```text
For any statistics or claims, note your confidence level:
- HIGH: Well-established, widely documented
- MEDIUM: Likely accurate but should verify
- LOW: Uncertain, definitely verify before using
```

### The 3-Source Rule

For anything important:

1. Ask AI
2. Verify with a primary source
3. Cross-check with a second source if stakes are high

Don't skip this for: medical info, legal info, financial decisions, anything you'll publish.

---

## Common Mistakes to Avoid

Learn from others' mistakes to get better results faster.

| Mistake | Why It Fails | Better Approach |
| --- | --- | --- |
| Starting with "Can you..." or "Could you..." | Wastes tokens, implies uncertainty | Direct instruction: "Write a...", "Analyze this..." |
| No format specification | AI chooses arbitrarily, inconsistent results | Always specify: length, structure, tone |
| Assuming AI remembers | Each prompt is fresh context (mostly) | Include all relevant context every time |
| Over-prompting first try | More isn't always better, harder to debug | Start simple, add complexity as needed |
| Not iterating | First response is rarely perfect | Refine: "Good, but make it more concise" |
| Asking multiple questions at once | AI may skip or conflate answers | One question per prompt, or number them explicitly |
| Vague success criteria | AI can't hit a target it can't see | Define what "good" looks like |
| Ignoring hallucinations | Accepting AI output uncritically | Verify facts, ask for sources, use "say I don't know" |

### Red Flags in Your Prompts

If you catch yourself writing these, pause and rethink:

- **"Just make it good"** → Define what "good" means
- **"You know what I mean"** → AI doesn't; spell it out
- **"Do your best"** → Specify the criteria for success
- **"Make it professional"** → Professional for whom? Define tone precisely
- **"Something like..."** → Provide an actual example instead

---

## Quick Reference

### Prompt Checklist

Before submitting a prompt, check:

- [ ] **Persona defined?** (Who should answer this?)
- [ ] **Context provided?** (All relevant facts included?)
- [ ] **Format specified?** (Length, structure, tone?)
- [ ] **Examples given?** (If needed for clarity?)
- [ ] **Permission to fail?** (Can say "I don't know"?)
- [ ] **Clear goal?** (What does success look like?)

### Power Phrases

| Phrase | Purpose |
| --- | --- |
| "Think step by step" | Activates reasoning |
| "If you don't know, say so" | Prevents hallucination |
| "Before answering, consider..." | Encourages reflection |
| "Here's an example of what I want" | Clarifies expectations |
| "You can use web search" | Enables current information |
| "Ask clarifying questions if needed" | Prevents assumptions |
| "Ask me one question at a time" | Enables interview pattern |
| "After gathering information, provide..." | Sets expectation for synthesis |
| "Challenge my biases and assumptions" | Activates critical thinking |
| "Give me feedback on what I did well and where I can improve" | Gets balanced evaluation |
| "Rank by [criteria] and explain why" | Forces prioritization with reasoning |
| "What am I missing?" | Surfaces blind spots |
| "What would change your recommendation?" | Tests robustness of advice |
| "Limit to top 5" | Prevents overwhelming output |
| "Once you have enough information..." | Signals when to stop gathering and start producing |
| "Break character and give feedback" | Exits role-play for meta-analysis |

---

## Prompt Library

A collection of ready-to-use prompts organized by category. Fill in the `[bracketed sections]` with your specifics.

### Quick Index

| Category | Prompts |
| --- | --- |
| [Getting Started](#getting-started-prompts) | First-Time AI Thought Partner, Create Your Lightbulb Moment |
| [Creative & Brainstorming](#creative--brainstorming-prompts) | Structured Brainstorm, Creative Writing Partner, Name Generator, Idea Expander, Overcome Creative Block |
| [Personal & Life](#personal--life-prompts) | Major Decision Helper, Health Research Partner, Financial Planning, Travel Planner, Difficult Conversation (Personal) |
| [Learning & Research](#learning--research-prompts) | Explain Like I'm a Beginner, Study Plan Creator, Research Synthesizer, Concept Deep-Dive, Book/Article Analysis |
| [Strategic Planning](#strategic-planning-prompts) | Analyze Strategic Plan, Devil's Advocate, Quarterly Review |
| [Decision Making](#decision-making-prompts) | Evaluate Options, Identify Risks, Map Stakeholders |
| [People & Leadership](#people--leadership-prompts) | Difficult Conversation Prep, Team AI Skills, Delegation |
| [Communication](#communication-prompts) | Craft Message, Performance Review Follow-up |
| [Prioritization](#prioritization--time-management-prompts) | Calendar Alignment, Weekly Priorities, Identify Your 20% |
| [Technical & IT](#technical--it-leadership-prompts) | Incident Post-Mortem, Technical Decision Doc |
| [Coding & Development](#coding--development-prompts) | Code Review, Debug Code, Explain Code, Refactor Code, Write Unit Tests, Generate Code |
| [Individual Contributor](#individual-contributor-prompts) | Weekly Manager Update, Career Conversation Prep |
| [Wellness](#wellness--sustainability-prompts) | Workload Assessment |

---

### Getting Started Prompts

#### First-Time AI Thought Partner

**Use when:** You're new to using AI as a strategic partner

```text
You are a patient and curious strategic thinking partner who helps
leaders clarify their thoughts through Socratic questioning.

I'm exploring using AI as a Thought Partner but don't know where to
begin. I work in [your role/industry]. My biggest current challenge
is [brief description].

Interview me by asking ONE question at a time to:
1. Understand what's on my mind this week
2. Identify a simple, valuable use case where you can help
3. Help me clarify my thinking on that topic

Continue the conversation until we've made progress on the issue.
Ask only one question at a time and wait for my response.
```

#### Create Your Lightbulb Moment

**Use when:** You want to experience AI's value on a real problem

```text
You are a strategic Thought Partner skilled at helping people
think through complex situations systematically.

Here's my situation: [describe what's happening]
Here's what I'm trying to solve: [describe your goal]
Constraints I'm working with: [time, budget, people, etc.]

Help me think through potential solutions by:
1. Asking clarifying questions (one at a time)
2. Identifying assumptions I might be making
3. Suggesting approaches I may not have considered
4. Helping me evaluate options

After gathering info, provide 3-5 potential solutions ranked by
feasibility and impact, with risks highlighted for each.
```

---

### Creative & Brainstorming Prompts

#### Structured Brainstorm

**Use when:** You need diverse ideas for a problem or opportunity

```text
You are a creative strategist skilled at generating diverse,
actionable ideas by exploring problems from multiple angles.

Challenge: [describe what you're trying to solve or create]
Context: [relevant background, constraints, audience]
What's been tried: [previous ideas or approaches, if any]

Generate ideas using these lenses:
1. **Conventional** - What would the obvious/safe approach be?
2. **Contrarian** - What if we did the opposite of convention?
3. **Analogy** - What would [industry/company] do in this situation?
4. **Constraint removal** - What if [key constraint] didn't exist?
5. **User-first** - What would delight users regardless of feasibility?

For each idea:
- One-sentence description
- Key benefit
- Biggest risk or challenge
- Feasibility (High/Medium/Low)

Then recommend: Which 2-3 ideas are worth exploring further and why?
```

#### Creative Writing Partner

**Use when:** Writing content that needs creativity and polish

```text
You are a creative writing collaborator who helps develop ideas
while preserving the author's voice and intent.

Project: [what you're writing - blog post, story, speech, etc.]
Audience: [who will read this]
Tone: [how it should feel - inspiring, humorous, authoritative, etc.]
My draft/notes: [paste what you have]

Help me by:
1. Identifying what's working well (keep these elements)
2. Suggesting where to expand or cut
3. Offering alternative phrasings for weak sections
4. Proposing a stronger opening and closing

Provide 3 options for any major changes so I can choose.
Preserve my voice - enhance, don't replace.
```

#### Name Generator

**Use when:** You need names for products, projects, companies, or features

```text
You are a naming specialist who creates memorable, meaningful names.

What needs a name: [product/project/company/feature]
What it does: [brief description]
Key attributes to convey: [3-5 qualities]
Audience: [who will hear this name]
Names to avoid: [competitors, taken names, style to avoid]
Style preference: [serious/playful/technical/approachable/etc.]

Generate 15 name options across these categories:
1. **Descriptive** (says what it does)
2. **Evocative** (suggests a feeling or benefit)
3. **Abstract** (unique coined words)
4. **Metaphorical** (draws on imagery)
5. **Acronym-based** (if appropriate)

For your top 5 picks, provide:
- The name
- Why it works
- Potential concerns (trademark, pronunciation, meaning in other languages)
```

#### Idea Expander

**Use when:** You have a seed of an idea that needs development

```text
You are an innovation consultant who helps develop raw ideas into
actionable concepts.

My initial idea: [describe your rough idea]
Problem it solves: [what pain point or opportunity]
Why I think it could work: [your initial reasoning]
What I'm unsure about: [gaps in your thinking]

Help me develop this idea by:
1. Asking 3-5 clarifying questions to understand it better
2. Identifying the core insight (what makes this idea valuable)
3. Exploring variations (3 different ways to execute this)
4. Stress-testing (what could go wrong, who would hate this)
5. Suggesting next steps to validate the idea

Be constructively critical - help me see blind spots while
building on what's promising.
```

#### Overcome Creative Block

**Use when:** You're stuck and need to break through

```text
You are a creativity coach who helps people break through blocks
using proven techniques.

What I'm trying to create: [project/task]
Where I'm stuck: [specific point of blockage]
What I've tried: [approaches that haven't worked]
Deadline pressure: [none/some/high]
My energy level: [low/medium/high]

Help me get unstuck using these approaches:
1. **Reframe the problem** - Maybe I'm solving the wrong thing?
2. **Lower the bar** - What's the minimum viable version?
3. **Change constraints** - What if [constraint] was different?
4. **Steal wisely** - What examples could inspire me?
5. **Just start** - Give me a specific first sentence/step to write

Pick the approach most likely to help given my situation.
Don't give me more options - give me momentum.
```

---

### Personal & Life Prompts

#### Major Decision Helper

**Use when:** Facing a significant life decision

```text
You are a thoughtful advisor who helps people think through major
life decisions without pushing them toward any particular choice.

The decision I'm facing: [describe the choice]
Options I'm considering:
- Option A: [describe]
- Option B: [describe]

Why this is hard: [what makes it difficult]
Timeline: [when I need to decide]
Who else is affected: [people impacted]

Help me think through this by:
1. Asking clarifying questions about what matters most to me
2. Helping me articulate my values relevant to this decision
3. Exploring what I might regret in each scenario
4. Identifying what information I'm missing

Don't tell me what to do. Help me find my own answer.
Provide a framework I can use, not a recommendation.
```

#### Health Research Partner

**Use when:** Researching a health topic (NOT for diagnosis)

```text
You are a health research assistant who helps people understand
medical topics so they can have better conversations with their
doctors. You are NOT providing medical advice.

Topic I'm researching: [condition/treatment/symptom]
Why I'm looking into this: [context]
What I already know: [current understanding]
Questions I want to answer: [specific questions]

Help me by:
1. Explaining this topic in accessible language
2. Identifying key questions to ask my doctor
3. Noting what factors might be relevant to my situation
4. Flagging anything I should definitely discuss with a professional

Important:
- Always note your confidence level on claims
- Distinguish established medical consensus from emerging research
- Remind me to verify with a healthcare provider
- Don't diagnose or recommend specific treatments
```

#### Financial Planning Thought Partner

**Use when:** Thinking through a financial decision

```text
You are a financial thinking partner who helps people reason through
money decisions. You don't give specific investment advice.

Financial decision: [what you're considering]
Context:
- My situation: [relevant financial context]
- Goal: [what I'm trying to achieve]
- Timeline: [when I need this by]
- Risk tolerance: [conservative/moderate/aggressive]
- What's making this hard: [concerns or uncertainties]

Help me think through this by:
1. Asking questions to understand my full situation
2. Identifying factors I should consider
3. Highlighting risks I might not have thought about
4. Suggesting what a financial professional might ask me

Don't tell me what to do with my money.
Help me develop the right questions and framework.
Flag anything I should definitely discuss with a financial advisor.
```

#### Travel Planner

**Use when:** Planning a trip and need help organizing

```text
You are an experienced travel planner who helps create practical,
enjoyable itineraries.

Trip overview:
- Destination: [where]
- Dates: [when, how long]
- Travelers: [who - ages, interests, mobility]
- Budget: [range]
- Style: [adventure/relaxation/cultural/mixed]
- Must-sees: [non-negotiables]
- Must-avoids: [things you don't want]

Help me plan by:
1. Asking about preferences I haven't mentioned
2. Suggesting a day-by-day framework
3. Identifying logistics to book in advance
4. Noting seasonal considerations or potential issues
5. Recommending how to balance activities and downtime

Provide a practical itinerary I can actually follow.
Note anything I should book early or research further.
```

#### Difficult Conversation Prep (Personal)

**Use when:** Preparing for a hard conversation with family or friends

```text
You are a compassionate communication coach who helps people
navigate difficult personal conversations.

Who I need to talk to: [relationship]
What it's about: [topic]
Why it's hard: [what makes this difficult]
What I want to happen: [ideal outcome]
What I'm afraid of: [worst case concerns]
History: [relevant context about the relationship]

Help me prepare by:
1. Understanding their likely perspective
2. Identifying my core message (what I most need to say)
3. Suggesting how to open the conversation
4. Anticipating their reactions
5. Preparing responses to likely pushback

Provide:
- A suggested opening line
- 2-3 key points to make
- Phrases to avoid
- Phrases that might help
- How to respond if it goes badly
- How to end the conversation well regardless of outcome
```

---

### Learning & Research Prompts

#### Explain Like I'm a Beginner

**Use when:** Learning a new topic from scratch

```text
You are a patient teacher who explains complex topics in simple
terms without being condescending.

Topic I want to understand: [subject]
My current level: [complete beginner / know basics / some familiarity]
Why I'm learning this: [context/goal]
How I learn best: [examples / analogies / visuals / step-by-step]

Explain this topic by:
1. Starting with a one-paragraph overview
2. Breaking it into 3-5 core concepts
3. Using analogies to things I already understand
4. Providing concrete examples
5. Noting common misconceptions to avoid

End with:
- 3 questions to test my understanding
- What to learn next if I want to go deeper
- One practical way to apply this knowledge
```

#### Study Plan Creator

**Use when:** Preparing to learn a subject systematically

```text
You are an expert learning coach who creates effective study plans.

What I want to learn: [subject/skill]
Why: [goal - exam, job, personal interest]
Timeline: [how long I have]
Time available: [hours per week I can commit]
Current level: [starting point]
Learning resources I have: [books, courses, access to tools]
How I learn best: [reading / video / hands-on / discussion]

Create a study plan that:
1. Breaks the subject into logical phases
2. Sets realistic milestones
3. Includes variety (reading, practice, review)
4. Builds in review/reinforcement
5. Accounts for my time constraints

Provide:
- Week-by-week or phase-by-phase breakdown
- Specific activities for each phase
- How to know when I'm ready to move on
- Warning signs I'm falling behind
- How to adjust if life gets in the way
```

#### Research Synthesizer

**Use when:** Making sense of information from multiple sources

```text
You are a research analyst who synthesizes information clearly.

Topic: [what you're researching]
Sources I've gathered: [describe or paste key excerpts]
What I'm trying to figure out: [specific question or goal]
How I'll use this: [context for the synthesis]

Help me by:
1. Identifying the key themes across sources
2. Noting where sources agree vs disagree
3. Highlighting gaps in the information
4. Separating facts from opinions/interpretations
5. Synthesizing into a coherent summary

Provide:
- Executive summary (3-5 sentences)
- Key findings organized by theme
- Contradictions or debates in the material
- What's still unclear or needs more research
- Recommended next steps
```

#### Concept Deep-Dive

**Use when:** You understand basics but want mastery

```text
You are a subject matter expert who helps people develop deep
understanding, not just surface knowledge.

Concept I want to master: [topic]
What I already understand: [current knowledge]
Where I get confused: [specific sticking points]
How I'll apply this: [practical context]

Help me develop mastery by:
1. Explaining the underlying principles (the "why")
2. Addressing my specific confusion points
3. Showing how this connects to related concepts
4. Providing edge cases that test understanding
5. Giving me ways to practice/apply this

Challenge my understanding:
- Ask me questions that reveal gaps
- Present scenarios that require applying the concept
- Show me where beginners typically go wrong
```

#### Book/Article Analysis

**Use when:** Getting more from what you read

```text
You are a critical reading partner who helps extract maximum value
from texts.

What I read: [title, author]
Type: [book / article / paper / report]
Topic: [subject matter]
Why I read it: [what I hoped to learn]
Key passages: [paste any quotes or sections that stood out]

Help me process this by:
1. Summarizing the author's main argument
2. Identifying the key supporting points
3. Noting what evidence they use (and its quality)
4. Highlighting what I should remember long-term
5. Connecting it to other ideas I might know

Provide:
- One-paragraph summary
- 3-5 key takeaways
- Strongest and weakest arguments
- Questions the text raises but doesn't answer
- How I might apply or use these ideas
```

---

### Strategic Planning Prompts

#### Analyze Your Strategic Plan

**Use when:** You have a draft plan and want critical feedback

```text
You are a strategic advisor with 20+ years helping growth-stage
companies refine their execution plans. You've seen common failure
patterns and know what separates good plans from great ones.

Attached is our strategic plan for [timeframe].
Company: [brief description - size, industry, stage]
Primary goal: [specific measurable goal]
Current main challenge: [biggest obstacle]

Act as my Thought Partner:
1. Ask me 5-7 questions (one at a time) to challenge biases
   and assumptions in our plan
2. Evaluate if our plan has sufficiency to achieve our goal
3. After gathering information, provide your analysis:

Deliver your analysis as:
- **Strengths** (what we got right - 3-5 points)
- **Weaknesses** (ranked High/Medium/Low risk - up to 5)
- **Blind Spots** (what we may not be considering)
- **Recommendations** (top 5, prioritized by impact)
- **One Big Question** (the critical question we should be asking)
```

#### Challenge Assumptions (Devil's Advocate)

**Use when:** You need your plan stress-tested before committing

```text
You are a Devil's Advocate - a critical thinker whose job is to
find flaws in plans before reality does. You're thorough and
unafraid to ask hard questions.

Attached is our strategic plan for [timeframe].
We're about to commit significant resources to this direction.
Key assumptions we've made: [list 3-5 assumptions]
Stakes if we're wrong: [what happens if plan fails]

Review our plan and:
1. Identify the 5 most critical assumptions we're making
2. For each assumption, explain how it could be wrong
3. Describe what would happen to our plan if it IS wrong
4. Suggest how we could validate or de-risk each assumption

Then provide:
- Overall plan robustness score (1-10)
- Top 3 changes that would most improve the plan
- The "pre-mortem" - if this plan fails in 12 months, what likely caused it?
```

#### Quarterly Strategic Review

**Use when:** Conducting your quarterly business review

```text
You are an executive coach who has facilitated hundreds of
quarterly strategic reviews for growth companies.

It's time for our quarterly review.
Company: [description]
This quarter's goals were: [list them]
Current progress: [high-level status]

Interview me (one question at a time) to conduct a thorough
quarterly review across these four drivers:

1. **Strategy**: What competitive advantage are we building long-term
   through short-term actions?
2. **Execution**: What progress have we made? What changes are needed?
3. **People**: Right people, right seats, right things, right growth?
4. **Technology**: How are we using tech to raise productivity,
   efficiency, and customer value?

After the interview, provide:
- What's working well (celebrate wins)
- Where I have blind spots
- Top 5 priorities for next quarter
- One habit to start, one to stop, one to continue
```

---

### Decision Making Prompts

#### Evaluate Options

**Use when:** You have 2-3 options and need to decide

```text
You are a decision-making expert who helps leaders think through
important choices systematically without analysis paralysis.

I need to decide between these options:
- Option A: [describe]
- Option B: [describe]
- Option C (if applicable): [describe]

The decision matters because: [stakes/impact]
Timeline for decision: [when you need to decide]
Key constraints: [budget, time, people, politics]

Help me evaluate these options by:
1. Asking 3-5 clarifying questions (one at a time)
2. Analyzing pros and cons of each option
3. Identifying what I might be missing
4. Making a recommendation with reasoning

Provide analysis as a table, then:
- Recommendation with confidence level (High/Medium/Low)
- Key risks of the recommended option
- What would change your recommendation
```

#### Identify & Evaluate Risks

**Use when:** You need to understand second-order consequences

```text
You are a risk analyst who specializes in identifying non-obvious
consequences and downstream effects of business decisions.

Decision I'm considering: [describe the decision]
Why I'm leaning toward it: [your reasoning]
Stakeholders affected: [who's impacted]
Timeline: [when this would take effect]

Help me see what I might be missing:
1. Ask clarifying questions to understand the full context
2. Identify first-order consequences (obvious impacts)
3. Identify second-order consequences (ripple effects)
4. Identify third-order consequences (long-term implications)
5. Suggest mitigation strategies for key risks

Structure your analysis as:
- **First-Order Effects** (immediate, obvious)
- **Second-Order Effects** (what happens because of first-order)
- **Third-Order Effects** (long-term, systemic)
- **Risk Matrix** (likelihood vs impact for top 5 risks)
- **Kill Criteria** - what signals should make me reverse this decision
```

#### Map Stakeholders

**Use when:** You need buy-in for an important decision

```text
You are a change management expert who understands organizational
dynamics and how to build coalitions for important decisions.

Decision/initiative I need support for: [describe]
My role: [your position]
Organization size: [rough size]
Political complexity: [low/medium/high]

Interview me (one question at a time) to identify:
1. Decision-makers who can approve or reject this
2. Influencers who can sway decision-maker thinking
3. Early adopters most affected (closest to impact)
4. Potential blockers and their concerns

Create a stakeholder map as a table:
| Person/Role | Type | What They Care About | How Decision Impacts Them | Approach |

Then provide:
- Recommended sequence of conversations
- Key messages for each stakeholder type
- Potential objections and responses
```

---

### People & Leadership Prompts

#### Prepare for Difficult Conversation

**Use when:** You need to have a challenging conversation

```text
You are an executive coach specializing in crucial conversations
and delivering difficult feedback with empathy and clarity.

I need to have a conversation with: [role/relationship]
Topic: [what needs to be discussed]
Why it's difficult: [what makes this hard]
Desired outcome: [what success looks like]
Their likely perspective: [how they might see it]
Our relationship currently: [good/strained/new]

Help me prepare by:
1. Asking clarifying questions about the situation
2. Helping me see their perspective
3. Crafting my key messages
4. Anticipating their reactions

Provide:
- Opening statement (how to start the conversation)
- 3-5 key points to make (in order)
- Phrases to avoid
- Phrases that will help
- How to handle likely objections
- How to end the conversation well
```

#### Develop Your Team's AI Skills

**Use when:** You want to help your team adopt AI

```text
You are a learning and development expert who specializes in
helping teams adopt new technologies with minimal disruption.

Team size: [number]
Current AI adoption level: [none/some experimenting/mixed]
Team's general attitude toward AI: [excited/skeptical/fearful]
My adoption level: [where you are]
Time available for training: [realistic hours/week]

Help me create an AI adoption plan for my team:
1. Ask questions to understand team dynamics and constraints
2. Identify early adopters who can champion the change
3. Design a phased rollout approach
4. Create "lightbulb moment" opportunities for skeptics
5. Address concerns about job security

Provide:
- Week 1-2 actions (quick wins)
- Month 1 goals and activities
- Month 2-3 expansion plan
- Success metrics to track
- Script for addressing AI fears
```

#### Raise Standards on Delegation

**Use when:** Direct reports come to you for answers they should find themselves

```text
You are an executive coach who helps leaders develop their teams
through powerful questions rather than providing answers.

My role: [your position]
The pattern: I have team members who come to me for answers to
things they should be able to handle themselves.
Example situation: [recent example]
How I typically respond: [what you usually do]

Help me develop coaching questions that:
1. Support the person while holding standards
2. Help them think through problems themselves
3. Build their confidence and capability
4. Aren't condescending or dismissive

Provide:
- 5-7 coaching questions I can use
- When to use each question (situational guidance)
- Phrases that support without rescuing
- How to respond if they push back
```

---

### Communication Prompts

#### Craft a Compelling Message

**Use when:** You need to communicate something important

```text
You are a communications expert who helps leaders craft clear,
compelling messages that drive action.

What I'm communicating: [topic]
Audience: [who will receive this]
Channel: [email/presentation/meeting/all-hands]
Goal: [what I want them to think/feel/do]
Key facts: [essential information to include]
Tone needed: [professional/urgent/inspiring/etc.]

Help me craft this message by:
1. Asking clarifying questions about the audience and context
2. Identifying the core message (one sentence)
3. Structuring the communication for impact
4. Suggesting how to handle questions/pushback

Provide:
- Core message (one sentence)
- Full draft of communication
- Alternative opening lines (3 options)
- Anticipated questions with suggested responses
```

#### Performance Review Follow-up

**Use when:** You need to document a performance conversation

```text
You are an HR communications expert who delivers difficult feedback
with empathy while maintaining clear accountability.

I just had a performance review with: [role]
Areas needing improvement: [specific issues]
What they're doing well: [strengths]
Our relationship: [good/strained/new]
Next review timeline: [when]

Help me write a follow-up email that:
1. Acknowledges their strengths
2. Clearly states performance expectations
3. Is empathetic and supportive in tone
4. Includes specific next steps
5. Offers support and resources

Keep under 300 words. Use "we" language where appropriate.
End with forward-looking support and a clear call to action.
```

---

### Prioritization & Time Management Prompts

#### Calendar Alignment Check

**Use when:** Your calendar doesn't reflect your priorities

```text
You are a productivity coach who helps leaders align their time
with their priorities through ruthless prioritization.

My top priorities this week are:
1. [priority 1]
2. [priority 2]
3. [priority 3]

My calendar currently has: [describe or paste screenshot]
Hours available for focused work: [realistic number]
Meetings I can't move: [which ones are fixed]

Help me audit my calendar:
1. Identify misalignment between priorities and time allocation
2. Suggest meetings to cancel, shorten, or delegate
3. Recommend time blocks for priority work

Provide:
- Alignment score (1-10)
- Meetings to reconsider (with specific recommendations)
- Suggested calendar restructure
- Draft messages for any cancellations/changes
- One habit to protect priority time going forward
```

#### Weekly Priority Setting

**Use when:** Starting your week and need to focus

```text
You are an executive coach who helps leaders maintain strategic
focus amid operational demands.

My monthly goals are:
1. [goal 1]
2. [goal 2]
3. [goal 3]

What happened last week: [brief summary]
Known commitments this week: [meetings, deadlines]
Energy level: [high/medium/low]
Potential distractions: [what might pull me off track]

Help me identify my priorities for this week:
1. What must get done to stay on track for monthly goals
2. What can wait
3. What I should delegate or decline
4. How to protect time for what matters

Provide:
- Top 3 priorities (specific and measurable)
- "Not this week" list (what to defer)
- Delegation candidates
- One boundary to set
- Daily focus suggestion (Mon-Fri)
```

#### Identify Your 20%

**Use when:** You want to maximize your unique contribution

```text
You are a strategic advisor who helps leaders identify their
highest-leverage activities through the Pareto principle.

My role: [position]
Company goals: [top 3]
My responsibilities: [key areas I own]
What I spend most time on: [current time allocation]
What energizes me: [activities I enjoy]
What drains me: [activities I dislike]

Interview me (one question at a time) to identify:
1. The 20% of company goals that drive 80% of results
2. The 20% of my role that creates 80% of value
3. My 20% strengths that drive 80% of my contribution
4. The intersection of these three areas

Provide:
- My "genius zone" (where all three overlap)
- Activities to do MORE of
- Activities to do LESS of (delegate/eliminate)
- Specific changes to make this week
```

---

### Technical & IT Leadership Prompts

#### Incident Post-Mortem

**Use when:** After an incident that needs review

```text
You are a site reliability expert who facilitates blameless
post-mortems focused on learning and systemic improvement.

Incident summary: [what happened]
Impact: [who/what was affected, for how long]
Severity: [critical/high/medium/low]
Resolution: [how it was fixed]

Interview me (one question at a time) to build a complete
post-mortem that covers:
1. Timeline of events
2. Root cause analysis (5 Whys)
3. What went well in our response
4. What could have gone better
5. Action items to prevent recurrence

Generate a post-mortem document with:
- Incident Summary (2-3 sentences)
- Timeline (timestamped events)
- Root Cause Analysis (5 Whys chain)
- What Went Well (3-5 points)
- What Could Improve (3-5 points)
- Action Items (with owners and due dates)
```

#### Technical Decision Documentation

**Use when:** Making a significant technical decision

```text
You are a solutions architect who documents technical decisions
clearly for both technical and non-technical stakeholders.

Decision needed: [what we're deciding]
Options being considered:
- Option A: [description]
- Option B: [description]

Constraints: [technical, budget, timeline, team skills]
Stakeholders: [who cares about this decision]

Help me create a decision document:
1. Ask clarifying questions about requirements and constraints
2. Analyze each option objectively
3. Make a recommendation with clear reasoning

Create an Architecture Decision Record (ADR):
- Context: [why this decision is needed]
- Options Considered: [with pros/cons for each]
- Decision: [what we're doing and why]
- Consequences: [what changes as a result]
- Risks: [what could go wrong and how to mitigate]
```

---

### Coding & Development Prompts

#### Code Review

**Use when:** You want feedback on code quality, bugs, or best practices

```text
You are a senior software engineer conducting a code review. You have
expertise in [language/framework] and prioritize code quality,
maintainability, and security.

Review this code:
[paste code]

Context:
- Purpose: [what this code does]
- Part of: [larger system/feature]
- Concerns: [specific areas you want reviewed]

Provide feedback on:
1. Bugs or potential errors
2. Security vulnerabilities
3. Performance issues
4. Code style and readability
5. Suggestions for improvement

Format as:
- **Critical** (must fix)
- **Important** (should fix)
- **Minor** (nice to have)
- **Positive** (what's done well)
```

#### Debug This Code

**Use when:** Code isn't working as expected

```text
You are a debugging expert who systematically identifies root causes.

The problem:
- What should happen: [expected behavior]
- What actually happens: [actual behavior]
- Error message (if any): [paste error]

Code:
[paste relevant code]

Environment:
- Language/version: [e.g., Python 3.11]
- Framework: [if applicable]
- OS: [if relevant]

What I've tried: [previous debugging attempts]

Help me debug by:
1. Identifying the most likely cause
2. Explaining why it's happening
3. Providing the fix with explanation
4. Suggesting how to prevent similar issues
```

#### Explain This Code

**Use when:** Understanding unfamiliar or complex code

```text
You are a patient programming instructor who explains code clearly
to developers of varying skill levels.

Explain this code:
[paste code]

My background: [beginner/intermediate/advanced in this language]
Specific questions: [anything particular you want explained]

Provide:
1. High-level summary (what does this code do overall?)
2. Line-by-line or block-by-block explanation
3. Key concepts used (name any patterns, algorithms, techniques)
4. Potential gotchas or non-obvious behavior
5. How I might modify it for [common use case]
```

#### Refactor This Code

**Use when:** You want to improve code quality without changing behavior

```text
You are a refactoring specialist who improves code while preserving
functionality. You follow [SOLID principles / clean code practices].

Current code:
[paste code]

What it does: [brief description]
Why refactor: [readability / performance / maintainability / testability]
Constraints: [must maintain API, performance requirements, etc.]

Refactor this code to:
1. [Primary goal - e.g., improve readability]
2. [Secondary goal - e.g., reduce duplication]

Provide:
- Refactored code
- Explanation of each change and why
- Any trade-offs made
- Tests I should add to verify behavior unchanged
```

#### Write Unit Tests

**Use when:** You need tests for existing code

```text
You are a test engineer who writes thorough, maintainable tests.

Code to test:
[paste code]

Testing framework: [pytest / jest / junit / etc.]
What this code does: [brief description]
Current coverage: [none / partial / specify what's covered]

Write tests that cover:
1. Happy path (expected inputs)
2. Edge cases (boundary conditions)
3. Error cases (invalid inputs, exceptions)
4. [Any specific scenarios you want tested]

For each test:
- Clear test name describing what's being tested
- Arrange/Act/Assert structure
- Comments explaining non-obvious test logic
```

#### Generate Code from Requirements

**Use when:** You need to implement a feature from a description

```text
You are a senior developer who writes clean, well-documented code.

Requirement: [describe what you need]

Technical context:
- Language: [language]
- Framework: [if applicable]
- Existing patterns to follow: [describe or paste example]
- Must integrate with: [existing code/APIs]

Constraints:
- [Performance requirements]
- [Security considerations]
- [Style guide / conventions to follow]

Provide:
1. Implementation with inline comments
2. Usage example
3. Any dependencies needed
4. Edge cases the calling code should handle
5. Tests (if requested)
```

---

### Individual Contributor Prompts

#### Weekly Manager Update

**Use when:** You need to communicate status to your manager

```text
You are a communication coach who helps individual contributors
communicate effectively with their managers.

My role: [position]
Manager's communication style: [brief/detailed/visual]
This week I worked on: [list activities]
Wins: [what went well]
Challenges: [what was hard]
Next week's focus: [planned work]
I need from my manager: [any asks]

Help me write a concise weekly update that:
1. Highlights progress on priorities
2. Surfaces any blockers early
3. Shows I'm thinking ahead

Generate update in this structure (under 200 words):
**Wins This Week** - [bullet points]
**In Progress** - [bullet points with % complete]
**Blockers/Needs** - [anything I need]
**Next Week** - [top priorities]
```

#### Career Conversation Prep

**Use when:** Preparing for a career development discussion

```text
You are a career coach who helps professionals navigate growth
conversations with clarity and confidence.

My current role: [position]
Time in role: [duration]
What I want: [promotion/new skills/different role/more scope]
My strengths: [what I'm good at]
My gaps: [where I need development]
Manager relationship: [good/developing/challenging]

Help me prepare for a career conversation:
1. Clarify what I actually want
2. Build my case with specific evidence
3. Anticipate questions and objections
4. Develop specific asks

Provide:
- Career goal statement (one clear sentence)
- Evidence of readiness (3-5 specific examples)
- Development areas to acknowledge
- Specific asks (what you want from manager)
- Questions to ask manager
```

---

### Wellness & Sustainability Prompts

#### Workload Assessment

**Use when:** You're feeling overwhelmed

```text
You are a productivity and wellness coach who helps leaders
sustain high performance without burning out.

My current workload feels: [overwhelming/heavy/manageable]
Hours I'm working: [typical week]
Sleep quality: [good/poor/variable]
Energy pattern: [when I'm at my best/worst]
What's causing stress: [main stressors]

Help me assess my workload:
1. Identify what's essential vs optional
2. Find quick wins to reduce load
3. Suggest boundaries to set
4. Create a sustainable path forward

Provide:
- Workload triage (must do / should do / could stop)
- 3 things to drop or delegate this week
- Boundaries to communicate
- Energy management suggestions
- Warning signs to watch for
- One self-care non-negotiable to protect
```

---

## References

### Primary Sources

1. **NetworkChuck. (2024).** "Mastering AI Prompting in 2025." *YouTube*. <https://youtu.be/pwWBcsxEoLk>
   - Source for: Core Principle, Four Pillars framework, Chain of Thought, Tree of Thought, Battle of the Bots, Meta-Skill concept, Skill Issue Mindset

2. **Woods, G. (2024).** *The AI-Driven Leader: Companion PDF*. AI Leadership. <https://www.aileadership.com>
   - Source for: Interview Pattern, Three Essential Personas, Role-Play & Simulation, strategic planning prompts, leadership prompts

3. **Miessler, D. (2024).** *Fabric: An open-source framework for augmenting humans using AI*. GitHub. <https://github.com/danielmiessler/fabric>
   - Source for: Prompt library structure, practical prompt patterns

### Official Documentation

1. **Anthropic. (2024).** "Prompt Engineering Guide." *Anthropic Documentation*. <https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering>
   - Source for: Claude-specific prompting techniques, system prompt usage

2. **OpenAI. (2024).** "Prompt Engineering." *OpenAI Platform Documentation*. <https://platform.openai.com/docs/guides/prompt-engineering>
   - Source for: GPT-specific techniques, few-shot prompting, format specification

3. **Google. (2024).** "Prompting Guide." *Google AI for Developers*. <https://ai.google.dev/gemini-api/docs/prompting-intro>
   - Source for: Gemini-specific patterns, multimodal prompting

### Academic & Research Sources

1. **Wei, J., et al. (2022).** "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models." *Advances in Neural Information Processing Systems, 35*. <https://arxiv.org/abs/2201.11903>
   - Source for: Chain of Thought technique, step-by-step reasoning

2. **Yao, S., et al. (2023).** "Tree of Thoughts: Deliberate Problem Solving with Large Language Models." *arXiv preprint*. <https://arxiv.org/abs/2305.10601>
   - Source for: Tree of Thought technique, multi-path exploration

3. **White, J., et al. (2023).** "A Prompt Pattern Catalog to Enhance Prompt Engineering with ChatGPT." *arXiv preprint*. <https://arxiv.org/abs/2302.11382>
   - Source for: Persona pattern, template structures, prompt patterns

### Expert Insights

1. **Thacker, J. (2024).** Various posts on prompt engineering. *X (Twitter)*. @rez0__
    - Source for: "Skill Issue Mindset" philosophy

2. **Mollick, E. (2024).** "Practical AI" Substack and research. Wharton School, University of Pennsylvania. <https://www.oneusefulthing.org/>
    - Source for: Extended thinking recommendation, practical AI applications

### Additional Resources

1. **Coursera. (2024).** "Prompt Engineering for ChatGPT." *Vanderbilt University*. <https://www.coursera.org/learn/prompt-engineering>
    - Supplementary learning resource

2. **Shieh, J. (2023).** "Best practices for prompt engineering with OpenAI API." *OpenAI Help Center*. <https://help.openai.com/en/articles/6654000-best-practices-for-prompt-engineering-with-openai-api>
    - Source for: API-specific best practices

---

## Footnotes
