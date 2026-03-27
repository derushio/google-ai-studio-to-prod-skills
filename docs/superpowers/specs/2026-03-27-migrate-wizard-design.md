# migrate-wizard Design Spec

## Summary

A single orchestrator skill that runs the full AI Studio to production migration workflow in one pass. Instead of manually invoking each skill (Step 0-5), the wizard auto-detects completed steps, asks all necessary configuration questions upfront, then executes remaining steps sequentially.

## Design Decisions

- **Orchestrator pattern (not self-contained):** The wizard reads each existing skill's SKILL.md and executes its instructions. No duplication of generation logic.
- **Wizard absorbs all user interaction:** Each downstream skill has its own question/approval phases. The wizard collects all required inputs upfront and passes them as pre-supplied context when executing each skill. Skills' internal question phases are skipped.
- **Upfront questions (not per-step confirmation):** All user choices are collected in one intake phase. Per-step confirmation is not needed because the plan is presented and approved before execution.
- **Cloud Run only (v1):** Vercel/Railway paths are out of scope for the initial wizard. The `vercel-railway-deploy` SKILL.md lacks generation-level detail comparable to `graduate-from-ai-studio`. Users wanting Vercel/Railway are directed to those individual skills.
- **setup-dev-environment excluded from wizard:** It addresses Claude Code developer experience, not production migration. Recommended in the summary after completion.
- **Mid-run participation supported:** Auto-detect skips completed steps. Partially completed steps (e.g., `.git` exists but `.gitignore` incomplete) trigger partial execution.

## Required Inputs per Skill

The wizard absorbs these inputs so downstream skills run non-interactively:

| Skill | Inputs wizard collects | Inputs auto-detected |
|-------|----------------------|---------------------|
| export-from-ai-studio | (none — auto) | Language from package.json/requirements.txt |
| repo-initializer-google | Project name, language | `.git` existence, remote URL, `.gitignore` contents |
| graduate-from-ai-studio | Firebase project strategy, IaC tool, GCP region | Framework, runtime, port, build/start commands, collections, env vars |
| monitoring-sentry-datadog | Monitoring platform choice | Existing SDK in dependencies |
| security-hardening-gcp | Execute or skip (for existing infra) | SA existence, Secret Manager usage via `gcloud` |

## Phases

### Phase 0: Prerequisites Check

Before any detection or questions, verify the execution environment.

**Check:**
1. `git` — installed (required for all paths)
2. `gcloud` — installed and authenticated (`gcloud auth print-access-token`)
3. `firebase` — installed (`npx firebase-tools --version`)
4. `gh` — installed and authenticated (`gh auth status`)
5. `npm` or `pip` — available for SDK installation
6. `docker` — installed (for Dockerfile validation)
7. `terraform` / `pulumi` — checked but not required upfront (asked in Phase 2)

**Output:**
```
=== Environment Check ===

✓ git       installed
✓ gcloud    authenticated (project: my-project-123)
✓ firebase  installed (v13.x)
✓ gh        authenticated (user: TakuroFukamizu)
✓ npm       installed (v20.x)
△ docker    not found — Dockerfile will be generated but cannot validate locally
✗ terraform not found — will ask about IaC choice

→ Proceeding with available tools. Missing tools will result in
  manual commands listed in the summary.
```

**Behavior:**
- `git` missing → abort (hard requirement)
- `gcloud` unauthenticated → warn, continue. Remote operations (SA, Secret Manager, etc.) collected as manual commands in Summary.
- Other tools missing → warn, continue. Affected steps degrade gracefully.

### Phase 1: Auto-Detect

Scan project files to determine each step's completion status.

**Detection criteria — expected artifact sets (not just file existence):**

| Step | Skill | Complete | Partial | Checks |
|:----:|-------|----------|---------|--------|
| 0 | analyze-and-document | `CLAUDE.md` exists, non-empty, contains `## Architecture` or `## Tech Stack` section | — | File existence + section headers |
| 1 | export-from-ai-studio | `firebase-applet-config.json` apiKey is placeholder/absent AND `.env.example` exists with `GEMINI_API_KEY` | apiKey plaintext → incomplete | JSON parse + grep `.env.example` |
| 2 | repo-initializer-google | `.git` + remote + `.gitignore` contains `.env` and `service-account*.json` + README exists with setup section | `.git` exists but `.gitignore` missing entries → partial | Check each artifact individually |
| 3 | graduate-from-ai-studio | `Dockerfile` + (`infra/terraform/` or `infra/pulumi/` or `infra/scripts/`) + `.github/workflows/deploy.yml` + `firebase.json` | Subset exists → list missing | Check each artifact; verify Dockerfile matches detected runtime |
| 4 | monitoring-sentry-datadog | `@sentry/node` or `sentry-sdk` or `dd-trace` in dependencies AND init code exists in server entry point | SDK in deps but no init code → partial | package.json/requirements.txt + grep server file |
| 5 | security-hardening-gcp | If `gcloud` authenticated: dedicated SA (not default compute) + secrets in Secret Manager + API key restrictions. If not authenticated: mark as `unconfirmed` | SA exists but no API key restriction → partial | `gcloud iam service-accounts list`, `gcloud secrets list`, `gcloud services api-keys list` |

