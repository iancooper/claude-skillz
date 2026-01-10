#!/bin/bash

# Claude Launcher - Bash wrapper (DEPRECATED)
#
# This script has been replaced by a Python version for better maintainability.
# Please update your alias to use the Python launcher.

LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_LAUNCHER="$LAUNCHER_DIR/claude-launcher.py"

if [ ! -f "$PYTHON_LAUNCHER" ]; then
    echo "❌ Error: Python launcher not found at $PYTHON_LAUNCHER"
    exit 1
fi

echo ""
echo "⚠️  DEPRECATED: Bash launcher is no longer maintained"
echo ""
echo "Update your alias in ~/.zshrc or ~/.bashrc:"
echo ""
echo "  alias cl='python3 $PYTHON_LAUNCHER'"
echo ""
echo "Then reload:"
echo ""
echo "  source ~/.zshrc  # or source ~/.bashrc"
echo ""
echo "Launching Python version..."
echo ""

# Pass through all arguments to Python launcher
exec python3 "$PYTHON_LAUNCHER" "$@"
