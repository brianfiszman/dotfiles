---
name: dependency-research
description: Discover, rank, and verify third-party dependencies using GitHub popularity, default-branch activity, practical utility, and real free-versus-paid usage.
---

# Dependency research

## Purpose

Find the best-supported dependency for the user's actual workflow, rather than
starting from a familiar package or the first option remembered. This skill
applies to editor plugins, libraries, CLIs, SDKs, model providers, agents, and
hosted developer tools.

The user's default comparison priorities are:

1. **Popularity:** current GitHub stars, with the check date.
2. **Freshness:** the date of the latest commit on the repository's actual
   default branch, plus the latest release where applicable.
3. **Utility:** what the tool demonstrably does and how well it fits the exact
   requested workflow.
4. **Cost:** whether the complete working setup can be used for free, and
   under what limits or infrastructure requirements.

Compatibility, security, maintenance health, licensing, data handling, and
migration cost are important filters and caveats. Do not silently replace the
user's priorities with a different ranking.

## 1. Define the real job before searching

Translate the request into observable user workflows. For AI coding tools,
distinguish at least:

- Automatic inline/ghost-text completion while typing.
- Next-edit suggestions (larger predictive edits elsewhere in a file).
- User-invoked inline generation or refactoring.
- Chat and code explanation.
- Agentic multi-file changes, tool execution, and diff review.
- Frontends that connect Neovim to an external CLI agent.
- Local/self-hosted inference versus a hosted model service.

These are related but not interchangeable. A manual inline-edit action is not
an autocomplete engine. A chat UI that starts a CLI agent is not itself a model
provider. A plugin that renders suggestions may still depend on a separate,
paid inference service.

Record the existing behavior that must be replaced or improved. Do not narrow a
broad "AI tools" request to the first currently installed plugin's feature.

## 2. Discover candidates without anchoring

When asked to find the best option, especially when the user names a candidate
they already favor:

1. Start with generic category and workflow queries. Do not put the favored
   product's name in the initial search terms.
2. Search at least three angles: the broad category, the exact user workflow,
   and alternatives/rankings/catalogues for the ecosystem.
3. Use more than one discovery source where possible: web search, GitHub
   repository search, maintained ecosystem lists, package registries, and
   official documentation.
4. Build an initial pool of roughly 8–15 candidates before selecting a
   shortlist. Include projects discovered independently even when they were
   not previously known.
5. Record the exact queries and discovery sources. If the user requests a
   blind rediscovery, explicitly say whether the expected candidate emerged
   before its name was searched.

Do not treat one "awesome" list as exhaustive or authoritative. It may be stale,
biased, incomplete, or ranked using cached star counts. Use it to discover names,
then verify each candidate directly.

## 3. Verify popularity and actual upstream activity

For each serious candidate, inspect the canonical upstream repository:

- Read the live GitHub star count from the repository API and record the date.
- Read `default_branch`. Never assume it is named `master`.
- Fetch the latest commit from that exact branch (for example, the branch's
  `commits?per_page=1` endpoint) and record its commit date and subject.
- Record the latest tagged release and publication date when releases exist.
- Check whether the repository is archived, whether the service still works,
  and whether recent activity is code maintenance or only documentation/issues.

Do **not** use `updated_at` or repository `pushed_at` as a substitute for the
latest default-branch commit. Those timestamps can reflect issue, release, tag,
or non-default-branch activity. When they disagree, report the actual branch
commit and explain the discrepancy if relevant.

Stars are evidence of adoption and community attention, not proof of quality,
correctness, security, or suitability. Keep the raw count visible; do not invent
a combined popularity score.

## 4. Verify utility from documentation and implementation

Read the official README, usage documentation, installation instructions, and
relevant source code. Confirm:

- The exact interaction and features that are implemented today.
- Whether advertised features are stable, experimental, disabled by default,
  or dependent on another plugin/service.
- Which backend/provider is actually required.
- Whether the editor plugin is a complete tool, a UI wrapper, or only one layer
  in a multi-component system.
- Required editor version, runtimes, binaries, build steps, and external CLIs.
- How project context, diagnostics, files, and terminal/tool access are shared.

Use careful labels. For example, "inline edit" usually means a user sends a
prompt and reviews a buffer change; "inline completion" means the tool
automatically proposes text while the user types. Do not present one as a
replacement for the other without evidence.

## 5. Determine whether the complete setup is free

Always separate four cost layers:

1. **Plugin/package:** license and whether installation/use has a fee.
2. **Inference/backend:** local model, free API tier, paid API usage, or
   subscription-backed model access.
3. **Infrastructure:** CPU/GPU/RAM, storage, server hosting, Node/Rust/runtime
   dependencies, and maintenance.
4. **Limits and data terms:** free quotas, rate limits, model restrictions,
   expiry, queue/latency constraints, and whether submitted code may be used to
   improve the provider's models.

For each candidate, state the cheapest workable path:

- Local inference: usually no per-request fee, but requires compatible hardware,
  model downloads, electricity, and setup. "Free" is not "costless".
- Free hosted tier: name the quota, restrictions, and data policy from current
  official pricing/docs.
- Existing subscription: state which plan includes the service and whether the
  tool's use consumes plan limits.
- API billing: state that an API key alone does not make the service free.

Never infer "free" from an open-source license, a GitHub repository, a provider
name, or an installation guide. A free plugin can call a paid service; an open
model can require expensive hardware; a free hosted tier can have strict usage
and privacy limitations.

Use official current pricing and model-provider docs. Do not repeat cached
prices or quotas from third-party comparison sites without verifying them.

## 6. Apply health and fit filters

Check archive status, release/commit history, unresolved high-impact issues,
compatibility with the target editor/runtime, license, build complexity,
security posture, prompt/code data routing, permission defaults, and likely
migration/rollback effort.

A very popular project with stale default-branch code should remain visible in
the comparison, but its inactivity must be obvious. A newer project with fewer
stars can be a useful emerging option, but do not let recency alone outrank
utility and adoption.

## 7. Compare and recommend

Present a compact comparison with, at minimum:

- Project and canonical repository.
- Current stars and check date.
- Default branch and latest branch-commit date.
- Actual role / utility.
- Free path and what is still paid or resource-intensive.
- License and important runtime/dependency requirements.
- Material risks or feature limitations.

Organize candidates by workflow before ranking them. A good result can have
separate winners for all-in-one assistant, inline autocomplete, agent frontend,
and zero-subscription/local use.

Use the user's stated criteria as the primary ranking. Do not create opaque
weighted scores unless the user requests them; if a score is useful, show the
weights and underlying evidence. Explain why the leading candidate fits the
criteria and what it does not do well.

## 8. Evidence and handoff

Cite official repositories, default-branch commits/releases, feature docs, and
official pricing/privacy sources. Record the exact research date, queries, and
what could not be verified. Distinguish verified facts from inference and
unknowns.

For repository work, save durable research guidance in this skill and the
decision/outcome in an ADR or issue. Link this skill from `AGENTS.md` and the
relevant specialist skill. Update it when recurring research mistakes are found.

Research alone does not authorize installing, replacing, or bulk-updating
dependencies. Once a candidate is selected, create a separately scoped change
and test the real user workflow, including negative and regression paths.
