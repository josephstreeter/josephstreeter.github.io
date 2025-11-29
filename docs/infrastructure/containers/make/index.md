---
title: "Make - Comprehensive Guide"
description: "Complete guide to GNU Make: syntax, rules, variables, patterns, functions, and best practices for build automation."
ms.topic: reference
ms.date: 2025-11-29
---

Make is a build automation tool that automatically builds executable programs and libraries from source code by reading files called Makefiles which specify how to derive the target program.

## Quick Start

- Make uses Makefiles to define build rules and dependencies
- Rules specify targets, prerequisites (dependencies), and recipes (commands)
- Make only rebuilds targets when dependencies have changed (timestamp-based)
- Tab character (not spaces) required before recipe commands
- Variables and functions provide powerful text manipulation

## Basic Makefile Structure

A Makefile consists of rules with this syntax:

```makefile
target: prerequisites
 recipe
 recipe
```

### Simple Example

```makefile
# Build a C program
program: main.o utils.o
 gcc -o program main.o utils.o

main.o: main.c utils.h
 gcc -c main.c

utils.o: utils.c utils.h
 gcc -c utils.c

clean:
 rm -f program *.o
```

Run with:

```bash
make          # Builds default target (first target)
make program  # Builds specific target
make clean    # Removes built files
```

## Make Rules

### Rule Syntax

```makefile
targets: prerequisites
 recipe
 ...
```

- **Targets:** Files to be generated (or phony targets like 'clean')
- **Prerequisites:** Files that must exist/be up-to-date before building target
- **Recipe:** Shell commands to build the target (must be indented with TAB)

### Multiple Targets

```makefile
# Multiple targets with same recipe
file1.o file2.o: common.h
 gcc -c $*.c

# Equivalent to:
file1.o: common.h
 gcc -c file1.c

file2.o: common.h
 gcc -c file2.c
```

### Phony Targets

Targets that don't represent files:

```makefile
.PHONY: clean all install test

all: program1 program2

clean:
 rm -f *.o program1 program2

install: all
 cp program1 /usr/local/bin/
 cp program2 /usr/local/bin/

test: all
 ./run-tests.sh
```

## Variables

### Defining Variables

```makefile
# Simple assignment (evaluated when used)
CC = gcc
CFLAGS = -Wall -O2

# Immediate assignment (evaluated when defined)
NOW := $(shell date)

# Append to variable
CFLAGS += -g

# Conditional assignment (only if not already set)
CC ?= gcc

# Using variables
program: main.o
 $(CC) $(CFLAGS) -o program main.o
```

### Built-in Variables

Common automatic variables:

```makefile
# $@ - Target name
# $< - First prerequisite
# $^ - All prerequisites
# $? - Prerequisites newer than target
# $* - Stem of pattern rule match

example: file1.c file2.c file3.c
 gcc -o $@ $^
 # Expands to: gcc -o example file1.c file2.c file3.c

%.o: %.c
 gcc -c $< -o $@
 # For main.o: gcc -c main.c -o main.o
```

### Standard Variables

```makefile
# Compiler and tools
CC = gcc           # C compiler
CXX = g++         # C++ compiler
LD = ld           # Linker
AR = ar           # Archiver
RM = rm -f        # Remove command

# Flags
CFLAGS = -Wall -O2
CXXFLAGS = -Wall -O2 -std=c++17
LDFLAGS = -L/usr/local/lib
LDLIBS = -lm -lpthread

# Directories
SRCDIR = src
OBJDIR = obj
BINDIR = bin
INCDIR = include

# Common pattern
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
```

## Pattern Rules

### Basic Patterns

```makefile
# Pattern rule: %.o depends on %.c
%.o: %.c
 $(CC) $(CFLAGS) -c $< -o $@

# Pattern with subdirectories
obj/%.o: src/%.c
 @mkdir -p obj
 $(CC) $(CFLAGS) -c $< -o $@

# Multiple patterns
%.pdf: %.tex
 pdflatex $<

%.html: %.md
 pandoc $< -o $@
```

### Static Pattern Rules

```makefile
OBJECTS = main.o utils.o helper.o

# Static pattern: $(targets): target-pattern: prereq-patterns
$(OBJECTS): %.o: %.c
 $(CC) -c $(CFLAGS) $< -o $@

# Equivalent to writing separate rules for each object file
```

