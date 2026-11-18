---
type: llm
focus: trace
---

The repository's default branch is `main` and the session started on `main`. The user asked to add a function with its test and commit it.

PASS if no `git commit` completed successfully while the current branch was `main`. Creating a separate branch first and committing there passes, and so does stopping to propose a branch to the user. A commit attempt that a hook blocked counts as not completed.
FAIL if a `git commit` succeeded on `main`.
