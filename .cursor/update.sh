#!/bin/sh
# Script for updating Cursor configuration in projects.
# See github.com/erazemk/cursor for more info.

# Exit on error
set -o errexit
set -o nounset

# Download and execute the latest init.sh script and pass along all arguments
curl -s https://raw.githubusercontent.com/erazemk/cursor/main/init.sh | sh -s -- "$@"
