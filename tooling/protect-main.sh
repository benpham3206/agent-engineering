#!/usr/bin/env bash
# Protects a GitHub repository's default branch with a ruleset named "main":
# changes arrive by pull request, required checks pass on an up-to-date branch,
# and the branch cannot be force-pushed or deleted.
# Usage: bash tooling/protect-main.sh OWNER/REPO. Needs an authenticated gh with admin rights.
# Required checks are the checks that ran (not skipped) on the latest pull request CI run,
# so a check that never runs on pull requests (a scheduled job) is never required.
# Run again after CI first runs on a pull request, or when check names change; it updates the ruleset in place.
set -euo pipefail

repo="${1:?usage: protect-main.sh OWNER/REPO}"
sha="$(gh api "repos/$repo/actions/runs?event=pull_request&per_page=1" --jq '.workflow_runs[0].head_sha // empty')"
checks=""
[[ -z "$sha" ]] || checks="$(gh api "repos/$repo/commits/$sha/check-runs" --paginate \
  --jq '.check_runs[] | select(.conclusion != "skipped") | .name' | sort -u)"

rules='{"type":"deletion"},{"type":"non_fast_forward"},{"type":"pull_request","parameters":{"required_approving_review_count":0,"dismiss_stale_reviews_on_push":false,"require_code_owner_review":false,"require_last_push_approval":false,"required_review_thread_resolution":false}}'
if [[ -n "$checks" ]]; then
  contexts="$(printf '%s\n' "$checks" | sed 's/.*/{"context":"&"}/' | paste -sd, -)"
  rules="$rules,{\"type\":\"required_status_checks\",\"parameters\":{\"strict_required_status_checks_policy\":true,\"required_status_checks\":[$contexts]}}"
else
  printf 'protect-main: no pull request CI run found; no required checks set. Run again after one runs.\n' >&2
fi
body="{\"name\":\"main\",\"target\":\"branch\",\"enforcement\":\"active\",\"conditions\":{\"ref_name\":{\"include\":[\"~DEFAULT_BRANCH\"],\"exclude\":[]}},\"rules\":[$rules]}"

existing="$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "main") | .id')"
if [[ -n "$existing" ]]; then
  gh api -X PUT "repos/$repo/rulesets/$existing" --input - --jq '"updated ruleset \(.id) on '"$repo"'"' <<< "$body"
else
  gh api -X POST "repos/$repo/rulesets" --input - --jq '"created ruleset \(.id) on '"$repo"'"' <<< "$body"
fi
printf 'required checks: %s\n' "${checks//$'\n'/, }"
