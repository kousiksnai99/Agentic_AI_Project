#!/usr/bin/env python3
"""
commit_ps.py
- Creates a new branch from SOURCE_BRANCH
- Pushes a local PowerShell (.ps1) file into that branch (path: scripts/<filename>)
- Creates a Pull Request from the new branch -> SOURCE_BRANCH (PR remains open)
- Optionally attach reviewers by email/uniqueName
"""
import os
import sys
import uuid
import json
import requests
from requests.auth import HTTPBasicAuth

# ===== HARD-CODED CONFIG =====
ORG = "Teva-CCOE"
PROJECT = "ITOA-Agentic-AI-PROJECT"
REPO = "ITOA-Agentic-AI-PROJECT"
EMAIL = "your_email@company.com"        # <-- replace with your Azure DevOps login email
PAT = "azdXXXXXXXXXXXXXX"               # <-- replace with your PAT
SOURCE_BRANCH = "main"
LOCAL_PS_FILE = "sample_script.ps1"    # local PS1 file path

API_VERSION = "7.1"
HEADERS = {"Content-Type": "application/json"}

# BASE URL for repo API calls
BASE_URL = f"url_refs = f"https://dev.azure.com/{ORG}/{PROJECT}/_apis/git/repositories/{REPO}/refs?filter=heads/{branch_name}&api-version=7.1"
auth = HTTPBasicAuth(EMAIL, PAT)

def get_ref_for_branch(branch_name):
    """Return ref object for a branch (or None). branch_name: e.g. 'main'"""
    url = f"{BASE_URL}/refs?filter=heads/{branch_name}&api-version={API_VERSION}"
    r = requests.get(url, auth=auth)
    r.raise_for_status()
    data = r.json()
    if data.get("count", 0) > 0:
        return data["value"][0]
    return None

def create_branch_from(source_branch, new_branch):
    """Create refs/heads/{new_branch} pointing to source_branch's commit"""
    source_ref = get_ref_for_branch(source_branch)
    if not source_ref:
        raise RuntimeError(f"Source branch '{source_branch}' not found in repo.")
    commit_id = source_ref["objectId"]
    body = [
        {
            "name": f"refs/heads/{new_branch}",
            "oldObjectId": "0000000000000000000000000000000000000000",
            "newObjectId": commit_id
        }
    ]
    url = f"{BASE_URL}/refs?api-version={API_VERSION}"
    r = requests.post(url, json=body, auth=auth, headers=HEADERS)
    r.raise_for_status()
    print(f"✅ Branch created: refs/heads/{new_branch}")
    return r.json()

def push_file_to_branch(branch_name, local_file_path, repo_target_path):
    """Push a file into the branch at repo_target_path (e.g. scripts/foo.ps1)"""
    if not os.path.exists(local_file_path):
        raise RuntimeError(f"Local file not found: {local_file_path}")

    with open(local_file_path, "r", encoding="utf-8") as f:
        content = f.read()

    ref = get_ref_for_branch(branch_name)
    if not ref:
        raise RuntimeError(f"Branch '{branch_name}' not found for push.")
    old_object_id = ref["objectId"]

    url = f"{BASE_URL}/pushes?api-version={API_VERSION}"
    body = {
        "refUpdates": [
            {"name": f"refs/heads/{branch_name}", "oldObjectId": old_object_id}
        ],
        "commits": [
            {
                "comment": f"Add {repo_target_path}",
                "changes": [
                    {
                        "changeType": "add",
                        "item": {"path": "/" + repo_target_path},
                        "newContent": {
                            "content": content,
                            "contentType": "rawtext"
                        }
                    }
                ]
            }
        ]
    }
    r = requests.post(url, json=body, auth=auth, headers=HEADERS)
    r.raise_for_status()
    print(f"✅ File pushed to branch 'refs/heads/{branch_name}' at path '/{repo_target_path}'")
    return r.json()

def create_pull_request(source_branch, target_branch, title, description, reviewers=None):
    """Create PR from refs/heads/{source_branch} -> refs/heads/{target_branch}"""
    url = f"{BASE_URL}/pullrequests?api-version={API_VERSION}"
    body = {
        "sourceRefName": f"refs/heads/{source_branch}",
        "targetRefName": f"refs/heads/{target_branch}",
        "title": title,
        "description": description
    }
    if reviewers:
        body["reviewers"] = [{"uniqueName": r} for r in reviewers]
    r = requests.post(url, json=body, auth=auth, headers=HEADERS)
    r.raise_for_status()
    pr = r.json()
    pr_id = pr.get("pullRequestId")
    pr_url = pr.get("_links", {}).get("web", {}).get("href")
    print(f"✅ Pull Request created: ID {pr_id}")
    if pr_url:
        print(f"🔗 PR URL: {pr_url}")
    return pr

def main():
    # generate branch name
    short = uuid.uuid4().hex[:8]
    new_branch = f"agentic-{short}"

    # 1) create branch from SOURCE_BRANCH
    create_branch_from(SOURCE_BRANCH, new_branch)

    # 2) push the local PS file into repository under scripts/<filename>
    filename = os.path.basename(LOCAL_PS_FILE)
    repo_path = f"scripts/{filename}"
    push_file_to_branch(new_branch, LOCAL_PS_FILE, repo_path)

    # 3) create PR (open) -> reviewer option
    print("\nDo you want to add reviewers to the PR? (enter comma-separated emails/uniqueNames, or leave blank)")
    rev_input = input("Reviewers: ").strip()
    reviewers = [r.strip() for r in rev_input.split(",")] if rev_input else None

    title = f"Auto PR: add {filename} (branch {new_branch})"
    description = "Auto-created PR: add PowerShell script. Merge after approval."

    pr = create_pull_request(new_branch, SOURCE_BRANCH, title, description, reviewers=reviewers)

    print("\n🎯 Done — PR is OPEN and waiting for approval.")
    print("Reminder: The file and changes are only in the new branch until PR is approved & merged.")
    print("To approve & merge, use Azure DevOps UI or call the approval/complete API (not performed by this script).")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERROR:", str(e))
        sys.exit(1)
