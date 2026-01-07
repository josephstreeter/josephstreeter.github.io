#!/usr/bin/env python3
"""Fix literal \n escape sequences in NLP documentation."""

import re

def fix_code_block_line(line):
    """Expand a single line containing literal \n into multiple lines."""
    # Only process if line has literal \n escapes
    if r'\n' not in line:
        return [line]
    
    # Split by literal \n, but preserve \n inside f-strings and regular strings
    # This is a simple approach - split all \n that aren't escaped further
    result = []
    parts = line.split(r'\n')
    
    for i, part in enumerate(parts):
        if part:  # Skip empty parts
            # Unescape string escape sequences
            part = part.replace(r'\\n', '\n')  # \\n -> \n (for f-strings)
            part = part.replace(r'\"', '"')     # Unescape quotes
            result.append(part + '\n')
        elif i < len(parts) - 1:  # Empty part means blank line
            result.append('\n')
    
    return result

def main():
    with open('docs/development/python/nlp/index.md', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    in_python_block = False
    
    while i < len(lines):
        line = lines[i]
        
        # Check for code block markers
        if line.strip() == '```python' or line.strip().startswith('```python\n'):
            in_python_block = True
            result.append(line)
        elif line.strip().startswith('```') and in_python_block:
            in_python_block = False
            result.append(line)
        # Handle ` ```pythoncode...` pattern (missing newline after fence)
        elif '```python' in line and len(line) > 20 and not line.strip() == '```python':
            # Split into fence and code
            idx = line.find('```python')
            if idx > 0:
                result.append(line[:idx].rstrip() + '\n')
            result.append('```python\n')
            rest = line[idx+9:]  # Skip ```python
            # Expand the rest
            expanded = fix_code_block_line(rest)
            result.extend(expanded)
            in_python_block = True
        # Handle compressed code blocks (very long lines with \n in Python blocks)
        elif in_python_block and r'\n' in line and len(line) > 150:
            expanded = fix_code_block_line(line)
            result.extend(expanded)
        else:
            result.append(line)
        
        i += 1
    
    # Write result
    with open('docs/development/python/nlp/index.md', 'w', encoding='utf-8') as f:
        f.writelines(result)
    
    print(f"Processed {len(lines)} lines -> {len(result)} lines")
    print(f"Expansion: {len(result) - len(lines)} additional lines")

if __name__ == '__main__':
    main()
