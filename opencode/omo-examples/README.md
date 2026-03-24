# Oh My OpenCode (OMO) Agent Configuration Guide

## Overview

Oh My OpenCode (OMO) is a workflow plugin for OpenCode that replaces the default Plan/Build agent system with a specialized orchestration framework. This guide explains OMO's architecture, provides configuration examples for restoring missing Plan/Build agents, and offers migration paths between different agent configurations.

## Current State Analysis

Based on your configuration analysis:

- **OMO Plugin**: Installed and active (`oh-my-opencode` in `opencode.jsonc`)
- **OMO Configuration**: `~/.config/opencode/oh-my-opencode.jsonc` configures 11 specialized OMO agents
- **Missing Agents**: Plan and Build agents are intentionally replaced by OMO's Sisyphus orchestrator
- **Current Agents**: "fast" and "smart" agents are configured as subagents in `opencode.jsonc`

## OMO Agent Architecture

OMO introduces 11 specialized agents that replace OpenCode's default agent system:

1. **Sisyphus** - Primary orchestrator (replaces Plan/Build coordination)
2. **Hephaestus** - Build/execution specialist  
3. **Prometheus** - Monitoring/observability
4. **Oracle** - Research/analysis
5. **Librarian** - Documentation/code search
6. **Explore** - Exploration/discovery
7. **Multimodal-looker** - Visual/UI analysis
8. **Metis** - Strategy/wisdom
9. **Momus** - Critique/review
10. **Atlas** - Navigation/mapping
11. **Sisyphus-junior** - Lightweight orchestrator

### Key Configuration Properties

The `sisyphus_agent` configuration controls OMO's behavior:

```jsonc
"sisyphus_agent": {
  "disabled": false,           // Disable entire OMO orchestrator
  "default_builder_enabled": true,  // Enable default OpenCode-Builder
  "planner_enabled": true,     // Enable planner functionality
  "replace_plan": false        // Whether to replace the Plan agent
}
```

## Configuration Examples

Five example configurations are provided in this directory:

### 1. Default OMO Replacement (`01-default-omo-replacement.jsonc`)
- **Description**: OMO's default behavior - replaces Plan/Build with Sisyphus orchestration
- **Use Case**: Users who want full OMO workflow with specialized agents
- **Missing Agents**: Plan and Build agents are intentionally unavailable

### 2. OMO with Plan Agent (`02-omo-with-plan-agent.jsonc`)
- **Description**: Restores Plan agent while keeping OMO orchestration
- **Configuration**: `sisyphus_agent.planner_enabled: true`, `replace_plan: false`
- **Use Case**: Want OMO's execution but prefer traditional planning

### 3. OMO with Builder Agent (`03-omo-with-builder-agent.jsonc`)
- **Description**: Restores OpenCode-Builder for execution
- **Configuration**: `sisyphus_agent.default_builder_enabled: true`
- **Use Case**: OMO planning with customizable builder execution

### 4. Full Coexistence (`04-full-coexistence.jsonc`)
- **Description**: All agents available - OMO + Plan + Build + OpenCode-Builder
- **Use Case**: Maximum flexibility, testing, or transition period
- **Note**: May cause agent selection conflicts

### 5. Disable OMO, Default OpenCode (`05-disable-omo-default-opencode.jsonc`)
- **Description**: Disables OMO, restores default OpenCode agents
- **Configuration**: `sisyphus_agent.disabled: true`
- **Use Case**: Reverting from OMO to standard OpenCode

## Testing Configuration Changes

### Step 1: Backup Current Configuration
```bash
cp ~/.config/opencode/oh-my-opencode.jsonc ~/.config/opencode/oh-my-opencode.jsonc.backup
```

### Step 2: Apply New Configuration
```bash
# Example: Apply OMO with Plan agent configuration
cp omo-examples/02-omo-with-plan-agent.jsonc ~/.config/opencode/oh-my-opencode.jsonc
```

### Step 3: Restart OpenCode
Configuration changes require an OpenCode restart:
- Close current OpenCode session
- Start new OpenCode session

### Step 4: Verify Agent Availability
After restart, test agent availability:
- Use `/loop` command to test planning
- Use task delegation to test build execution
- Check agent list in OpenCode interface

