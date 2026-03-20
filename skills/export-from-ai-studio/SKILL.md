---
name: export-from-ai-studio
description: Use when extracting code from Google AI Studio exports, converting playground prompts to structured application code, or migrating AI Studio prototypes to a local development environment
---

# Export from AI Studio

## Overview

Google AI Studio exports code as a single script with hardcoded API keys and inline prompts. This skill extracts, restructures, and cleans up that code into a production-ready project structure.

## When to Use

- User has a Google AI Studio export (Python or Node.js)
- User wants to convert an AI Studio playground session to local code
- User pastes code with `genai.configure(api_key=...)` or similar patterns
- User says "AI Studioからコード持ってきて" or "export my AI Studio project"

**When NOT to use:** If the user already has structured code that just needs deployment, skip to `cloud-run-deploy`.

## Core Pattern

### Before (AI Studio Export)
```python
import google.generativeai as genai
genai.configure(api_key="AIzaSy...")
model = genai.GenerativeModel("gemini-2.0-flash")
response = model.generate_content("Translate this to French: Hello world")
print(response.text)
```

### After (Production-Ready)
```python
import os
from google import genai

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

def translate(text: str, target_lang: str) -> str:
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=f"Translate this to {target_lang}: {text}",
    )
    return response.text
```

## Quick Reference

| AI Studio Pattern | Production Replacement |
|-------------------|----------------------|
| Hardcoded API key | `os.environ["GEMINI_API_KEY"]` |
| `genai.configure()` | `genai.Client()` |
| Inline prompt strings | Parameterized functions |
| `print(response)` | Return values / structured output |
| Single script | Modular files with `main.py` entry point |
| No error handling | Try/catch with retry logic |

## Implementation Steps

1. **Identify the export type** — Python (`google-generativeai`) or Node.js (`@google/generative-ai`)
2. **Extract API key** — Replace hardcoded key with environment variable
3. **Migrate to latest SDK** — Use `google-genai` (Python) or latest `@google/genai` (Node.js)
4. **Extract functions** — Each `generate_content` call becomes a named function
5. **Add typing** — Type hints (Python) or TypeScript types (Node.js)
6. **Create `.env.example`** — Document required environment variables
7. **Add `requirements.txt` / `package.json`** — Pin dependency versions

## Common Mistakes

- **Leaving API key in code** — Always extract to env var immediately
- **Using deprecated SDK** — AI Studio may export `google-generativeai`, migrate to `google-genai`
- **Ignoring streaming** — If AI Studio used streaming, preserve that in the export
- **Losing system instructions** — AI Studio system prompts must be extracted and preserved
