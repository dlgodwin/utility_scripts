#!/bin/bash

# Fetch and prune remote branches
git fetch --prune

# Get a list of local branches
local_branches=$(git branch --format '%(refname:short)')

# Get a list of remote branches
remote_branches=$(git branch -r --format '%(refname:short)' | sed 's|origin/||')

# Loop through local branches and delete those not on the remote
for branch in $local_branches; do
  if [[ "$branch" != "main" && "$branch" != "master" && ! "$remote_branches" =~ "$branch" ]]; then
    echo "Deleting local branch: $branch"
    git branch -D "$branch"
  fi
done