# Contributing to BurntToast

Thanks for your interest in contributing. This document covers what you need to know to get set up, the conventions the codebase follows, and how to get a change merged.

## Reporting issues

Use the [issue templates](.github/ISSUE_TEMPLATE) — they exist to make sure bug reports include the PowerShell edition/version, Windows build, and a reproduction. Maintainer-time is the bottleneck; a clear repro is the single most useful thing you can include.

## Development setup

You will need:

- Windows 10 build 15063 or later (Windows Server equivalent is fine).
- PowerShell 7.2 (LTS) or later. Windows PowerShell 5.1 is no longer supported as of v2.0.0.
- The [Pester](https://pester.dev/) v5.x and [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) modules.

Clone the repo and import the dev module straight from `src/`:

```powershell
Import-Module ./src/BurntToast.psd1 -Force
```

## Running the tests

The full test + coverage flow goes through the build script:

```powershell
./Tasks/build.ps1 -Test
```

This produces `TestResults.xml` (JUnit) and `CoverageResults.xml` (JaCoCo) at the repo root. The same script runs in CI on every push and pull request — see `.github/workflows/ci.yaml`.

For a quick inner loop you can invoke Pester directly:

```powershell
Invoke-Pester ./Tests
```

## Linting

PSScriptAnalyzer runs as part of CI. To run it locally:

```powershell
./Tests/_pssa.ps1
```

There are no excluded rules — if a finding genuinely doesn't apply, justify the suppression in the PR rather than adding it to the excludes list.

## Code style

- 4-space indent, CRLF line endings, UTF-8. The `.editorconfig` enforces this.
- Use `[CmdletBinding()]` (canonical casing) on every public function. Add `[OutputType(...)]` whenever the function emits objects.
- Mutating cmdlets should declare `SupportsShouldProcess = $true` and call `$PSCmdlet.ShouldProcess(...)` before side effects.
- Cmdlets that take per-item input should support the pipeline (`ValueFromPipeline` for the primary input; `ValueFromPipelineByPropertyName` where it's natural — e.g. `Tag`/`Group` on `Remove-BTNotification`). Use `begin`/`process`/`end` blocks accordingly.
- Comment-based help (`.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.INPUTS`/`.OUTPUTS`/`.EXAMPLE`/`.LINK`) is required on every public function.

## Commit and PR conventions

Look at recent merged commits for the style — the prefix in parentheses categorizes the change (`(#123)`, `(repo)`, `(release)`, `(maint)`, etc). Keep commit subjects short; put the why in the body or PR description.

PRs that touch behaviour should:

1. Update or add tests in `Tests/`.
2. Update the matching markdown help file in `Help/` (or note it for a follow-up if the change is large).
3. Add an entry to `CHANGES.md` under an unreleased heading.

## Scope guidance

This is a focused module: it produces and submits Windows toast notifications. It is not a general-purpose Windows automation library. Features should fit that scope — when in doubt, open an issue first to discuss.