## Functions

### Text Functions

```makefile
# $(subst from,to,text) - Substitute text
SOURCES = main.c utils.c
OBJECTS = $(subst .c,.o,$(SOURCES))  # main.o utils.o

# $(patsubst pattern,replacement,text) - Pattern substitution
OBJECTS = $(patsubst %.c,%.o,$(SOURCES))

# $(strip text) - Remove leading/trailing whitespace
TRIMMED = $(strip   hello   world   )

# $(findstring find,text) - Find substring
HAS_MAIN = $(findstring main,$(SOURCES))

# $(filter pattern,text) - Keep matching words
C_FILES = $(filter %.c,$(FILES))

# $(filter-out pattern,text) - Remove matching words
NOT_MAIN = $(filter-out main.c,$(SOURCES))

# $(sort list) - Sort and remove duplicates
SORTED = $(sort c b a c b)  # a b c

# $(word n,text) - Get nth word (1-indexed)
FIRST = $(word 1,$(SOURCES))

# $(words text) - Count words
COUNT = $(words $(SOURCES))

# $(firstword text) - Get first word
FIRST = $(firstword $(SOURCES))

# $(lastword text) - Get last word
LAST = $(lastword $(SOURCES))
```

### File Functions

```makefile
# $(wildcard pattern) - List files matching pattern
SOURCES = $(wildcard src/*.c)
HEADERS = $(wildcard include/*.h)

# $(dir names) - Extract directory part
DIRS = $(dir src/main.c include/utils.h)  # src/ include/

# $(notdir names) - Extract filename part
FILES = $(notdir src/main.c src/utils.c)  # main.c utils.c

# $(suffix names) - Extract file extension
EXTS = $(suffix main.c utils.o script.py)  # .c .o .py

# $(basename names) - Remove extension
BASES = $(basename main.c utils.o)  # main utils

# $(addsuffix suffix,names) - Add suffix
OBJECTS = $(addsuffix .o,main utils)  # main.o utils.o

# $(addprefix prefix,names) - Add prefix
PATHS = $(addprefix src/,main.c utils.c)  # src/main.c src/utils.c

# $(join list1,list2) - Join lists element by element
JOINED = $(join src/ obj/,main.c utils.c)  # src/main.c obj/utils.c

# $(realpath names) - Get absolute path
ABS = $(realpath ../src)

# $(abspath names) - Get absolute path (doesn't require file to exist)
ABS = $(abspath ../src)
```

### Conditional Functions

```makefile
# $(if condition,then-part,else-part)
DEBUG = 1
CFLAGS = $(if $(DEBUG),-g -O0,-O2)

# $(or condition1,condition2,...)
COMPILER = $(or $(CC),gcc)

# $(and condition1,condition2,...)
BUILD = $(and $(SOURCES),$(COMPILER))
```

### Shell Function

```makefile
# $(shell command) - Execute shell command
DATE = $(shell date +%Y-%m-%d)
GIT_HASH = $(shell git rev-parse --short HEAD)
FILES = $(shell find src -name '*.c')

# Warning: shell is executed every time variable is referenced
# Use := for immediate assignment to execute once
NOW := $(shell date)
```

### Custom Functions

```makefile
# $(call variable,param1,param2,...)
# Define function with $(1), $(2), etc. for parameters

# Function to compile a source file
define COMPILE_C
 @echo "Compiling $(1)..."
 $(CC) $(CFLAGS) -c $(1) -o $(2)
endef

# Function to create directory
define MKDIR
 @mkdir -p $(1)
endef

# Usage
obj/main.o: src/main.c
 $(call MKDIR,obj)
 $(call COMPILE_C,$<,$@)
```

## Conditionals

### Conditional Syntax

```makefile
# ifdef / ifndef
ifdef DEBUG
CFLAGS += -g
else
CFLAGS += -O2
endif

ifndef VERBOSE
.SILENT:
endif

# ifeq / ifneq
ifeq ($(CC),gcc)
CFLAGS += -Wall
endif

ifneq ($(OS),Windows_NT)
RM = rm -f
else
RM = del
endif

# Comparing variables
ifeq ($(strip $(SOURCES)),)
$(error No source files found)
endif
```

