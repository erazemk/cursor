#!/bin/sh
# A script for vendoring Go libraries for use with Cursor and setting up useful Cursor rules.
# See github.com/erazemk/cursor for more info.

set -o errexit
set -o nounset

DEBUG=false
SYNC_RULES=true
FORCE=false

CURSOR_DIR=".cursor"
RULES_DIR="$CURSOR_DIR/rules"
LIBRARIES_DIR="$CURSOR_DIR/libraries"

command -v git >/dev/null 2>&1 || error "git is not installed"

# Debug log (only shown if debug mode is enabled)
debug() {
    [ "$DEBUG" = true ] && printf "\033[90m%s\033[0m\n" "$@"
}

# Info log (always shown, blue)
info() {
    printf "\033[34m%s\033[0m\n" "$@"
}

# Error log (always shown, red, then exit)
error() {
    printf "\033[31m%s\033[0m\n" "$@"
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -d, --debug       Enable debug output
  -r, --no-rules    Disable downloading of Cursor rules
  -f, --force       Don't ask for confirmation when overwriting files (e.g., when copying Cursor rules)
  -h, --help        Show this help message and exit
EOF
}

create_temp_dir() {
    TEMP_DIR="$(mktemp -d)" || error "Failed to create a temporary directory"
}

remove_temp_dir() {
    rm -rf "$TEMP_DIR" || error "Failed to remove the temporary directory"
}

clone_template_repo() {
    info "Fetching latest Cursor template files..."
    if [ "$DEBUG" = true ]; then
        debug "Cloning the template repository to $TEMP_DIR..."
        git clone --depth 1 "https://github.com/erazemk/cursor.git" "$TEMP_DIR" || \
            error "Failed to clone the template repository"
    else
        git clone --depth 1 --quiet "https://github.com/erazemk/cursor.git" "$TEMP_DIR" || \
            error "Failed to clone the template repository"
    fi
}

copy_helper_files() {
    mkdir -p "$CURSOR_DIR" || error "Failed to create the $CURSOR_DIR directory"
    find "$TEMP_DIR/.cursor" -maxdepth 1 -type f -exec cp -f {} "$CURSOR_DIR"/ \; || error "Failed to copy files into $CURSOR_DIR/"
}

copy_rules() {
    mkdir -p "$RULES_DIR" || error "Failed to create the $RULES_DIR directory"

    cpcmd="cp -r"
    if [ "$FORCE" = true ]; then
        cpcmd="cp -rf"
    fi

    $cpcmd "$TEMP_DIR"/.cursor/rules/* "$RULES_DIR"/ || error "Failed to copy rules into $RULES_DIR/"
    chmod u+x "$CURSOR_DIR"/*.sh || error "Failed to make scripts within $CURSOR_DIR/ executable"
}

vendor_libraries() {
    command -v go >/dev/null 2>&1 || error "Go is not installed, can't vendor Go libraries"
    info "Vendoring Go libraries..."

    rm -rf "$LIBRARIES_DIR" || error "Failed to remove all files in $LIBRARIES_DIR"
    mkdir -p "$LIBRARIES_DIR" || error "Failed to create $LIBRARIES_DIR"

    vendor_dir="$TEMP_DIR/vendor"
    go mod vendor -o "$vendor_dir" || error "Failed to vendor Go dependencies"

    # Copy only direct dependencies, preserving structure
    for dependency in $(go list -f '{{if not .Indirect}}{{.Path}}{{end}}' -m all | grep -v '^$'); do
        dependency_path="$vendor_dir/$dependency"
        if [ -d "$dependency_path" ]; then
            target_path="$LIBRARIES_DIR/$dependency"
            mkdir -p "$(dirname "$target_path")" || error "Failed to create $target_path"
            cp -rf "$dependency_path" "$target_path" || error "Failed to copy $dependency to $LIBRARIES_DIR"
        fi
    done

    info "Vendored Go libraries to $LIBRARIES_DIR"
}

update_ignore_files() {
    # Don't track the libraries directory in git
    if [ -f .gitignore ]; then
        if ! grep -qF "$LIBRARIES_DIR" .gitignore; then
            echo "$LIBRARIES_DIR" >> .gitignore || error "Failed to update .gitignore"
        fi
    else
        echo "$LIBRARIES_DIR" > .gitignore || error "Failed to create .gitignore"
    fi

    # But Cursor should index it
    if [ -f .cursorignore ]; then
        if ! grep -qF "!$LIBRARIES_DIR" .cursorignore; then
            echo "!$LIBRARIES_DIR" >> .cursorignore || error "Failed to update .cursorignore"
        fi
    else
        echo "!$LIBRARIES_DIR" > .cursorignore || error "Failed to create .cursorignore"
    fi
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -r|--no-rules)
            SYNC_RULES=false
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

create_temp_dir
clone_template_repo
copy_helper_files
update_ignore_files

if [ "$SYNC_RULES" = true ]; then
    copy_rules
fi

if [ -f go.mod ]; then
    vendor_libraries
fi

remove_temp_dir
info "Finished initializing Cursor configuration"
