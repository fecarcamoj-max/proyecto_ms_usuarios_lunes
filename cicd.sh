#!/usr/bin/env bash

# Poll origin/master and deploy this Compose project when a new commit arrives.
# Intended for cron on the deployment host. Requires git, Docker Compose,
# and flock (util-linux). Maven runs inside the Docker build stage.

set -Eeuo pipefail

BRANCH="${BRANCH:-master}"
REMOTE="${REMOTE:-origin}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename -- "$PROJECT_DIR" | tr -cs '[:alnum:]_.-' '_')"
LOCK_FILE="${CICD_LOCK_FILE:-${TMPDIR:-/tmp}/cicd-${USER:-deploy}-${PROJECT_NAME}.lock}"
STATE_FILE="${CICD_STATE_FILE:-${HOME}/.cicd-last-deployed-${PROJECT_NAME}}"

cd "$PROJECT_DIR"

# Cron may start a new run before the previous build/deploy has finished.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$(date -Is)] Another CICD run is active; skipping."
  exit 0
fi

# chmod +x on Linux changes only the local mode. Ignore mode-only differences,
# while still refusing to pull over tracked content changes.
if ! git -c core.filemode=false diff --quiet --; then
  echo "[$(date -Is)] Tracked files have local content changes; refusing to pull/deploy." >&2
  exit 1
fi
if ! git -c core.filemode=false diff --cached --quiet --; then
  echo "[$(date -Is)] The index contains staged changes; refusing to pull/deploy." >&2
  exit 1
fi

# .env contains host-specific secrets and is expected to remain untracked.
while IFS= read -r untracked_file; do
  [[ -z "$untracked_file" || "$untracked_file" == ".env" ]] && continue
  echo "[$(date -Is)] Unexpected untracked file '${untracked_file}'; refusing to pull/deploy." >&2
  exit 1
done < <(git ls-files --others --exclude-standard)

git fetch --prune "$REMOTE" "$BRANCH"
LOCAL_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse "${REMOTE}/${BRANCH}")"

if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
  # Only advance when the remote is a descendant; never discard local history.
  if ! git merge-base --is-ancestor "$LOCAL_COMMIT" "$REMOTE_COMMIT"; then
    echo "[$(date -Is)] Local branch cannot fast-forward to ${REMOTE}/${BRANCH}; refusing deployment." >&2
    exit 1
  fi
  git pull --ff-only "$REMOTE" "$BRANCH" # SSH , Git pull token.
fi

CURRENT_COMMIT="$(git rev-parse HEAD)"
if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "$CURRENT_COMMIT" ]]; then
  echo "[$(date -Is)] Commit ${CURRENT_COMMIT} is already deployed."
  exit 0
fi

#Despliegue final...
docker compose down --remove-orphans --rmi local
# Remove dangling layers only; avoid pruning images or containers used by other projects.
docker image prune --force
docker compose build --pull usuarios_ms
docker compose up -d
printf '%s\n' "$CURRENT_COMMIT" >"$STATE_FILE"

echo "[$(date -Is)] Deployment completed for commit ${CURRENT_COMMIT:0:12}."
