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
#   Validate every icon theme shipped in usr/share/icons/ BEFORE the
#   package is built, so users never hit an error or a wall of missing
#   icons when they install and activate the theme.
#
#   It checks the things that actually break an icon theme on a user's
#   machine: a missing or malformed index.theme, directories that the
#   index.theme promises but that do not exist on disk, broken symlinks,
#   file/directory names containing spaces, a stale icon-theme.cache
#   accidentally committed, and finally runs gtk-update-icon-cache in
#   test mode as the definitive validator.
#
# Why:
#   The distribution install hook runs gtk-update-icon-cache; if the
#   tree is inconsistent the user sees errors and broken icons. Catching
#   it here keeps a bad theme from ever being published.
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="${SCRIPT_DIR}/usr/share/icons"

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

# A valid index.theme must exist, start the [Icon Theme] group, carry a
# Name= key, and use Unix line endings — anything else and GTK/Qt either
# ignore the theme or warn on every lookup.
check_index_theme() {
    local theme="$1"
    local idx="${ICONS_DIR}/${theme}/index.theme"

    if [[ ! -f "${idx}" ]]; then
        err "${theme}: index.theme is missing — theme will not be recognised"
        return
    fi
    if ! grep -q '^\[Icon Theme\]' "${idx}"; then
        err "${theme}: index.theme has no [Icon Theme] header"
    fi
    if ! grep -q '^Name=' "${idx}"; then
        err "${theme}: index.theme has no Name= key"
    fi
    if grep -qU $'\r' "${idx}"; then
        err "${theme}: index.theme has CRLF line endings — convert to Unix (LF)"
    fi
}

# Every path in Directories= and ScaledDirectories= must exist on disk;
# gtk-update-icon-cache aborts the whole theme when one is missing. The
# reverse (a real folder not listed) only loses those icons, so it warns.
check_declared_directories() {
    local theme="$1"
    local idx="${ICONS_DIR}/${theme}/index.theme"
    [[ -f "${idx}" ]] || return

    local declared sub
    declared="$(grep -E '^(Directories|ScaledDirectories)=' "${idx}" \
        | sed 's/^[^=]*=//; s/,/\n/g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
        | grep -v '^$' | sort -u)"

    while IFS= read -r sub; do
        [[ -z "${sub}" ]] && continue
        if [[ ! -d "${ICONS_DIR}/${theme}/${sub}" ]]; then
            err "${theme}: index.theme lists '${sub}' but that folder does not exist"
        fi
    done <<< "${declared}"

    # Real context folders on disk that are not declared anywhere.
    local present
    present="$(find "${ICONS_DIR}/${theme}" -mindepth 2 -maxdepth 2 -type d \
        -printf '%P\n' 2>/dev/null | sort -u)"
    while IFS= read -r sub; do
        [[ -z "${sub}" ]] && continue
        if ! grep -qx "${sub}" <<< "${declared}"; then
            warn "${theme}: '${sub}' exists on disk but is not declared in index.theme"
        fi
    done <<< "${present}"
}

