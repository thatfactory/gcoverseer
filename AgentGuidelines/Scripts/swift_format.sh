#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <format|format-and-lint|lint|lint-strict> <path>..." >&2
}

if [[ $# -lt 2 ]]; then
    usage
    exit 64
fi

mode="$1"
shift

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
configuration="$script_directory/../Configurations/Swift/.swift-format"

if command -v xcrun >/dev/null 2>&1 && xcrun --find swift-format >/dev/null 2>&1; then
    formatter=(xcrun swift-format)
elif command -v swift-format >/dev/null 2>&1; then
    formatter=(swift-format)
elif command -v swift >/dev/null 2>&1; then
    formatter=(swift format)
else
    echo "error: swift-format is unavailable; install or select a Swift 6 toolchain." >&2
    exit 127
fi

common_arguments=(
    --configuration "$configuration"
    --recursive
    --parallel
)

format_sources() {
    "${formatter[@]}" format --in-place "${common_arguments[@]}" "$@"
}

lint_sources() {
    "${formatter[@]}" lint "${common_arguments[@]}" "$@"
}

case "$mode" in
    format)
        format_sources "$@"
        ;;
    format-and-lint)
        format_sources "$@"
        lint_sources "$@"
        ;;
    lint)
        lint_sources "$@"
        ;;
    lint-strict)
        "${formatter[@]}" lint --strict "${common_arguments[@]}" "$@"
        ;;
    *)
        usage
        exit 64
        ;;
esac
