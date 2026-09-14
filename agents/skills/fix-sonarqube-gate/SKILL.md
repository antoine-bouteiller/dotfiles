---
name: fix-sonarqube-gate
description: Diagnose and repair a failing SonarQube quality gate for the requested merge request or analyzed branch.
disable-model-invocation: true
---

# Fix the SonarQube gate

Identify the analysis behind the failure, fix its failing conditions at the source, and distinguish
local verification from a confirmed green gate. Use the installed `sonar` CLI and confirm access
with `sonar auth status`; use its configured credentials rather than exposing tokens.

## Resolve the analysis

Read the request, repository remote, `sonar-project.properties`, scanner/build configuration, and
relevant CI wiring for the project key. If still unknown, use `sonar list projects` and match the
repository; resolve ambiguity before editing.

For an MR gate, obtain the current branch and list analyzed pull requests:

```bash
git branch --show-current
sonar api get "/api/project_pull_requests/list?project=<encoded-project-key>"
```

Parse JSON and compare branch names exactly, not with a substring or regex grep. Match the requested
MR where supplied. Use the returned PR key; do not assume it from a branch name. Check analysis
revision/time against the failed CI run or requested commit when available.

If the MR has no analysis, report that gap and inspect its scanner/CI setup. Use an analyzed branch
only when it is the requested target or evidence shows the gate belongs to that exact branch.
Main-branch findings are not a substitute for missing feature-branch analysis.

## Read failing conditions

URL-encode query values. For an MR:

```bash
sonar api get "/api/qualitygates/project_status?projectKey=<key>&pullRequest=<pr>"
```

For a branch analysis, replace `pullRequest` with `branch` consistently in subsequent requests.
Read `metricKey`, `status`, `comparator`, `errorThreshold`, and `actualValue`. Target failing
conditions and related code; do not broaden the task to unrelated legacy findings.

For new issues, query:

```bash
sonar api get "/api/issues/search?componentKeys=<key>&pullRequest=<pr>&resolved=false&inNewCodePeriod=true&ps=500"
```

Inspect rules, affected paths/lines, messages, and reachability. Follow `paging.total` through all
pages; parameters and metric names can vary by server version, so inspect API help when rejected.
Fix genuine defects rather than suppressing rules to obtain a green gate. Document a demonstrated
false positive instead of changing behavior incorrectly.

## Repair coverage when it is failing

Fetch `new_coverage`, `new_lines_to_cover`, `new_conditions_to_cover`,
`new_uncovered_lines`, and `new_uncovered_conditions` through
`/api/measures/component`. Use `/api/measures/component_tree` with `qualifiers=FIL` to locate
affected files. Follow pagination when the first page is insufficient, and read metric values
from their returned period/value structure.

Coverage includes lines and branch conditions. With `total = lines_to_cover + conditions_to_cover`
and `uncovered = uncovered_lines + uncovered_conditions`, coverage is
`100 * (total - uncovered) / total` when total is nonzero. Use the actual threshold and comparator
to estimate the required improvement; do not assume 80% or infer coverage from missing metrics.

Choose meaningful tests for missing behavior and failure paths using the repository's test style.
Investigate missing or misconfigured coverage reports when existing tests should already cover
the code. Whole-file coverage is not a requirement, and a test that bypasses the behavior is not a fix.

## Verify and report

Run relevant tests and lint/type checks, and inspect generated coverage when available. Follow
applicable repository instructions, including path-scoped rules. Describe the fixes and remaining
conditions.

Only a new successful Sonar analysis for the relevant revision confirms the gate is green. If
pushing or rerunning CI is already authorized, do it and inspect that result; otherwise leave the
local fixes ready and state that analysis is pending. Do not weaken the gate or change project-wide
exclusions to bypass the failure.
