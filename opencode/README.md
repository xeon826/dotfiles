## Usage Guide

### **Commands** - Invoke with `/command-name`

| Command | Usage |
|---------|-------|
| `/loop [N] <task>` | Autonomous verification loops. `AUTO 5 fix auth bug` = 5 loops without approval. `5 fix auth bug` = show checklist first, then 5 loops. |
| `/init [basic\|user]` | Generate AGENTS.md for your repo. `basic` = minimal, `user` = user-focused docs |
| `/howto` | Scan repo and generate user-focused documentation |
| `/refactor` | Refactor code with modularity, file headers, cleanup |
| `/npm <cmd>` | Optimized npm executor with error recovery |
| `/rmslop` | Remove "AI slop" (emojis, chatty preambles, excessive comments) |
| `/create-pack` | Bundle agents/commands/skills into shareable pack |
| `/create-plugin` | Guided plugin creation workflow |
| `/component-create` | Generate spec-compliant React component |
| `/component-review` | Audit a React component against specs |
| `/improve-run <task>` | Transform task → production prompt, execute immediately |
| `/improve-save <task>` | Transform task → production prompt, save as .md |

### **Agents** - Automatic dispatch via Task tool

Opencode dispatches these automatically based on task complexity:

| Agent | When it's used |
|-------|----------------|
| `fast` | Trivial edits, lint fixes, boilerplate, simple lookups |
| `smart` | Complex bugs, architectural refactoring, deep debugging |
| `subagent-orchestrator` | Multi-agent coordination, parallel execution |
| `opencode-configurator` | Config setup, plugin discovery, MCP installation |
| `security-reviewer` | Security audits (has 10 framework-specific skills) |
| `component-engineer` | Professional React component architecture |

### **Skills** - Referenced by agents, not invoked directly

Skills provide specialized knowledge to agents:

- **Configurator skills**: `plugin-installer`, `opencode-config`, `command-creator`, `skill-creator`, `agent-architect`, `mcp-installer`, `model-researcher`
- **Security skills**: `security-nextjs`, `security-express`, `security-django`, etc.
- **Engineering skills**: `component-engineering`, `prd-authoring`, `create-opencode-plugin`

### Recommended Config

Add to your `opencode.json` to use fast/smart instead of generic agent:

```json
"subagents": {
  "general": { "disable": true }
}
```

### Quick Start Examples

```
/loop AUTO 3 implement user authentication with JWT
/init basic
/create-plugin
/npm install lodash
/rmslop src/
```
