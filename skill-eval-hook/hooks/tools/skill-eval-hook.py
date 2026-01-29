#!/usr/bin/env python3
import json
import os
import sys
import subprocess

SKILL_MANIFEST = os.environ.get("CLAUDE_SKILL_MANIFEST", "/tmp/claude-skill-manifest.json")

def load_manifest():
    try:
        with open(SKILL_MANIFEST) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None

def evaluate_skills(prompt, skills):
    skill_list = "\n".join(
        f"- {s['name']}: {s['description']}" for s in skills
    )

    eval_prompt = f"""You are a skill activation evaluator. Given a user prompt and a list of skills with trigger descriptions, determine which skills MUST be active for this prompt.

SKILLS:
{skill_list}

USER PROMPT:
{prompt}

For each skill, output YES or NO with a brief reason. Then output a final line:
ACTIVATE: skill1, skill2, ...

Be aggressive — if there is any chance a skill applies, say YES."""

    try:
        result = subprocess.run(
            ["claude", "--model", "sonnet", "--print", "-p", eval_prompt],
            capture_output=True,
            text=True,
            timeout=15
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None

def main():
    input_data = json.load(sys.stdin)
    prompt = input_data.get("prompt", "")
    if not prompt:
        sys.exit(0)

    manifest = load_manifest()
    if not manifest or not manifest.get("skills"):
        sys.exit(0)

    evaluation = evaluate_skills(prompt, manifest["skills"])
    if not evaluation:
        sys.exit(0)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": f"SKILL ACTIVATION EVALUATION:\n{evaluation}\n\nYou MUST follow every skill marked YES. This is not optional."
        }
    }
    print(json.dumps(output))
    sys.exit(0)

if __name__ == "__main__":
    main()
