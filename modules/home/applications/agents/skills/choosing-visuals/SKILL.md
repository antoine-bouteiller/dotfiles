---
name: choosing-visuals
description: Choose a compact visual for explaining design structure, behavior, or alternatives in specs, plans, and discussions.
---

# Choose a visual

Use a visual when it makes relationships easier to understand than a short paragraph. Simple facts
and one-step changes often need no visual. Place the view beside the text it supports and include
only the boundaries, labels, and detail needed for that decision.

| Explain                                          | Prefer                                                       |
| ------------------------------------------------ | ------------------------------------------------------------ |
| Options, properties, or mappings                 | Table                                                        |
| Algorithm or branching logic                     | Pseudocode                                                   |
| Runtime calls                                    | Indented call tree                                           |
| UI ownership and state boundaries                | Component tree annotated with relevant paths                 |
| File responsibilities                            | Shallow file tree                                            |
| Interactions, sequence, or data flow             | Mermaid                                                      |
| A change to an existing shape                    | Short diff                                                   |
| A mostly new contract that needs copyable detail | Code block                                                   |
| A dense layout or interactive comparison         | Focused HTML artifact, when the deliverable benefits from it |

For example, a short diff can show how a call sequence changes:

```diff
 submitForm
   createSession
+    expandSkillMention
     launchAgent
   navigateToSession
+    subscribeToEvents
```

Use language tags that match the content; mark sketches as text or pseudocode rather than presenting
them as compilable code. Prefer signatures and boundary behavior over a complete implementation.

For HTML, use real labels and the product's visual conventions when available. Create a file only
when an artifact fits the requested deliverable, and place it beside the document it supports.
Open it only when useful and supported by the environment; otherwise provide its path. Choose the
smallest view that answers the question, not every view in the table.
