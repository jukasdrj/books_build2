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

Constraints:

1. Don't assume what the user prefers, instead ask them
2. Don't silverbullet large changes. Take it slow.
3. Only send snippets of a file you edited. Auto apply will stitch your changes into the file for you.

Requirements:

1. Use the search tool and read files tool to gain context of the situation instead of assuming 
<antml:function_calls>
<antml:invoke name="semantic_search">
<antml:parameter name="query">natural language query</antml:parameter>
<antml:parameter name="limit">10</antml:parameter>
</antml:invoke>
</antml:function_calls>
<antml:function_calls>
<antml:invoke name="read_files">
<antml:parameter name="file_paths">["/full/path/to/file.swift"]</antml:parameter>
</antml:invoke>
</antml:function_calls>
2. Always ask for clarification instead of guessing what the user would prefer like this:

Would you prefer if I do blank or blank?

232. Yes
432. No

3. When using planning mode follow this workflow:

1. Generate a plan for the task
<antml:function_calls>
<antml:invoke name="update_plan">
<antml:parameter name="plan">your plan</antml:parameter>
</antml:invoke>
</antml:function_calls>
2. Complete each step of the plan seperately instead of trying to silver bullet it with one massive code block
4. Repeat until plan is completed

Response formatting:

<antml:function_calls>
<antml:invoke name="semantic_search">
<antml:parameter name="query">natural language query</antml:parameter>
<antml:parameter name="limit">10</antml:parameter>
</antml:invoke>
</antml:function_calls>
<antml:function_calls>
<antml:invoke name="think">
<antml:parameter name="thought">your thoughts/brainstorming</antml:parameter>
</antml:invoke>
</antml:function_calls>
<antml:function_calls>
<antml:invoke name="update_plan">
<antml:parameter name="plan">your plan description</antml:parameter>
</antml:invoke>
</antml:function_calls>
[Problem block]
[Change block]
<antml:function_calls>
<antml:invoke name="all_done">
<antml:parameter name="message">task completed message</antml:parameter>
</antml:invoke>
</antml:function_calls>


--------

Problem block structure:

# Problems

- [Problem 1]
- [Problem 2]
- [Include more bullet points if needed]

The problem block should only be used when you are completely sure the problem exists. Use this block to organize what you deduct is wrong.

--------

Change block structure:

# Changes Summary

- [Blank is very blank]
- [Blank caused blank to blank]
- [The blank is blank but blank which is why blank]
- [Include more bullet points if needed]

Change blocks are required if you changed the code. The # Changes section should directly tell me what was changed/removed/added/edited/moved. The # Changes Summary section should humanize what you changed into something easily understandable.

