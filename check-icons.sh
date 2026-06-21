#!/bin/bash
set -uo pipefail
#####################################################################
# Author    : Erik Dubois
# Website   : https://erikdubois.be
#####################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
# Purpose:
#   Validate every icon theme in a repo BEFORE the package is built, so
#   users never hit an error or a wall of missing icons when they install
#   and activate the theme.
#
#   It checks the things that actually break an icon theme on a user's
#   machine: a missing or malformed index.theme, directories that the
#   index.theme promises but that do not exist on disk, broken symlinks,
#   file/directory names containing spaces, a stale icon-theme.cache
#   accidentally committed, and finally runs gtk-update-icon-cache as the
#   definitive validator.
#
#   Layout-agnostic: it locates themes by finding index.theme anywhere
#   under the repo, so it works whether the themes live in usr/share/icons,
#   icons/, surfn-icons/ or the repo root. Drop it into any icon-theme repo
#   and run it, or pass a path:  ./check-icons.sh /path/to/icon-repo
#
# Why:
#   The distribution install hook runs gtk-update-icon-cache; if the
#   tree is inconsistent the user sees errors and broken icons. Catching
#   it here keeps a bad theme from ever being published.
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Scan root: first argument if given, otherwise the script's own directory.
ROOT="${1:-${SCRIPT_DIR}}"

#####################################################################
# Colors
#####################################################################
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    RESET="$(tput sgr0)"
else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""
fi

#####################################################################
# Logging
#####################################################################
log_section() {
    echo
    echo "${GREEN}############################################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################################${RESET}"
    echo
}

log_info() {
    echo
    echo "${BLUE}############################################################################${RESET}"
    echo "$1"
    echo "${BLUE}############################################################################${RESET}"
    echo
}

log_warn() {
    echo
    echo "${YELLOW}############################################################################${RESET}"
    echo "$1"
    echo "${YELLOW}############################################################################${RESET}"
    echo
}

log_error() {
    echo
    echo "${RED}############################################################################${RESET}"
    echo "$1"
    echo "${RED}############################################################################${RESET}"
    echo
}

log_success() {
    echo
    echo "${GREEN}############################################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################################${RESET}"
    echo
}

#####################################################################
# Error handling
#####################################################################
on_error() {
    local lineno="$1"
    local cmd="$2"
    echo
    echo "${RED}ERROR on line ${lineno}: ${cmd}${RESET}"
    echo
    sleep 10
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

#####################################################################
# Counters — collected across all checks, reported at the end
#####################################################################
ERRORS=0
WARNINGS=0

err() {
    echo "  ${RED}ERROR${RESET}  $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo "  ${YELLOW}WARN ${RESET}  $1"
    WARNINGS=$((WARNINGS + 1))
}

ok() {
    echo "  ${GREEN}OK   ${RESET}  $1"
}

#####################################################################
# Functions
#####################################################################

# Display a path relative to the scan root for readable output.
rel() {
    echo "${1#"${ROOT}"/}"
}

# A valid index.theme must exist, start the [Icon Theme] group, carry a
# Name= key, and use Unix line endings — anything else and GTK/Qt either
# ignore the theme or warn on every lookup.
check_index_theme() {
    local dir="$1" name="$2"
    local idx="${dir}/index.theme"

    if [[ ! -f "${idx}" ]]; then
        err "${name}: index.theme is missing — theme will not be recognised"
        return
    fi
    if ! grep -q '^\[Icon Theme\]' "${idx}"; then
        err "${name}: index.theme has no [Icon Theme] header"
    fi
    if ! grep -q '^Name=' "${idx}"; then
        err "${name}: index.theme has no Name= key"
    fi
    if grep -qU $'\r' "${idx}"; then
        err "${name}: index.theme has CRLF line endings — convert to Unix (LF)"
    fi
}

# Consistency between index.theme and the folders on disk. Both directions
# are WARN, not ERROR: gtk-update-icon-cache tolerates a declared dir that is
# missing (it just skips it — themes routinely over-declare, Papirus-style,
# verified on surfn-plasma-flow), and a real folder not listed only loses
# those icons. Neither aborts the install; the gtk build test is the real
# gate, so these only surface typos and coverage gaps.
check_declared_directories() {
    local dir="$1" name="$2"
    local idx="${dir}/index.theme"
    [[ -f "${idx}" ]] || return

    local declared sub
    declared="$(grep -E '^(Directories|ScaledDirectories)=' "${idx}" \
        | sed 's/^[^=]*=//; s/,/\n/g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
        | grep -v '^$' | sort -u)"

    while IFS= read -r sub; do
        [[ -z "${sub}" ]] && continue
        if [[ ! -d "${dir}/${sub}" ]]; then
            warn "${name}: index.theme lists '${sub}' but that folder does not exist"
        fi
    done <<< "${declared}"

    # Real context folders on disk that are not declared anywhere.
    local present
    present="$(find "${dir}" -mindepth 2 -maxdepth 2 -type d \
        -printf '%P\n' 2>/dev/null | sort -u)"
    while IFS= read -r sub; do
        [[ -z "${sub}" ]] && continue
        if ! grep -qx "${sub}" <<< "${declared}"; then
            warn "${name}: '${sub}' exists on disk but is not declared in index.theme"
        fi
    done <<< "${present}"
}