# Broken symlinks render as missing icons in the user's session.
# Only RELATIVE targets are judged here: a relative link that does not resolve
# inside the repo is genuinely broken in the package. An ABSOLUTE target (e.g.
# /usr/share/icons/...) only resolves once installed, so we report those
# separately as info instead of failing the build on a false positive.
check_broken_symlinks() {
    local link target
    while IFS= read -r -d '' link; do
        target="$(readlink "${link}")"
        if [[ "${target}" == /* ]]; then
            if [[ ! -e "${link}" ]]; then
                warn "absolute symlink unresolved in repo (verify it exists once installed): ${link#"${SCRIPT_DIR}"/} -> ${target}"
            fi
        elif [[ ! -e "${link}" ]]; then
            err "broken symlink: ${link#"${SCRIPT_DIR}"/} -> ${target}"
        fi
    done < <(find "${ICONS_DIR}" -type l -print0 2>/dev/null)
}

# A space in a file or directory name breaks the cache and usually means a
# leftover "(copy)" file slipped in.
check_spaces() {
    local hits
    hits="$(find "${ICONS_DIR}" -name '* *' 2>/dev/null)"
    if [[ -n "${hits}" ]]; then
        while IFS= read -r p; do
            err "name contains a space: ${p#"${SCRIPT_DIR}"/}"
        done <<< "${hits}"
    fi
}

# Hidden files/dirs (.directory, .DS_Store, stray dotfiles) and editor/OS
# junk should never ship inside the package. Matches fix-icon-cache.sh's
# scan for any hidden file or directory, plus the usual backup/junk names.
check_junk_files() {
    local hidden junk
    hidden="$(find "${ICONS_DIR}" -depth -name '.*' ! -name '.' 2>/dev/null)"
    if [[ -n "${hidden}" ]]; then
        while IFS= read -r p; do
            warn "hidden file/dir (should not ship): ${p#"${SCRIPT_DIR}"/}"
        done <<< "${hidden}"
    fi
    junk="$(find "${ICONS_DIR}" \
        \( -iname '*~' -o -iname 'Thumbs.db' -o -iname '*.bak' \) 2>/dev/null)"
    if [[ -n "${junk}" ]]; then
        while IFS= read -r p; do
            warn "junk/backup file: ${p#"${SCRIPT_DIR}"/}"
        done <<< "${junk}"
    fi
}

# A committed icon-theme.cache is stale the moment a single icon changes and
# makes GTK serve wrong/blank icons until it is rebuilt.
check_committed_cache() {
    local caches
    caches="$(find "${ICONS_DIR}" -name 'icon-theme.cache' 2>/dev/null)"
    if [[ -n "${caches}" ]]; then
        while IFS= read -r p; do
            err "stale cache committed (remove before shipping): ${p#"${SCRIPT_DIR}"/}"
        done <<< "${caches}"
    fi
}

# Files the package installs must be world-readable, directories traversable,
# or the icons are invisible to every non-root user.
check_permissions() {
    local bad_files bad_dirs
    bad_files="$(find "${ICONS_DIR}" -type f ! -perm -004 2>/dev/null)"
    bad_dirs="$(find "${ICONS_DIR}" -type d ! -perm -005 2>/dev/null)"
    if [[ -n "${bad_files}" ]]; then
        while IFS= read -r p; do
            warn "not world-readable: ${p#"${SCRIPT_DIR}"/}"
        done <<< "${bad_files}"
    fi
    if [[ -n "${bad_dirs}" ]]; then
        while IFS= read -r p; do
            warn "directory not world-executable: ${p#"${SCRIPT_DIR}"/}"
        done <<< "${bad_dirs}"
    fi
}

# The definitive test: gtk-update-icon-cache has no dry-run mode and writes
# icon-theme.cache next to the theme, so we run it against a throwaway copy
# (symlinks preserved with cp -a, --index-only to skip the heavy image data)
# and read its exit status. This is exactly what the distro install hook does.
check_gtk_cache() {
    local theme="$1"
    if ! command -v gtk-update-icon-cache >/dev/null 2>&1; then
        warn "gtk-update-icon-cache not installed — skipping definitive cache test"
        return
    fi
    local tmp out
    tmp="$(mktemp -d)" || { warn "${theme}: could not create temp dir — skipping cache test"; return; }
    cp -a "${ICONS_DIR}/${theme}/." "${tmp}/"
    if out="$(gtk-update-icon-cache --index-only --force --quiet "${tmp}" 2>&1)"; then
        ok "${theme}: gtk-update-icon-cache build passed"
    else
        err "${theme}: gtk-update-icon-cache build failed :: ${out}"
    fi
    rm -rf "${tmp}"
}

#####################################################################
# Main
#####################################################################
main() {
    log_section "Checking icon themes in usr/share/icons"

    if [[ ! -d "${ICONS_DIR}" ]]; then
        log_error "${ICONS_DIR} does not exist — nothing to check"
        exit 1
    fi

    local themes theme
    themes="$(find "${ICONS_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"

    if [[ -z "${themes}" ]]; then
        log_error "No theme directories found in ${ICONS_DIR}"
        exit 1
    fi

    log_info "Per-theme checks"
    while IFS= read -r theme; do
        echo "${CYAN}== ${theme} ==${RESET}"
        check_index_theme "${theme}"
        check_declared_directories "${theme}"
        check_gtk_cache "${theme}"
    done <<< "${themes}"

    log_info "Tree-wide checks"
    check_broken_symlinks
    check_spaces
    check_junk_files
    check_committed_cache
    check_permissions

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