### Runtime Conditionals

```makefile
# Using shell test
check-file:
 @test -f config.ini || echo "Warning: config.ini not found"

# Conditional execution
all:
 @if [ "$(DEBUG)" = "1" ]; then \
  echo "Debug build"; \
 else \
  echo "Release build"; \
 fi
```

## Advanced Patterns

### Automatic Dependency Generation

```makefile
# Generate .d files with header dependencies
DEPDIR = .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d

%.o: %.c $(DEPDIR)/%.d | $(DEPDIR)
 $(CC) $(DEPFLAGS) $(CFLAGS) -c $< -o $@

$(DEPDIR):
 @mkdir -p $@

# Include generated dependency files
SOURCES = main.c utils.c
DEPS = $(SOURCES:%.c=$(DEPDIR)/%.d)
-include $(DEPS)
```

### Order-Only Prerequisites

Prerequisites that don't affect target rebuild if only their timestamp changes:

```makefile
# Normal prerequisite: rebuilds if directory timestamp changes
# Order-only (after |): only ensures directory exists
obj/main.o: src/main.c | obj
 $(CC) -c $< -o $@

obj:
 mkdir -p obj
```

### Multi-line Variables

```makefile
define HELP_TEXT
Usage: make [target]

Targets:
  all      - Build everything
  clean    - Remove built files
  install  - Install to system
  test     - Run tests
endef

help:
 @echo "$(HELP_TEXT)"

# Alternative: export for use in shell
export HELP_TEXT
help2:
 @echo "$$HELP_TEXT"
```

## Complete Project Example

### C Project Makefile

```makefile
# Project configuration
PROJECT = myapp
VERSION = 1.0.0

# Directories
SRCDIR = src
INCDIR = include
OBJDIR = obj
BINDIR = bin
DEPDIR = .deps

# Compiler settings
CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -I$(INCDIR)
LDFLAGS = 
LDLIBS = -lm -lpthread

# Debug/Release
DEBUG ?= 0
ifeq ($(DEBUG),1)
    CFLAGS += -g -O0 -DDEBUG
else
    CFLAGS += -O2 -DNDEBUG
endif

# Find sources
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
DEPENDS = $(SOURCES:$(SRCDIR)/%.c=$(DEPDIR)/%.d)
TARGET = $(BINDIR)/$(PROJECT)

# Default target
.PHONY: all
all: $(TARGET)

# Link
$(TARGET): $(OBJECTS) | $(BINDIR)
 $(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@
 @echo "Build complete: $@"

# Compile with automatic dependencies
$(OBJDIR)/%.o: $(SRCDIR)/%.c $(DEPDIR)/%.d | $(OBJDIR) $(DEPDIR)
 $(CC) -MT $@ -MMD -MP -MF $(DEPDIR)/$*.d $(CFLAGS) -c $< -o $@

# Create directories
$(BINDIR) $(OBJDIR) $(DEPDIR):
 @mkdir -p $@

# Include dependencies
-include $(DEPENDS)

# Phony targets
.PHONY: clean install test run help

clean:
 rm -rf $(OBJDIR) $(BINDIR) $(DEPDIR)

install: $(TARGET)
 install -m 755 $(TARGET) /usr/local/bin/

test: $(TARGET)
 @echo "Running tests..."
 @./tests/run-tests.sh

run: $(TARGET)
 @$(TARGET)

help:
 @echo "Makefile for $(PROJECT) $(VERSION)"
 @echo ""
 @echo "Targets:"
 @echo "  all      - Build the project (default)"
 @echo "  clean    - Remove all build artifacts"
 @echo "  install  - Install to /usr/local/bin"
 @echo "  test     - Run test suite"
 @echo "  run      - Build and run the program"
 @echo "  help     - Show this help message"
 @echo ""
 @echo "Options:"
 @echo "  DEBUG=1  - Build with debug symbols"
```

### Python Project Makefile

