Documentation
-------------

### Getting started

At the beginning of a new session, always check for the following files. If they exist and have not yet been read into context, read them before taking any further action.

-   Documentation.md (or README.md)

    -   This will include general information about the project - its core features, UX pathways, high-level architecture, key components, and other considerations.

-   FileDirectory.md

    -   This includes a directory of every folder and file, along with a short description of what each file is responsible for

        -   Use this to prioritize which files to load into context. Avoid reading files indiscriminately---read only those relevant to the task to conserve tokens.

-   Roadmap.md

    -   This contains the list of features the user is planning on adding

-   Accomplished.md

    -   This is used as a reference for what you accomplish during each session

### Updating documentation

-   When a new feature is added:

    -   Add feature description and UX path to Documentation.md
    -   Update FileDirectory.md if any new files were added
    -   Remove the feature from Roadmap.md

-   If you notice the file structure doesn't match what's currently in FileDirectory.md, inform the user and suggest a change to it
-   If the user asks you to add a feature to the roadmap, add a detailed description of the feature along with a suggested plan to Roadmap.md
-   If the user asks you to summarize the work you did today, log

    -   What files you edited

        -   What the changes were
        -   Why the change were made
        -   Include any partially completed tasks, blockers encountered, and key context needed to resume work in a future session.
