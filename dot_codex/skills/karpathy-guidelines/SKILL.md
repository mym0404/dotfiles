---
name: karpathy-guidelines
description: Apply four compact gates for assumption-aware, simple, surgical, and verifiable coding work.
license: MIT
---

# Karpathy Guidelines

Apply every gate to the current coding task.

## 1. Decision Gate

- State assumptions that can change behavior, scope, data handling, risk, or irreversible action.
- Present materially different interpretations and the simplest viable approach with its tradeoff.
- Begin implementation when every result-changing decision is resolved or explicitly assumed.

Complete when no hidden choice can change the result.

## 2. Simplicity Gate

- Build only the requested behavior.
- Use a current requirement to justify each abstraction, option, dependency, and error branch.
- Reduce an overgrown first pass before finishing.

Complete when removing another line would make the requested behavior incomplete or less safe.

## 3. Surgical Gate

- Preserve unrelated code, comments, formatting, and structure.
- Match the existing style.
- Remove only artifacts made unused by the current change.
- Report unrelated dead code and leave it unchanged.

Complete when every changed line traces directly to the request.

## 4. Verification Gate

- Translate each requested result into an observable behavior, file state, or command result.
- Run the smallest repository-native check for each meaningful result.
- Repeat until every criterion passes, available validation is exhausted, or a result-changing blocker requires the user.

Complete when the evidence proves the requested result rather than merely failing to reveal an error.