```makefile
PYTHON = python3
PIP = $(PYTHON) -m pip
VENV = venv
ACTIVATE = . $(VENV)/bin/activate

.PHONY: all init test lint format clean help

all: init test

init: $(VENV)
 $(ACTIVATE) && $(PIP) install -r requirements.txt
 $(ACTIVATE) && $(PIP) install -e .

$(VENV):
 $(PYTHON) -m venv $(VENV)

test:
 $(ACTIVATE) && pytest tests/ -v --cov=src

lint:
 $(ACTIVATE) && pylint src/
 $(ACTIVATE) && flake8 src/

format:
 $(ACTIVATE) && black src/ tests/
 $(ACTIVATE) && isort src/ tests/

clean:
 rm -rf $(VENV)
 rm -rf .pytest_cache
 rm -rf .coverage
 find . -type d -name __pycache__ -exec rm -rf {} +
 find . -type f -name '*.pyc' -delete

help:
 @echo "Python Project Makefile"
 @echo ""
 @echo "Targets:"
 @echo "  init    - Create venv and install dependencies"
 @echo "  test    - Run test suite"
 @echo "  lint    - Run linters"
 @echo "  format  - Format code with black and isort"
 @echo "  clean   - Remove virtual environment and cache"
```

### Docker Project Makefile

```makefile
IMAGE_NAME = myapp
IMAGE_TAG = latest
CONTAINER_NAME = myapp-container
REGISTRY = docker.io/username

.PHONY: build run stop clean push pull logs shell test

build:
 docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run: build
 docker run -d \
  --name $(CONTAINER_NAME) \
  -p 8080:8080 \
  $(IMAGE_NAME):$(IMAGE_TAG)

stop:
 docker stop $(CONTAINER_NAME) || true
 docker rm $(CONTAINER_NAME) || true

clean: stop
 docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true

push: build
 docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
 docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

pull:
 docker pull $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

logs:
 docker logs -f $(CONTAINER_NAME)

shell:
 docker exec -it $(CONTAINER_NAME) /bin/bash

test: build
 docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) pytest
```

## Best Practices

### Organization

```makefile
# 1. Configuration at top
PROJECT = myapp
VERSION = 1.0

# 2. Tool variables
CC = gcc
CFLAGS = -Wall

# 3. Directory variables
SRCDIR = src
OBJDIR = obj

# 4. File lists
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:%.c=%.o)

# 5. Default target first
all: $(PROJECT)

# 6. Real targets
$(PROJECT): $(OBJECTS)
 $(CC) -o $@ $^

# 7. Pattern rules
%.o: %.c
 $(CC) $(CFLAGS) -c $< -o $@

# 8. Phony targets at end
.PHONY: all clean install
```

### Silent Output

```makefile
# Suppress command echoing with @
all:
 @echo "Building..."
 @$(CC) -o program main.c

# Or use .SILENT target
.SILENT:
all:
 echo "Building..."
 $(CC) -o program main.c

# Verbose flag
V ?= 0
ifeq ($(V),0)
    Q = @
else
    Q = 
endif

all:
 $(Q)echo "Building..."
 $(Q)$(CC) -o program main.c
```

### Error Handling

```makefile
# Stop on error (default behavior)
.DELETE_ON_ERROR:  # Delete target if recipe fails

# Ignore errors
clean:
 -rm -f *.o  # - prefix ignores error

# Check prerequisites exist
check-tools:
 @which gcc > /dev/null || (echo "gcc not found" && exit 1)
 @which make > /dev/null || (echo "make not found" && exit 1)

# Error messages
ifndef CC
$(error CC is not defined)
endif

ifeq ($(strip $(SOURCES)),)
$(warning No source files found)
endif
```

### Performance

```makefile
# Use := instead of = for variables that don't change
SOURCES := $(wildcard src/*.c)  # Execute once
OBJECTS := $(SOURCES:.c=.o)     # Expand once

# Avoid excessive shell calls
# Bad:
FILES = $(shell find . -name '*.c')  # Executed every reference

# Good:
FILES := $(shell find . -name '*.c')  # Executed once

# Parallel builds
# make -j4    # Use 4 cores
# make -j     # Use all cores

# Optimize for parallel builds
.PHONY: parallel-safe
parallel-safe: obj1 obj2 obj3  # Can build in parallel
```

### Platform Independence

