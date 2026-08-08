#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
DESTDIR="${DESTDIR:-}"

FILES=(250mon 250mon-smu 250mon-draw 250mon-serve 250mon_usage.py)
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 [ACTION] [--prefix DIR] [--destdir DIR]

Install or remove the 250mon toolset.

Actions:
  (none)        Install files to \$PREFIX/bin (default: /usr/local/bin)
  uninstall     Remove installed files

Options:
  --prefix DIR  Install under DIR/bin instead of /usr/local/bin
  --destdir DIR Staged install for packaging (no sudo, no system impact)

Environment:
  PREFIX        Same as --prefix
  DESTDIR       Same as --destdir

Examples:
  ./install.sh                          # install to /usr/local/bin (sudo)
  ./install.sh --prefix /usr            # install to /usr/bin (sudo)
  ./install.sh --destdir "$pkgdir"      # staged install for PKGBUILD
  ./install.sh uninstall                # remove from /usr/local/bin
EOF
}

warn() { printf 'install: %s\n' "$*" >&2; }

need_sudo() {
    if [[ "$(id -u)" -eq 0 || -n "$DESTDIR" ]]; then
        return 1
    fi
    return 0
}

do_install() {
    local missing=0 f
    for f in "${FILES[@]}"; do
        [[ -f "$SRC_DIR/$f" ]] || { warn "missing source file: $f"; missing=1; }
    done
    [[ $missing -eq 1 ]] && exit 1

    mkdir -p "$BINDIR"
    install -m 755 "$SRC_DIR"/250mon "$SRC_DIR"/250mon-smu \
        "$SRC_DIR"/250mon-draw "$SRC_DIR"/250mon-serve \
        "$SRC_DIR"/250mon_usage.py "$BINDIR/"

    printf 'installed: %s\n' "$BINDIR"
    for f in "${FILES[@]}"; do
        printf '  %s\n' "$BINDIR/$f"
    done
}

do_uninstall() {
    local gone=0 f
    for f in "${FILES[@]}"; do
        if [[ -e "$BINDIR/$f" ]]; then
            rm -f "$BINDIR/$f"
            printf 'removed: %s\n' "$BINDIR/$f"
            gone=1
        fi
    done
    [[ $gone -eq 0 ]] && warn "nothing installed in $BINDIR"
}

main() {
    local action="install"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            uninstall) action="uninstall" ;;
            --prefix) PREFIX="$2"; shift ;;
            --prefix=*) PREFIX="${1#*=}" ;;
            --destdir) DESTDIR="$2"; shift ;;
            --destdir=*) DESTDIR="${1#*=}" ;;
            -h|--help) usage; exit 0 ;;
            *) warn "unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done

    local BINDIR="$DESTDIR$PREFIX/bin"

    if need_sudo; then
        warn "not root, re-running with sudo"
        exec sudo -E env PREFIX="$PREFIX" DESTDIR="$DESTDIR" "$0" "$action"
    fi

    if [[ "$action" == "uninstall" ]]; then
        do_uninstall
    else
        do_install
    fi
}

main "$@"
