#!/bin/bash
# Add pull request comment

# Requires these, provided in action.yml:
# - ADD_PR_COMMENT (skip unless "Yes")
# - PR_COMMENT_TOKEN (fail if empty)
# - COMMENTS_URL (skip if empty)
# - Current working directory is in the config repo

_planfile="${GITHUB_WORKSPACE}/octodns-sync.plan"

if [ "${ADD_PR_COMMENT}" = "Yes" ]; then
  if [ -z "${PR_COMMENT_TOKEN}" ]; then
    echo "FAIL: \$PR_COMMENT_TOKEN is not set."
    exit 1
  fi
  echo "INFO: \$ADD_PR_COMMENT is 'Yes' and \$PR_COMMENT_TOKEN is set."
else
  echo "SKIP: \$ADD_PR_COMMENT is not 'Yes'."
  exit 0
fi

if [ -z "${COMMENTS_URL}" ]; then
  echo "SKIP: \$COMMENTS_URL is not set."
  echo "Was this workflow run triggered from a pull request?"
  exit 0
fi

# Construct the comment body
_sha="$(git log -1 --format='%h')"
_header="## octoDNS Plan for ${_sha}"
_footer="Automatically generated by octodns-sync"

  # Post the comment
  # TODO: Rewrite post to use gh rather than python3
  _user="github-actions" \
  _token="${PR_COMMENT_TOKEN}" \
  _planfile="${_planfile}" \
  _header="${_header}" \
  _footer="${_footer}" \
  GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH}" \
  python3 -c "import requests, os, json
with open(os.environ['_planfile']) as f: plan = f.read()
comments_url = json.load(open(os.environ['GITHUB_EVENT_PATH'], 'r'))['pull_request']['comments_url']
response = requests.post(comments_url, auth=(os.environ['_user'], os.environ['_token']), json={'body':f\"{os.environ['_header']}\n\n{plan}\n{os.environ['_footer']}\"})
print(response)"
