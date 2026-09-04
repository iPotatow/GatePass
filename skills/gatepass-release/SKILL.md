---
name: gatepass-release
description: Prepare, publish, and audit GatePass macOS releases from main, including version alignment, README assets, CI packaging, GitHub Release notes, and post-publish verification.
---

# GatePass Release

Use this skill when the current repository is GatePass; verify the remote before mutating anything. It covers release preparation, integrating a release branch into main, publishing, and auditing an existing release.

## Choose the mode

- For questions such as “how does release work?” or “audit the last release,” inspect and report only. Do not edit, commit, push, or edit a GitHub Release.
- For prepare, publish, or ship requests, perform the workflow below, but preserve the user's authorization boundary before each externally visible mutation.
- If the target version is not explicit, calculate a candidate from the change set and ask for confirmation before editing VERSION.
- Treat existing worktree changes as user-owned. Never use git reset --hard, git checkout --, git clean, or an unrequested stash.

## Repository invariants

- VERSION is the canonical semantic version and must contain exactly MAJOR.MINOR.PATCH.
- Every existing MARKETING_VERSION assignment in GatePass.xcodeproj/project.pbxproj must match VERSION, including Debug and Release.
- The release tag is v<VERSION>. A tag that differs from VERSION is a hard stop.
- The release destination is origin/main. A feature branch such as defaults or feat/system-optimization-aa is a source of changes, not a branch to push during a main-only release unless explicitly requested.
- Release notes belong in the GitHub Release. Do not create CHANGELOG.md unless explicitly requested.
- Keep README.md and README.zh-CN.md accurate. When the UI changes, update current screenshots under assets and remove stale, unreferenced screenshots.
- Never include .codex/, local environment files, build products, or temporary evidence files unless explicitly requested.

## 1. Inspect before changing

From the repository root, run read-only checks: git status --short --branch, git branch -vv, git log --oneline --decorate -12, git remote -v, cat VERSION, rg -n MARKETING_VERSION GatePass.xcodeproj/project.pbxproj, and find .github/workflows -maxdepth 1 -type f -print.

Determine the release/source branch, the relationship between local main and origin/main, the scope of dirty changes, and whether the request is a versioned release or a docs-only follow-up. If branch switching would risk unrelated changes, stop and ask.

## 2. Prepare the release

On the release/source branch, or on main when no source branch is involved:

1. Set VERSION to the confirmed target and align all Xcode MARKETING_VERSION assignments.
2. Review the implementation and tests. For System Preferences changes, preserve typed /usr/bin/defaults I/O, read-back verification, stale-state protection, recovery records, and history behavior.
3. Update both READMEs for shipped behavior, build/install instructions, safety implications, and release artifacts. Remove claims about removed features.
4. If the interface changed, replace stale README images with real screenshots of the shipped UI. Keep the full UI state, use descriptive alt text, verify every referenced path, and prefer a small focused set rather than a gallery.
5. Draft the GitHub Release body with:
   - Highlights
   - Breaking change, only when applicable
   - Safety
   - Verification

Do not use a repository CHANGELOG as a substitute for the GitHub Release. The workflow enables generated notes, but review and replace or supplement them when they omit the user-facing summary, breaking changes, safety notes, or verification evidence.

Before committing, run git diff --check, plutil -lint GatePass/Info.plist, plutil -lint GatePass.xcodeproj/project.pbxproj, and focused tests. Use the full Xcode app for a local build; Command Line Tools alone cannot build this project. If the local developer directory is only Command Line Tools, report that limitation and rely on hosted CI rather than mislabeling it as a source failure.

Commit only the reviewed release scope. A suitable message is release: prepare GatePass <version>; use a separate docs: commit for a later screenshot or README-only follow-up.

## 3. Integrate into main

When release changes are on another branch:

1. Fetch remote state and compare the source branch, local main, and origin/main.
2. Switch to main only when the worktree is safe to switch.
3. Fast-forward when possible. If origin/main has independent commits, use a normal merge or a user-approved rebase; do not rewrite published history by default.
4. Resolve conflicts deliberately and rerun version and README checks.
5. Inspect the final graph and diff. Do not push the source branch merely because it has an upstream tracking branch.
6. After explicit authorization, push exactly git push origin main.

If push is rejected, fetch again and inspect the new history. Never force-push as a convenience.

## 4. Repository CI

Release GatePass at .github/workflows/build.yml:

- Runs for pushes to main that include VERSION and for v* tags; manual dispatch accepts publish_release.
- Validates semantic versioning and requires a tag event to equal v<VERSION>.
- Runs on macos-latest, builds the GatePass - Release scheme with Xcode, and disables code signing for packaging.
- Installs create-dmg, invokes script/build_dmg.sh, and produces GatePass.zip, GatePass-<version>.dmg, and SHA256SUMS.
- Uploads a versioned artifact and, on a normal main push or authorized manual run, creates or updates the matching GitHub Release.

System Preferences CI at .github/workflows/system-preferences-ci.yml:

- Runs for System Preferences source/test changes on main and feat/system-optimization-aa, relevant pull requests, and manual dispatch.
- Tests macos-14, macos-15, and macos-26.
- macos-14 intentionally skips the project build because its hosted Xcode cannot open the project object version, but still compiles and runs the regression suite.
- Other matrix entries build against the macOS 13 deployment target and run the same core regression suite.

System Preferences Defaults Audit at .github/workflows/system-preferences-defaults-audit.yml:

- Runs manually or for final catalog changes on feat/system-optimization-aa.
- Probes every production preference and restores original values.
- Inspect or run this audit before merging catalog changes; do not claim it passed when only regression tests ran.

## 5. Verify the published release

After pushing a versioned commit:

1. Check Release GatePass for the exact main commit with gh run list --workflow build.yml --branch main; watch the run when active.
2. Check System Preferences CI when that feature changed, and check the defaults audit before claiming catalog validation.
3. Inspect the matching release with gh release view v<VERSION> or the GitHub UI.
4. Confirm it is published, not draft or prerelease, and targets the intended release commit.
5. Confirm GatePass.zip, GatePass-<version>.dmg, and SHA256SUMS exist and are non-empty. When assets are downloaded locally, verify them with shasum -a 256 -c SHA256SUMS.
6. Confirm the Release body contains the reviewed highlights, breaking changes when applicable, safety guidance, and verification evidence. Edit the existing release body instead of creating a duplicate release.
7. Verify git ls-remote origin refs/heads/main and confirm the worktree is clean except for explicitly pre-existing untracked files.

For a docs-only follow-up after a release, push the documentation commit normally but do not create a second version tag or duplicate Release. Change the Release body only when the release notes themselves need correction.

## Stop conditions and handoff

Stop and report when the target version is ambiguous, worktree ownership is unclear, VERSION/Xcode/tag values disagree, CI fails, assets are missing, the release targets the wrong commit, history would require a destructive rewrite, or GitHub authentication is unavailable.

End with evidence: target version, source and main commits, pushed ref, CI results, Release URL, asset names, checks performed, local limitations, and intentionally excluded files.