**AI Studio infrastructure detection:**
- Read `firebase-applet-config.json` → extract `projectId`
- If `projectId` matches `gen-lang-client-*` pattern → AI Studio managed project detected
- If `gcloud` authenticated: check existing Cloud Run services, Firestore databases, service accounts in that project
- Report findings to user in detection output and pre-fill Phase 2 Q2

**Output format:**
```
=== Migration Status ===

✓ Step 0  analyze-and-document     — CLAUDE.md detected (has Architecture, Tech Stack sections)
✗ Step 1  export-from-ai-studio    — apiKey not sanitized, .env.example missing
△ Step 2  repo-initializer-google  — .git exists / .gitignore missing .env entry
✗ Step 3  graduate-from-ai-studio  — Dockerfile missing, no IaC, no CI/CD
?  Step 4  monitoring-sentry-datadog — unconfirmed (gcloud not authenticated)
?  Step 5  security-hardening-gcp   — unconfirmed (gcloud not authenticated)

Detected: AI Studio project gen-lang-client-0a1b2c3d
  → Cloud Run service: ai-studio-app (asia-northeast1)
  → Firestore: (default) database

→ Steps 1, 2 (partial), 3, 4, 5 will be executed
```

### Phase 2: Intake Questions

Dynamically assemble questions based on **what downstream steps need as input**, not just which steps are incomplete.

| # | Question | Options | Shown when |
|---|----------|---------|-----------|
| Q1 | Firebase project strategy | (a) New project [recommended] (b) Continue AI Studio's `gen-lang-client-*` | Step 3 OR Step 5 incomplete. Show detected project ID if found. |
| Q2 | IaC tool | (a) Terraform [recommended] (b) Pulumi (TypeScript) (c) gcloud + firebase CLI scripts | Step 3 incomplete |
| Q3 | GCP region | Default: asia-northeast1 | Step 3 incomplete |
| Q4 | Monitoring tool | (a) Sentry (b) Datadog (c) Both (d) Skip | Step 4 incomplete or unconfirmed |
| Q5 | Security hardening | (a) Execute [recommended] (b) Skip | Step 5 incomplete or unconfirmed |
| Q6 | Project name (for repo) | Auto-detected from metadata.json or directory name | Step 2 incomplete AND no `.git` |

**Conditional rules:**
- Completed steps → no questions shown for that step
- Q1 = existing project AND Step 5 pending → wizard will harden existing infra
- Q1 = new project → Step 5 builds secure from scratch (no hardening of legacy)
- Q4 = skip → Step 4 skipped entirely
- Q5 = skip → Step 5 skipped entirely
- `gcloud` unauthenticated → Q1 still shown (affects IaC generation), but warn that remote operations become manual
- `terraform`/`pulumi` not installed → note in Q2 that selected tool needs installation before IaC can run

### Phase 3: Plan Presentation

After answers, display full execution plan. User confirms before proceeding.

```
=== Migration Plan ===

Target: Cloud Run (asia-northeast1) / Terraform / Sentry
Firebase: New project
Tools: gcloud ✓ / firebase ✓ / terraform ✗ (manual install needed)

Step 1  export-from-ai-studio
        → firebase-applet-config.json apiKey sanitize
        → Firebase init code → env var injection
        → .env.example generation

Step 2  repo-initializer-google (partial)
        → .gitignore: add .env, service-account*.json
        → README: append setup section

Step 3  graduate-from-ai-studio
        → Dockerfile + .dockerignore (Node.js multi-stage)
        → infra/terraform/ (main.tf, variables.tf, outputs.tf, terraform.tfvars.example)
        → .github/workflows/deploy.yml (WIF auth)
        → firebase.json + .firebaserc + firestore.indexes.json
        → .env.example update

Step 4  monitoring-sentry-datadog
        → npm install @sentry/node
        → Sentry init in server.ts
        → Gemini API latency/error metrics

Step 5  security-hardening-gcp
        → Dedicated SA + least-privilege IAM
        → Secret Manager migration (GEMINI_API_KEY, FIREBASE_API_KEY)
        → Firebase API Key referrer restriction
        → Budget alert

Estimated files: ~15
Proceed? (y/n)
```

