# migrate-wizard Design Spec

## Summary

A single orchestrator skill that runs the full AI Studio to production migration workflow in one pass. Instead of manually invoking each skill (Step 0-5), the wizard auto-detects completed steps, asks all necessary configuration questions upfront, then executes remaining steps sequentially.

## Design Decisions

- **Orchestrator pattern (not self-contained):** The wizard reads each existing skill's SKILL.md and executes its instructions. No duplication of generation logic.
- **Upfront questions (not per-step confirmation):** All user choices are collected in one intake phase. Per-step confirmation is not needed because the plan is presented and approved before execution.
- **setup-dev-environment excluded from wizard:** It addresses Claude Code developer experience, not production migration. Recommended in the summary after completion.
- **途中参加 supported:** Auto-detect skips completed steps. Partially completed steps (e.g., `.git` exists but `.gitignore` incomplete) trigger partial execution.

## Phases

### Phase 1: Auto-Detect

Scan project files to determine each step's completion status.

| Step | Skill | Completed | Partial |
|:----:|-------|-----------|---------|
| 0 | analyze-and-document | `CLAUDE.md` exists and non-empty | — |
| 1 | export-from-ai-studio | `firebase-applet-config.json` apiKey is placeholder or absent | apiKey is plaintext -> incomplete |
| 2 | repo-initializer-google | `.git` + remote + `.gitignore` contains `.env` + README exists | `.git` exists but `.gitignore` insufficient -> partial |
| 3 | graduate / vercel-railway + ci-cd | `Dockerfile` + `infra/` or deploy config + `.github/workflows/` exist | Subset exists -> generate missing |
| 4 | monitoring-sentry-datadog | `sentry-sdk` or `dd-trace` in dependencies | — |
| 5 | security-hardening-gcp | Dedicated SA exists (via `gcloud`) + Secret Manager in use | — |

Additional detection:
- If `firebase-applet-config.json` contains `projectId` matching `gen-lang-client-*`, report the AI Studio project ID and surface it in Phase 2 Q2.
- Step 4, 5 remote checks: If `gcloud` is authenticated, check actual GCP state. If not, mark as "unconfirmed (recommend execution)".
- If AI Studio has already created GCP/Firebase infrastructure, detect and reuse it.

Output format:
```
=== Migration Status ===

✓ Step 0  analyze-and-document     — CLAUDE.md detected
✗ Step 1  export-from-ai-studio    — apiKey not sanitized
△ Step 2  repo-initializer-google  — .git exists / .gitignore incomplete
✗ Step 3  graduate-from-ai-studio  — Dockerfile missing
✗ Step 4  monitoring-sentry-datadog — not configured
✗ Step 5  security-hardening-gcp   — not configured

Detected: AI Studio project gen-lang-client-xxxxx

→ Steps 1, 2 (partial), 3, 4, 5 will be executed
```

### Phase 2: Intake Questions

Dynamically assemble questions based on incomplete steps. Present all in one message.

| # | Question | Options | Shown when |
|---|----------|---------|-----------|
| Q1 | Deploy target | (a) Cloud Run (b) Vercel (c) Railway | Step 3 incomplete |
| Q2 | Firebase project | (a) New project (b) Continue AI Studio's `gen-lang-client-*` | Step 3 incomplete. Show detected project ID if found. |
| Q3 | IaC tool | (a) Terraform (b) Pulumi (c) CLI scripts | Step 3 incomplete AND Q1 = Cloud Run |
| Q4 | GCP region | Default: asia-northeast1 | Step 3 incomplete AND Q1 = Cloud Run |
| Q5 | Monitoring tool | (a) Sentry (b) Datadog (c) Both (d) Skip | Step 4 incomplete |
| Q6 | Harden existing infra | (a) Execute (b) Skip | Step 5 incomplete AND Q2 = existing project |

Conditional rules:
- Completed steps -> no questions shown
- Q1 = Vercel/Railway -> Q3, Q4 hidden
- Q2 = new project -> Q6 hidden (new infra built secure from start)
- Q5 = skip -> Step 4 skipped entirely

### Phase 3: Plan Presentation

After answers, display full execution plan with files to be generated per step. User confirms with y/n before proceeding.

Format:
```
=== Migration Plan ===

Target: Cloud Run (asia-northeast1) / Terraform / Sentry
Firebase: New project

Step 1  export-from-ai-studio
        -> firebase-applet-config.json apiKey sanitize
        -> Code restructuring, .env.example generation

Step 2  repo-initializer-google (partial)
        -> .gitignore update
        -> README append

Step 3  graduate-from-ai-studio
        -> Dockerfile + .dockerignore
        -> infra/terraform/ (4 files)
        -> .github/workflows/deploy.yml
        -> firebase.json, .firebaserc, firestore.indexes.json
        -> .env.example update

Step 4  monitoring-sentry-datadog
        -> Sentry SDK install + init code
        -> Gemini API metrics

Step 5  security-hardening-gcp
        -> Dedicated SA + least-privilege IAM
        -> Secret Manager migration
        -> Firebase API Key referrer restriction
        -> Budget alert

Estimated files: ~15
Proceed? (y/n)
```

Deploy target variations:
- Cloud Run -> Step 3 uses `graduate-from-ai-studio`
- Vercel -> Step 3 uses `vercel-railway-deploy` + `ci-cd-github-actions`
- Railway -> Step 3 uses `vercel-railway-deploy` + `ci-cd-github-actions`

### Phase 4: Sequential Execution

Execute each step by reading the corresponding skill's SKILL.md and following its instructions with Phase 2 answers as context.

Key behaviors:
- Skip user interaction within each skill (answers already collected)
- Display progress per step with generated file list
- On file conflict: show diff and ask whether to merge (only mid-execution interaction)
- On error: display error, skip that step, continue to next. Report in summary.
- On `gcloud`/`firebase` CLI unavailable: skip remote operations, collect manual commands for summary.

Progress format:
```
[1/5] export-from-ai-studio ...
      ✓ firebase-applet-config.json apiKey -> placeholder
      ✓ Firebase init code -> env var injection
      ✓ .env.example generated

[2/5] repo-initializer-google (partial) ...
      ✓ .gitignore updated
      ✓ README appended
      — GitHub repo creation: skipped (exists)
...
```

### Phase 5: Summary & Next Steps

Display all generated/modified files grouped by step, followed by manual action items.

Manual action list is dynamic:
- Cloud Run -> GCP project creation + IaC init + WIF setup + GitHub Secrets
- Vercel -> `vercel login` + env setup
- Railway -> `railway login` + env setup
- Existing Firebase project -> skip project creation
- `gcloud` unauthenticated -> list SA creation / Secret Manager commands
- Monitoring skipped -> no Sentry/Datadog items
- apiKey in git history -> recommend key rotation

Always end with:
```
-> setup-dev-environment
   Claude Code development experience setup.
   Run: "setup dev environment"
```

## Skill Integration

The wizard reads and delegates to these skills:

| Step | Cloud Run path | Vercel/Railway path |
|------|---------------|-------------------|
| 0 | analyze-and-document | analyze-and-document |
| 1 | export-from-ai-studio | export-from-ai-studio |
| 2 | repo-initializer-google | repo-initializer-google |
| 3 | graduate-from-ai-studio | vercel-railway-deploy + ci-cd-github-actions |
| 4 | monitoring-sentry-datadog | monitoring-sentry-datadog |
| 5 | security-hardening-gcp | security-hardening-gcp |

## File Location

`skills/migrate-wizard/SKILL.md`

Registered in:
- `.claude-plugin/marketplace.json` (skills array)
- `README.md` (Skills table + Typical Workflow)
