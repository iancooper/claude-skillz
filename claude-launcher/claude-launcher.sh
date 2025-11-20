#!/bin/bash

# Claude Code Profile Launcher with Import Processing
# Automatically resolves @ references in system prompts (1 level only)

PROMPTS_DIR="$HOME/.claude/system-prompts"
DEBUG_OUTPUT="/tmp/claude-launcher-debug.md"

# Process @ references (single level only)
process_imports() {
    local file="$1"
    local result=""
    local imports=()
    local errors=()

    echo "Processing: $file" >&2

    # Read file and collect imports
    while IFS= read -r line; do
        # Check for @ reference at start of line
        if [[ $line =~ ^[[:space:]]*-?[[:space:]]*@([^[:space:]]+)[[:space:]]*$ ]]; then
            local import_path="${BASH_REMATCH[1]}"
            local import_path_expanded="${import_path/#\~/$HOME}"

            if [ -f "$import_path_expanded" ]; then
                echo "  ✓ Found: $import_path" >&2
                imports+=("$import_path")
                result+="$(cat "$import_path_expanded")"
                result+=$'\n\n'
            else
                echo "  ✗ ERROR: Import file not found: $import_path" >&2
                errors+=("$import_path")
            fi
        else
            result+="$line"
            result+=$'\n'
        fi
    done < "$file"

    # Check for errors
    if [ ${#errors[@]} -gt 0 ]; then
        echo "" >&2
        echo "ERROR: Failed to load ${#errors[@]} import(s):" >&2
        for err in "${errors[@]}"; do
            echo "  - $err" >&2
        done
        return 1
    fi

    # Add manifest header if we found imports
    if [ ${#imports[@]} -gt 0 ]; then
        echo "" >&2
        echo "Loaded ${#imports[@]} skill(s) successfully" >&2

        local manifest="---

# Loaded Skills

The following skills have been loaded and are active for this session:

"
        for import in "${imports[@]}"; do
            local basename=$(basename "$import" .md)
            manifest+="- **$basename** (\`$import\`)
"
        done
        manifest+="
---

"
        echo "$manifest$result"
    else
        echo "$result"
    fi
}

# Get list of system prompts
profiles=()
profile_files=()
while IFS= read -r file; do
    basename_file=$(basename "$file")
    profiles+=("${basename_file%.*}")
    profile_files+=("$file")
done < <(find -L "$PROMPTS_DIR" \( -name "*.txt" -o -name "*.md" \) -type f | sort)

# Check if any profiles exist
if [ ${#profiles[@]} -eq 0 ]; then
    echo "Error: No system prompts found in $PROMPTS_DIR"
    exit 1
fi

# Display menu
echo "Select a Claude Code system prompt:"
PS3=$'\nEnter number: '
select profile_name in "${profiles[@]}" "Cancel"; do
    if [ "$profile_name" = "Cancel" ]; then
        echo "Cancelled"
        exit 0
    elif [ -n "$profile_name" ]; then
        # Find the corresponding file
        for i in "${!profiles[@]}"; do
            if [ "${profiles[$i]}" = "$profile_name" ]; then
                selected_file="${profile_files[$i]}"
                break
            fi
        done

        echo ""
        echo "Selected: $profile_name"
        echo ""

        # Process imports
        system_prompt=$(process_imports "$selected_file")

        if [ $? -ne 0 ]; then
            echo ""
            echo "Aborting due to import errors"
            exit 1
        fi

        # Save debug output
        echo "$system_prompt" > "$DEBUG_OUTPUT"
        echo ""
        echo "Debug: Processed system prompt saved to $DEBUG_OUTPUT"
        echo "       ($(echo "$system_prompt" | wc -l) lines, $(echo "$system_prompt" | wc -c) bytes)"
        echo ""
        echo "Launching Claude Code..."
        echo ""

        # Launch Claude Code with processed prompt
        exec claude --system-prompt "$system_prompt" "$@"
    else
        echo "Invalid selection. Please try again."
    fi
done