# The definitive test: gtk-update-icon-cache has no dry-run mode and writes
# icon-theme.cache next to the theme, so we run it against a throwaway copy
# (symlinks preserved with cp -a, --index-only to skip the heavy image data)
# and read its exit status. This is exactly what the distro install hook does.
check_gtk_cache() {
    local dir="$1" name="$2"
    if ! command -v gtk-update-icon-cache >/dev/null 2>&1; then
        warn "gtk-update-icon-cache not installed — skipping definitive cache test"
        return
    fi
    local tmp out
    tmp="$(mktemp -d)" || { warn "${name}: could not create temp dir — skipping cache test"; return; }
    cp -a "${dir}/." "${tmp}/"
    if out="$(gtk-update-icon-cache --index-only --force --quiet "${tmp}" 2>&1)"; then
        ok "${name}: gtk-update-icon-cache build passed"
    else
        err "${name}: gtk-update-icon-cache build failed :: ${out}"
    fi
    rm -rf "${tmp}"
}

# Broken symlinks render as missing icons in the user's session — BUT only when
# the target is genuinely absent at install time. Icon themes legitimately use
# symlinks that point OUTSIDE their own theme dir, into a sibling theme or an
# absolute /usr/share/icons/... path that only exists once every icon package is
# installed together (e.g. a meta-theme linking into al-beautyline). Those must
# NOT be called broken from a single repo. So:
#   - target resolves now                          -> fine
#   - target missing AND stays inside this theme   -> ERROR (truly broken, safe to remove)
#   - target missing AND escapes the theme (../ or /...) -> WARN (verify post-install, do NOT delete blindly)
check_broken_symlinks() {
    local scan="$1" link target resolved scan_abs
    scan_abs="$(realpath -m "${scan}")"
    while IFS= read -r -d '' link; do
        [[ -e "${link}" ]] && continue
        target="$(readlink "${link}")"
        if [[ "${target}" == /* ]]; then
            resolved="${target}"
        else
            resolved="$(realpath -m "$(dirname "${link}")/${target}")"
        fi
        if [[ "${resolved}" == "${scan_abs}/"* ]]; then
            err "broken symlink (target missing inside theme): $(rel "${link}") -> ${target}"
        else
            warn "symlink points outside theme — verify target exists once all icon packages are installed: $(rel "${link}") -> ${target}"
        fi
    done < <(find "${scan}" -type l -print0 2>/dev/null)
}

# A space in a file or directory name breaks the cache and usually means a
# leftover "(copy)" file slipped in.
check_spaces() {
    local scan="$1" hits
    hits="$(find "${scan}" -name '* *' 2>/dev/null)"
    if [[ -n "${hits}" ]]; then
        while IFS= read -r p; do
            err "name contains a space: $(rel "${p}")"
        done <<< "${hits}"
    fi
}

# Hidden files/dirs (.directory, .DS_Store, stray dotfiles) and editor/OS
# junk should never ship inside the package. Matches fix-icon-cache.sh's
# scan for any hidden file or directory, plus the usual backup/junk names.
check_junk_files() {
    local scan="$1" hidden junk
    hidden="$(find "${scan}" -depth -name '.*' ! -name '.' 2>/dev/null)"
    if [[ -n "${hidden}" ]]; then
        while IFS= read -r p; do
            warn "hidden file/dir (should not ship): $(rel "${p}")"
        done <<< "${hidden}"
    fi
    junk="$(find "${scan}" \
        \( -iname '*~' -o -iname 'Thumbs.db' -o -iname '*.bak' \) 2>/dev/null)"
    if [[ -n "${junk}" ]]; then
        while IFS= read -r p; do
            warn "junk/backup file: $(rel "${p}")"
        done <<< "${junk}"
    fi
}

# A committed icon-theme.cache is stale the moment a single icon changes and
# makes GTK serve wrong/blank icons until it is rebuilt.
check_committed_cache() {
    local scan="$1" caches
    caches="$(find "${scan}" -name 'icon-theme.cache' 2>/dev/null)"
    if [[ -n "${caches}" ]]; then
        while IFS= read -r p; do
            err "stale cache committed (remove before shipping): $(rel "${p}")"
        done <<< "${caches}"
    fi
}

# Files the package installs must be world-readable, directories traversable,
# or the icons are invisible to every non-root user.
check_permissions() {
    local scan="$1" bad_files bad_dirs
    bad_files="$(find "${scan}" -type f ! -perm -004 2>/dev/null)"
    bad_dirs="$(find "${scan}" -type d ! -perm -005 2>/dev/null)"
    if [[ -n "${bad_files}" ]]; then
        while IFS= read -r p; do
            warn "not world-readable: $(rel "${p}")"
        done <<< "${bad_files}"
    fi
    if [[ -n "${bad_dirs}" ]]; then
        while IFS= read -r p; do
            warn "directory not world-executable: $(rel "${p}")"
        done <<< "${bad_dirs}"
    fi
}

#####################################################################
# Main
#####################################################################
main() {
    log_section "Checking icon themes under ${ROOT}"

    if [[ ! -d "${ROOT}" ]]; then
        log_error "${ROOT} does not exist — nothing to check"
        exit 1
    fi

    # Discover themes by locating index.theme anywhere under the root (any
    # layout: usr/share/icons, icons/, surfn-icons/ or the repo root itself).
    local theme_dirs dir name
    theme_dirs="$(find "${ROOT}" -name .git -prune -o -type f -name 'index.theme' -printf '%h\n' 2>/dev/null | sort -u)"

    if [[ -z "${theme_dirs}" ]]; then
        log_error "No index.theme found anywhere under ${ROOT} — not an icon-theme repo?"
        exit 1
    fi

    log_info "Per-theme checks"
    while IFS= read -r dir; do
        [[ -z "${dir}" ]] && continue
        name="$(rel "${dir}")"
        echo "${CYAN}== ${name} ==${RESET}"
        check_index_theme "${dir}" "${name}"
        check_declared_directories "${dir}" "${name}"
        check_gtk_cache "${dir}" "${name}"
    done <<< "${theme_dirs}"

    log_info "Tree-wide checks"
    while IFS= read -r dir; do
        [[ -z "${dir}" ]] && continue
        check_broken_symlinks "${dir}"
        check_spaces "${dir}"
        check_junk_files "${dir}"
        check_committed_cache "${dir}"
        check_permissions "${dir}"
    done <<< "${theme_dirs}"

    if [[ "${ERRORS}" -gt 0 ]]; then
        log_error "$(basename "$0"): ${ERRORS} error(s), ${WARNINGS} warning(s) — fix errors before shipping"
        exit 1
    elif [[ "${WARNINGS}" -gt 0 ]]; then
        log_warn "$(basename "$0"): 0 errors, ${WARNINGS} warning(s) — review before shipping"
        log_success "$(basename "$0") done"
    else
        log_success "$(basename "$0") done — all themes clean"
    fi
}

main "$@"