### Phase 4: Sequential Execution

Execute each step by reading the corresponding skill's SKILL.md at `skills/<skill-name>/SKILL.md` and following its generation instructions. Phase 2 answers replace all interactive decision points within each skill.

**Execution protocol per skill:**
1. Read `skills/<skill-name>/SKILL.md`
2. Execute detection/analysis phase (Phase 1 of each skill) — use wizard's Phase 1 results as cache
3. Skip skill's question/approval phases — answers already collected
4. Execute generation phase with pre-supplied configuration
5. Report generated files

**Key behaviors:**
- Skip user interaction within each skill (answers already collected)
- Display progress per step with generated file list
- On file conflict: show diff and ask whether to merge (only mid-execution interaction allowed)
- On error: display error, skip that step, continue to next. Report in summary.
- On `gcloud`/`firebase` CLI unavailable: skip remote operations, collect manual commands for summary.

**Progress format:**
```
[1/5] export-from-ai-studio ...
      ✓ firebase-applet-config.json apiKey → placeholder
      ✓ src/lib/firebase.ts → env var injection
      ✓ .env.example generated

[2/5] repo-initializer-google (partial) ...
      ✓ .gitignore updated
      ✓ README.md appended
      — GitHub repo creation: skipped (exists)

[3/5] graduate-from-ai-studio ...
      ✓ Dockerfile + .dockerignore
      ✓ infra/terraform/ (4 files)
      ✓ .github/workflows/deploy.yml
      ✓ firebase.json + .firebaserc + firestore.indexes.json
      ✓ .env.example updated

[4/5] monitoring-sentry-datadog ...
      ✓ @sentry/node added to package.json
      ✓ Sentry init inserted in server.ts
      ✓ Gemini metrics helpers added

[5/5] security-hardening-gcp ...
      ⚠ gcloud unauthenticated — remote operations deferred
      ✓ Code-level security improvements applied
      → Manual commands collected for summary
```

### Phase 5: Summary & Next Steps

Display all generated/modified files grouped by step, followed by manual action items.

**Manual action list is dynamic based on:**
- `gcloud` auth status → if unauthenticated, list all GCP commands (SA creation, Secret Manager, API enablement)
- Q1 = new project → include `gcloud projects create` + `firebase projects:addfirebase`
- Q1 = existing project → skip project creation, include hardening commands
- IaC tool → include corresponding init command (`terraform init`, `pulumi up`, or `bash infra/scripts/setup.sh`)
- `terraform`/`pulumi` not installed → include install instructions
- Monitoring choice → Sentry DSN / Datadog API key setup in GitHub Secrets
- apiKey in git history → recommend key rotation with specific steps
- WIF setup → link to google-github-actions/auth documentation

**Always end with:**
```
=== Next: Development Environment ===

Claude Code の開発体験を整えるには:
→ 「開発環境セットアップして」 or 「setup dev environment」
  (setup-dev-environment skill: rules, hooks, permissions を .claude/ に構築)
```

## Skill Integration

The wizard reads and delegates to these skills (Cloud Run path only in v1):

| Step | Skill | SKILL.md path |
|------|-------|--------------|
| 0 | analyze-and-document | `skills/analyze-and-document/SKILL.md` |
| 1 | export-from-ai-studio | `skills/export-from-ai-studio/SKILL.md` |
| 2 | repo-initializer-google | `skills/repo-initializer-google/SKILL.md` |
| 3 | graduate-from-ai-studio | `skills/graduate-from-ai-studio/SKILL.md` |
| 4 | monitoring-sentry-datadog | `skills/monitoring-sentry-datadog/SKILL.md` |
| 5 | security-hardening-gcp | `skills/security-hardening-gcp/SKILL.md` |

**Future (v2):** Add Vercel/Railway path when `vercel-railway-deploy` SKILL.md has generation-level detail comparable to `graduate-from-ai-studio`.

## File Location

`skills/migrate-wizard/SKILL.md`

Registered in:
- `.claude-plugin/marketplace.json` (skills array)
- `README.md` (Skills table + Typical Workflow)
