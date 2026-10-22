# Development tasks. Run `just --list` to see all recipes.

repo := justfile_directory()

# Sync the pinned cli_version() in cli/cli.mbt with `version` in moon.mod.
sync:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{repo}}"
    version=$(perl -ne 'print $1 if /^version\s*=\s*"([^"]+)"/' moon.mod)
    if [ -z "$version" ]; then
        echo 'just sync: no version = "..." line found in moon.mod' >&2
        exit 1
    fi
    case "$version" in
        v*) pinned="$version" ;;
        *) pinned="v$version" ;;
    esac
    version="$pinned" perl -0777 -i -pe \
        'die "just sync: cli_version() not found in cli/cli.mbt\n"
            unless s/(fn cli_version\(\) -> String \{\s*")[^"]*(")/${1}$ENV{version}${2}/' \
        cli/cli.mbt
    echo "synced cli_version() to $pinned"

build:
    moon build cmd/moonway