### Step 5: Validate Functionality
Test specific workflows:
1. **Planning Test**: Request a complex task requiring decomposition
2. **Execution Test**: Request code implementation or fixes
3. **Integration Test**: Test multi-agent coordination

## Migration Paths

### From OMO to Default OpenCode
1. Use configuration #5 (`05-disable-omo-default-opencode.jsonc`)
2. Restart OpenCode
3. Verify Plan/Build agents are available
4. Remove OMO plugin from `opencode.jsonc` if desired

### From Default OpenCode to OMO
1. Install OMO plugin: Add `"oh-my-opencode"` to plugins in `opencode.jsonc`
2. Start with configuration #1 (default OMO replacement)
3. Gradually customize with other configurations as needed

### Hybrid Approach (OMO + Specific Default Agents)
1. Identify which default agents you need (Plan, Build, or both)
2. Use configurations #2, #3, or #4 based on needs
3. Monitor for agent selection conflicts
4. Adjust `sisyphus_agent` settings to fine-tune behavior

## Performance Considerations

### Token Usage
- **OMO Orchestration**: Additional tokens for agent coordination
- **Multiple Agents**: Each agent adds overhead for handoffs
- **Model Costs**: Different agents can use different models with varying costs

### Recommended Configurations

| Use Case | Recommended Configuration | Reasoning |
|----------|---------------------------|-----------|
| **Maximum Productivity** | #1 Default OMO Replacement | OMO's specialized agents optimized for workflow |
| **Planning Focus** | #2 OMO with Plan Agent | Traditional planning with OMO execution |
| **Execution Focus** | #3 OMO with Builder Agent | OMO planning with customizable builder |
| **Testing/Evaluation** | #4 Full Coexistence | Compare all agents before deciding |
| **Familiar Workflow** | #5 Disable OMO | Revert to known OpenCode behavior |

## Plugin Integration

### opencode-agent-tmux
OMO should work alongside `opencode-agent-tmux`. The tmux plugin provides terminal multiplexing capabilities that complement OMO's workflow.

### opencode-snip
`opencode-snip` provides snippet management. OMO agents can leverage snip for code reuse and templates.

### Configuration Conflicts
If experiencing conflicts:
1. Check plugin load order in `opencode.jsonc`
2. Ensure only one agent system manages Plan/Build responsibilities
3. Test with minimal plugin set, then add plugins incrementally

## Troubleshooting

### Common Issues

#### 1. Plan/Build Agents Still Missing After Configuration Change
- **Cause**: Configuration not loaded (OpenCode not restarted)
- **Solution**: Restart OpenCode completely
- **Verification**: Check `~/.config/opencode/oh-my-opencode.jsonc` matches intended configuration

#### 2. Agent Selection Conflicts
- **Cause**: Multiple agents competing for same role
- **Solution**: Use clearer role definitions or disable conflicting agents
- **Example**: If both `build` and `OpenCode-Builder` are active, disable one

#### 3. OMO Agents Not Responding
- **Cause**: `sisyphus_agent.disabled: true` or model configuration issues
- **Solution**: Verify `sisyphus_agent.disabled: false` and agent models are accessible

#### 4. Performance Degradation
- **Cause**: Too many active agents or expensive models
- **Solution**: Simplify configuration, use lighter models for certain agents

### Debug Steps
1. Check OpenCode logs for plugin loading errors
2. Validate JSONC syntax: `python3 -m json5.tool ~/.config/opencode/oh-my-opencode.jsonc`
3. Test with minimal configuration
4. Verify model availability and API keys

## References

- **OMO Repository**: https://github.com/code-yeongyu/oh-my-openagent
- **Schema URL**: https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/assets/oh-my-opencode.schema.json
- **OpenCode Documentation**: https://opencode.ai/docs/modes/
- **Research Findings**: OMO intentionally replaces Plan/Build agents; configuration allows restoration

## Next Steps

1. **Test configurations** in your environment using the testing methodology above
2. **Provide feedback** on which configuration works best for your workflow
3. **Customize further** based on specific needs (model selection, tool permissions, etc.)
4. **Monitor performance** and adjust configuration as needed

## Support

For OMO-specific issues, refer to the [OMO repository](https://github.com/code-yeongyu/oh-my-openagent). For OpenCode agent system questions, consult OpenCode documentation.
