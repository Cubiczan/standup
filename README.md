# Standup — AI-Native Daily Standup for Anna

> Anna AI-Native App Hackathon — [DoraHacks #2204](https://dorahacks.io/hackathon/2204/detail)

**One mention. Your whole day, summarized.**

`#standup` pulls your actual developer activity from GitHub, Slack, and Calendar, then synthesizes it into a structured standup — no typing, no forgetting, no fabricating.

## How It Works

```
User: #standup

Anna:
  1. Fetches your commits, PRs, issues from GitHub (built-in tool)
  2. Checks Slack for @mentions and urgent messages (built-in tool)
  3. Calls standup-tool Executa to analyze and structure the data
  4. Consults standup-playbook Skill for formatting guidelines
  5. Returns a clean standup

🎤 Standup — cubiczan — 2026-06-17

**What I Did**
• 2 feature commits (feat: add user authentication flow)
• 1 bugfix commit: fix: resolve login redirect loop
• 1 refactor commit: refactor: extract auth middleware
• Merged 1 PR: Fix login redirect

**What I'm Doing**
• PR: Add OAuth2 support (my-app)
• Issue: Setup CI pipeline

**Blockers**
• PR 'Add OAuth2 support' — no reviewers assigned
• Issue 'Update dependencies' is blocked

📊 5 commits · 1 PR merged · 1 PR open · 2 blocker(s)
```

## Architecture

Standup is an **Anna App** that bundles two Executas:

### 1. Tool Executa: `standup-tool` (Python)

A JSON-RPC 2.0 plugin (stdin/stdout) that does the heavy analysis the LLM can't do alone:

| Tool | What It Does |
|------|-------------|
| `format_standup` | Classifies commits by type (feature/bugfix/refactor/test/docs/merge/release/infra), summarizes PR activity, detects blockers from labels/comments/message patterns, produces structured standup |
| `detect_blockers` | Focused blocker analysis — scans PR comments, issue labels, and Slack messages for blocking signals, returns severity-ranked list |
| `weekly_digest` | Aggregates daily standups into weekly team digest with velocity metrics, top themes, daily breakdown table, and recommendations |
| `health_score` | Calculates team health score (0-100, letter grade A-D) based on consistency, blocker health, activity level, and velocity trend |

### 2. Skill Executa: `standup-playbook` (SKILL.md)

Declarative methodology that guides the agent on:
- Which data to gather and from which Anna built-in tools
- How to call standup-tool with the right parameters
- Output formatting rules (tone, length, special cases)
- Weekly digest and health report formats

### 3. Anna App Manifest

Bundles both Executas with a `system_prompt_addendum` that activates the standup workflow when the user types `#standup`.

## Blocker Detection

The tool automatically detects blockers from multiple signals:

- **PR labels**: `blocked`, `needs-review`, `waiting`, `hold`
- **PR comments**: "blocked on", "waiting on", "depends on", "can't merge"
- **PR review status**: `no_reviewers`, `changes_requested`
- **Issue labels**: same blocker labels
- **Slack messages**: "blocked", "waiting on you", "urgent", "asap"

All signals are deduplicated and severity-ranked.

## Tech Stack

- **Protocol**: JSON-RPC 2.0 over stdio (Anna Executa spec)
- **Language**: Python 3.10+ (zero dependencies — stdlib only)
- **Skill Format**: SKILL.md with frontmatter (Anna Skill spec)
- **App Format**: JSON manifest (Anna App spec v1)

## Running Locally

### Test the Tool Executa

```bash
# Describe (returns manifest)
echo '{"jsonrpc":"2.0","method":"describe","id":1}' | python3 executa/standup-tool/standup_tool.py

# Health check
echo '{"jsonrpc":"2.0","method":"health","id":0}' | python3 executa/standup-tool/standup_tool.py

# Format a standup
python3 -c "
import json, subprocess
req = {
    'jsonrpc': '2.0', 'id': 2, 'method': 'invoke',
    'params': {
        'tool': 'format_standup',
        'arguments': {
            'activities': {
                'commits': [
                    {'message': 'feat: add OAuth2 flow', 'repo': 'my-app', 'timestamp': '2026-06-17T10:00:00Z'},
                    {'message': 'fix: resolve redirect loop', 'repo': 'my-app', 'timestamp': '2026-06-17T11:00:00Z'}
                ],
                'pull_requests': [
                    {'title': 'Add OAuth2 support', 'status': 'open', 'repo': 'my-app', 'labels': ['blocked'], 'comments': [{'author': 'teammate', 'body': 'Blocked on auth server migration', 'timestamp': '2026-06-17T09:00:00Z'}], 'review_status': 'no_reviewers'},
                    {'title': 'Fix redirect loop', 'status': 'merged', 'repo': 'my-app', 'labels': ['bug'], 'comments': [], 'review_status': 'approved'}
                ],
                'issues': [
                    {'title': 'Setup CI pipeline', 'status': 'In Progress', 'labels': [], 'assignee': 'me'}
                ],
                'messages': [
                    {'channel': 'team-dev', 'text': '@you review PR #42 when you can?', 'timestamp': '2026-06-17T08:00:00Z', 'is_mention': True}
                ]
            },
            'team_config': {'username': 'developer', 'blocker_labels': ['blocked', 'needs-review', 'waiting']}
        }
    }
}
p = subprocess.run(['python3', 'executa/standup-tool/standup_tool.py'], input=json.dumps(req), capture_output=True, text=True)
print(json.dumps(json.loads(p.stdout), indent=2))
"
```

### Publishing to Anna

1. Register as a developer at [anna.partners/developer](https://anna.partners/developer)
2. Publish `standup-tool` as a Tool Executa (Python, local or binary distribution)
3. Publish `standup-playbook` as a Skill Executa (Markdown upload)
4. Create the `standup` Anna App using the manifest in `app/manifest.json`
5. Submit for review

## Project Structure

```
standup-anna/
├── executa/
│   └── standup-tool/
│       └── standup_tool.py          # Python JSON-RPC Executa (4 tools, zero deps)
├── skill/
│   └── standup-playbook/
│       └── SKILL.md                 # Declarative standup methodology
├── app/
│   └── manifest.json                # Anna App manifest (v1)
└── README.md
```

## Why This Matters

Every developer standup suffers from the same problems:

1. **Recall bias** — you forget half of what you did
2. **Vagueness** — "worked on some stuff" isn't useful
3. **Blocker hiding** — blockers go unmentioned until they escalate
4. **Time waste** — 15 minutes of meeting for 30 seconds of signal

Standup solves all four by pulling **real data** from the tools developers already use, running **actual analysis** (not just LLM summarization), and producing a **consistent format** every time.

## Hackathon

- **Event**: Anna AI-Native App Hackathon
- **Platform**: [DoraHacks #2204](https://dorahacks.io/hackathon/2204/detail)
- **Team**: Cubiczan
- **Category**: Productivity

---

Built with [Anna Developer Platform](https://anna.partners/developers) for the [Anna AI-Native App Hackathon](https://dorahacks.io/hackathon/2204/detail).