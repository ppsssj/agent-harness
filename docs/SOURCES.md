# Sources and adaptations

This document records material public research used in v0.1 and v0.2. The repository adapts high-level concepts only; its text and workflow wording were written independently.

| Project / source | URL | Concept studied | Adaptation in agent-harness | License considerations |
| --- | --- | --- | --- | --- |
| Anthropic Agent Skills | https://github.com/anthropics/skills | Self-contained skills, concise entry instruction, and supporting resources | Eight harness-neutral `SKILL.md` procedures with references and templates separated | Repository includes mixed licensing; no text, scripts, or assets copied |
| obra/superpowers | https://github.com/obra/superpowers | Composable skills, an initial operating contract, and a disciplined development workflow | Canonical `AGENTS.md` plus small workflow skills; no tool hooks or autonomous orchestration | MIT repository; no substantial text or code copied |
| Vercel Agent Skills | https://github.com/vercel-labs/agent-skills | Targeted agent procedures and practical verification focus | Scope-aware skills that delegate detailed policy to references/templates | Consult repository license before reuse; no text or code copied |
| Harness Skills | https://github.com/harness/harness-skills | Cross-agent skill packaging and structured task guidance | Vendor-neutral directory and minimal compatibility adapter | Consult repository license before reuse; no text or code copied |
| Awwwards | https://www.awwwards.com/ | Creative-web discovery | Router source for art direction and interaction research | Discovery only; do not copy designs or assets |
| Godly | https://godly.website/ | Creative-web discovery | Router source for visual language and interaction | Discovery only; do not copy designs or assets |
| CSS Design Awards | https://www.cssdesignawards.com/ | Creative-web discovery | Router source for experimental examples | Discovery only; do not copy designs or assets |
| SiteInspire | https://www.siteinspire.com/ | Curated site discovery | Router source for typography and editorial composition | Discovery only; do not copy designs or assets |
| Httpster | https://httpster.net/ | Curated web discovery | Router source for creative-web exploration | Discovery only; do not copy designs or assets |
| Land-book | https://land-book.com/ | Landing-page discovery | Router source for marketing hierarchy and sections | Discovery only; do not copy designs or assets |
| Lapa Ninja | https://www.lapa.ninja/ | Landing-page discovery | Router source for landing structures | Discovery only; do not copy designs or assets |
| One Page Love | https://onepagelove.com/ | Landing-page discovery | Router source for conversion-page patterns | Discovery only; do not copy designs or assets |
| Mobbin | https://mobbin.com/ | Product UI discovery | Router source for real product workflows and states | Discovery only; do not copy designs or assets |
| Refero | https://refero.design/ | Product UI discovery | Router source for SaaS and product patterns | Discovery only; do not copy designs or assets |
| SaaSFrame | https://www.saasframe.io/ | SaaS UI discovery | Router source for dashboard and settings patterns | Discovery only; do not copy designs or assets |

The four code-skill repositories were inspected in September 2026. Design discovery services are listed because they inform routing policy, not because a particular design from them was studied for this bootstrap.

## v0.2 official host research

All sources below were accessed on 2026-09-25. They inform [V0.2_INSTALLATION_DESIGN.md](V0.2_INSTALLATION_DESIGN.md); no host-specific configuration or implementation was copied.

| Source | URL | Concept studied | Design adaptation |
| --- | --- | --- | --- |
| OpenAI: Custom instructions with AGENTS.md | https://learn.chatgpt.com/docs/agent-configuration/agents-md | Codex global/project instruction discovery and session refresh | Keep project instructions local; do not install a global harness instruction adapter |
| OpenAI: Build skills | https://learn.chatgpt.com/docs/build-skills | Codex user/project skill locations, metadata discovery, symlink support | Generate self-contained, namespaced user-skill artifacts with concise metadata |
| OpenAI: Package your plugin | https://developers.openai.com/plugins/build/plugins | Plugin packaging and marketplace distribution | Defer plugin packaging until direct installation and cross-host behavior are validated |
| OpenAI: Windows sandbox | https://learn.chatgpt.com/docs/windows/windows-sandbox | Native Windows Codex support | Treat native Windows and WSL as separate installation environments |
| Anthropic: Explore the .claude directory | https://code.claude.com/docs/en/claude-directory | Claude global/project directory scopes and Windows home mapping | Use only user-scope skills; preserve host/project configuration |
| Anthropic: Extend Claude with skills | https://code.claude.com/docs/en/skills | Personal/project skill locations, self-contained support files, automatic relevance loading, symlink support | Use direct self-contained personal-skill copies; validate behavior in fresh sessions |
| Anthropic: How Claude remembers your project | https://code.claude.com/docs/en/memory | CLAUDE.md/AGENTS.md loading and precedence | Keep project instruction ownership separate from global harness skills |
| Anthropic: Plugins overview | https://code.claude.com/docs/en/plugins | Plugin scopes, marketplaces, and privilege implications | Defer plugin distribution and include it in a separate trust review |
| Anthropic: Set up Claude Code | https://docs.anthropic.com/en/docs/claude-code/getting-started | Windows host modes and restart/update behavior | Require host/environment detection and a new session after updates |