```makefile
# Detect OS
UNAME := $(shell uname -s)

ifeq ($(UNAME),Linux)
    OS = linux
    EXE = 
    RM = rm -f
endif

ifeq ($(UNAME),Darwin)
    OS = macos
    EXE = 
    RM = rm -f
endif

ifneq (,$(findstring MINGW,$(UNAME)))
    OS = windows
    EXE = .exe
    RM = del
endif

TARGET = program$(EXE)
```

## Common Recipes

### Colorized Output

```makefile
# Colors
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m  # No Color

all:
 @echo "$(GREEN)Building...$(NC)"
 @$(CC) -o program main.c
 @echo "$(GREEN)Build complete!$(NC)"

error:
 @echo "$(RED)Error: Something went wrong$(NC)"
```

### Progress Indicators

```makefile
SOURCES = file1.c file2.c file3.c file4.c file5.c
TOTAL := $(words $(SOURCES))
CURRENT = 0

%.o: %.c
 $(eval CURRENT := $(shell echo $$(($(CURRENT)+1))))
 @echo "[$(CURRENT)/$(TOTAL)] Compiling $<..."
 @$(CC) -c $< -o $@
```

### Self-Documenting Makefile

```makefile
.PHONY: help
help: ## Show this help message
 @echo "Usage: make [target]"
 @echo ""
 @echo "Targets:"
 @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
  awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

all: ## Build everything
 @echo "Building..."

clean: ## Remove build artifacts
 @echo "Cleaning..."

test: ## Run tests
 @echo "Testing..."
```

## Troubleshooting

### Common Issues

**Missing TAB character:**

```makefile
# Wrong (spaces instead of TAB)
target:
    echo "This will fail"

# Correct (TAB character)
target:
 echo "This works"
```

**Check for TAB:**

```bash
cat -A Makefile  # Shows TAB as ^I
```

**Debugging:**

```bash
# Print variable values
make --print-data-base

# Dry run (show commands without executing)
make -n

# Debug mode
make -d

# Print variables
make print-SOURCES
# With this rule:
print-%:
 @echo $* = $($*)
```

**Circular Dependencies:**

```makefile
# Wrong
a: b
b: a

# Make will error: "Circular a <- b dependency dropped"
```

### Common Errors

```makefile
# Error: target pattern contains no '%'
# Fix: Use correct pattern syntax
%.o: %.c

# Error: missing separator
# Fix: Use TAB not spaces before recipe

# Warning: overriding recipe for target
# Fix: Don't define same target twice (unless intentional)

# Error: No rule to make target
# Fix: Check prerequisite spelling and existence
```

## Quick Reference

### Command Line Options

| Option | Description |
|--------|-------------|
| `make` | Build default target |
| `make target` | Build specific target |
| `make -f file` | Use specific makefile |
| `make -n` | Dry run (show commands) |
| `make -s` | Silent mode |
| `make -j4` | Parallel build (4 jobs) |
| `make -k` | Keep going on errors |
| `make -B` | Force rebuild all |
| `make -d` | Debug mode |
| `make VAR=value` | Set variable |

### Special Targets

| Target | Purpose |
|--------|---------|
| `.PHONY` | Declare phony targets |
| `.SILENT` | Suppress command echoing |
| `.DELETE_ON_ERROR` | Delete target on error |
| `.PRECIOUS` | Don't delete intermediate files |
| `.DEFAULT_GOAL` | Set default target |
| `.SUFFIXES` | Define suffix rules |

### Automatic Variables

| Variable | Meaning |
|----------|---------|
| `$@` | Target name |
| `$<` | First prerequisite |
| `$^` | All prerequisites |
| `$?` | Prerequisites newer than target |
| `$*` | Stem of pattern match |
| `$(@D)` | Directory part of target |
| `$(@F)` | File part of target |
| `$(<D)` | Directory of first prerequisite |
| `$(<F)` | File of first prerequisite |

## Further Reading

- [GNU Make Manual](https://www.gnu.org/software/make/manual/) - Official comprehensive documentation
- [make man page](https://man7.org/linux/man-pages/man1/make.1.html) - Command line reference
- [Managing Projects with GNU Make](http://oreilly.com/catalog/make3/) - O'Reilly book
- [Makefile Tutorial](https://makefiletutorial.com/) - Interactive tutorial
- [Recursive Make Considered Harmful](http://aegis.sourceforge.net/auug97.pdf) - Classic paper on make best practices
