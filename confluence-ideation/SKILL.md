---
name: confluence-ideation
description: "Collaborative design sessions that publish directly to Confluence. Use this skill when the user wants to brainstorm, design, or ideate AND the result should live in Confluence — e.g., 'design session for a new Confluence page', 'update this Confluence page with a design', 'brainstorm X and put it on Confluence', or when given a Confluence page URL/ID to work on. Also trigger when the user says 'confluence design', 'write a design on Confluence', or references a parent page for new design work."
---

# Confluence Design Sessions

## Overview

Run collaborative design sessions — the same iterative brainstorming process as the ideation skill — but publish the outcome directly to Confluence instead of a local file.

Two modes:
- **New page**: Create a new child page under a given parent. Requires a parent page (ID, URL, or title).
- **Update page**: Refine or extend an existing Confluence page. Requires the page (ID, URL, or title).

## Getting Started

### Determine the mode

Figure out which mode you're in from the user's request:

- If they provide a **parent page** (or say "new page under X"), you're creating a new page.
- If they provide an **existing page** (or say "update this page", "improve this design"), you're updating.
- If unclear, ask: "Are we creating a new design page, or updating an existing one?"

### Extract the page reference

The user might give you:
- A Confluence URL — extract the page ID from it (the numeric part in `/pages/123456789/`)
- A page ID directly
- A page title — use it with space key `$SPACE_KEY` to look it up

### Gather context

**For new pages:**
1. Look up the parent page with `confluence_get_page` to understand where this will live and what sibling pages exist
2. Use `confluence_get_page_children` on the parent to see existing child pages — avoid duplicating something that already exists
3. Check the project state (files, docs, recent commits in copilot-service) for technical context

**For existing pages:**
1. Read the current page content with `confluence_get_page` — understand what's already written
2. Read comments with `confluence_get_comments` — these contain feedback, questions, and context from collaborators that must inform the design session
3. Summarize what you found: the current state of the page and any comment themes (open questions, disagreements, suggestions)
4. Check the project state for technical context

## The Design Session

This follows the same collaborative process as a regular ideation session.

**Understanding the idea:**
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible
- Only one question per message
- Focus on: purpose, constraints, success criteria
- For updates: anchor questions around the existing content and comment feedback — don't start from scratch

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Lead with your recommended option and explain why
- For updates: one option can be "keep current approach, refine details"

**Presenting the design:**
- Once you understand what you're building, present the design in sections of 200-300 words
- Ask after each section whether it looks right
- Cover what's relevant: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify

## Publishing to Confluence

Once the design is validated:

**New page:**
1. Propose a page title based on the design topic — confirm with the user before creating
2. Create the page with `confluence_create_page`:
   - `space_key`: `$SPACE_KEY` (default, unless user specifies otherwise)
   - `parent_id`: the parent page ID gathered earlier
   - `content_format`: `markdown`
3. Share the page URL with the user

**Updating an existing page:**
1. Decide whether to extend or rewrite based on the session outcome:
   - If the design session refined specific sections or added new ones → merge changes into the existing content, preserving parts that weren't discussed
   - If the design session fundamentally rethought the approach → rewrite the page
   - If it's not clear which approach fits → ask the user: "Should I update specific sections or rewrite the page with the new design?"
2. Update with `confluence_update_page`:
   - Preserve the existing title unless the user agreed to change it
   - Use `content_format`: `markdown`
3. Share the updated page URL with the user

## Key Principles

- **One question at a time** — don't overwhelm with multiple questions
- **Multiple choice preferred** — easier to answer than open-ended when possible
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Explore alternatives** — always propose 2-3 approaches before settling
- **Incremental validation** — present design in sections, validate each
- **Comments are context** — when updating, treat Confluence comments as stakeholder input that shapes the design direction
- **Be flexible** — go back and clarify when something doesn't make sense
- **Respect existing content** — when updating, don't discard content that wasn't part of the discussion unless explicitly agreed
