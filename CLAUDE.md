# Claude Project Memory: Dualio

Read `AGENTS.md` first. It is the shared source of truth for all coding agents in this repository.

## Project Summary

Dualio is a Flutter mobile app for Android first and iOS second. It is an AI-first semantic memory inbox for saved links, screenshots, photos, and text.

The current stage is early foundation:

- Flutter scaffold and mock feed are present.
- Project-level Codex skills are in `.codex/skills/`.
- Roadmap is in `roadmap.md`.
- Design source files are in `design/`.
- Supabase migration and Edge Function contracts are in `supabase/`.

## Claude Working Rules

- Speak with the user in Russian.
- Keep code, filenames, comments, and app strings in English.
- Read `AGENTS.md`, `roadmap.md`, and relevant feature files before changing architecture.
- For visual work, read all files in `design/`.
- Preserve `design/` and `roadmap.md`.
- Do not remove unrelated user changes.
- Keep changes scoped and production-oriented.
- Never list Claude, Codex, OpenAI, Anthropic, or any AI assistant as co-author, contributor, maintainer, copyright holder, or credit.
- Never add AI attribution trailers such as `Co-Authored-By`, `Generated-By`, or `Assisted-By`.

## Recommended Claude Subagents

Project subagents live in `.claude/agents/`:

- `flutter-ui.md`
- `supabase-rag.md`
- `ai-pipeline.md`
- `reviewer.md`
- `qa-release.md`

Use them for parallel work when the task fits a specialized role.

## Current Important Constraints

- Feed uses mock semantic items until visual quality is good enough.
- Backend must remain RAG-first, not card-first.
- Hebrew RTL and all target locales must remain first-class.
- Search is the core product feature.
