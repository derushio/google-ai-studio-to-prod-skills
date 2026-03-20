---
name: repo-initializer-google
description: Use when creating a new GitHub repository for a Google AI / Gemini application, setting up project scaffolding with .gitignore, README, and Google Cloud-aware project structure
---

# Repo Initializer for Google AI Projects

## Overview

Initialize a GitHub repository with best-practice structure for Google AI / Gemini applications. Generates `.gitignore`, `README.md`, directory structure, and optional GCP configuration files.

## When to Use

- Starting a new project from an AI Studio export
- User says "リポジトリ作って", "set up a new repo", "init a project"
- After `export-from-ai-studio` has extracted code

**When NOT to use:** If the repo already exists and just needs deployment config.

## Quick Reference

### Generated Structure

```
project-name/
├── .gitignore
├── .env.example
├── README.md
├── src/
│   └── main.py (or index.ts)
├── tests/
├── Dockerfile
└── requirements.txt (or package.json)
```

## Implementation Steps

1. **Ask for project name and language** (Python or Node.js/TypeScript)
2. **Create GitHub repo** via `gh repo create`
3. **Generate `.gitignore`** — Include Google Cloud, Python/Node, and IDE patterns
4. **Generate `.env.example`** — `GEMINI_API_KEY=`, `GOOGLE_CLOUD_PROJECT=`
5. **Generate `README.md`** — Project name, setup instructions, env vars
6. **Create directory structure** — `src/`, `tests/`, root config files
7. **Initial commit and push**

## .gitignore Essentials

```gitignore
# Secrets
.env
*.key
service-account*.json

# Google Cloud
.gcloudignore

# Python
__pycache__/
*.pyc
.venv/

# Node
node_modules/
dist/

# IDE
.vscode/
.idea/
```

## Common Mistakes

- **Committing `.env`** — `.gitignore` must be in place before first commit
- **Missing `service-account*.json` in `.gitignore`** — GCP credentials must never be committed
- **No `.env.example`** — Other developers need to know which env vars are required
