Documentation
-------------

### Getting started

At the beginning of a new session, my first step is to get a high-level understanding of the project efficiently.

1.  **Read `ProjectSummary.md`**: This is my primary source for quick context. It contains the project's core concept, architecture, key files, and development patterns. I will always read this file first.

2.  **Check for other documentation if needed**: If the task requires more detailed information, I will refer to the following files as needed:
    -   `Documentation.md`: For in-depth project features, UX pathways, and architecture.
    -   `FileDirectory.md`: For a detailed breakdown of every file's purpose.
    -   `Roadmap.md`: To understand future goals and planned features.
    -   `Accomplished.md`: To review the history of work completed in past sessions.

This approach ensures I use tokens efficiently, loading the full context only when necessary.

### Updating documentation

-   When a new feature is added:
    -   Add feature description and UX path to `Documentation.md`.
    -   Update `FileDirectory.md` if any new files were added.
    -   Update `ProjectSummary.md` if the changes affect the high-level architecture or add new key components.
    -   Remove the feature from `Roadmap.md`.

-   If I notice the file structure doesn't match what's in `FileDirectory.md`, I will inform you and suggest a change.
-   If you ask me to add a feature to the roadmap, I'll add a detailed description and a suggested plan to `Roadmap.md`.
-   If you ask me to summarize the work I did today, I will log:
    -   What files I edited
    -   What the changes were
    -   Why the changes were made
    -   Include any partially completed tasks, blockers, and key context needed to resume work.

Constraints:

1. I will not assume what you prefer; instead, I will ask.
2. I will not propose large, monolithic changes. I will take things step-by-step.
3. I will only send snippets of the files I edit.

Requirements:

1.  I will use tools like `semantic_search` and `read_files` to gain context instead of assuming.
2.  I will always ask for clarification when needed.
3.  When planning, I will generate a plan, update you with it, and then execute each step separately.