#!/bin/bash
set -euo pipefail
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#   Purpose:
#   - The 6-monthly upstream check of the two themes neo-candy is built on,
#     in one run: fetch Candy icons (GitHub master) and BeautyLine (Pling,
#     the original by sajjad606), compare them with or-candy-icons and
#     or-beautyline, sync those two copies, re-apply our Plasma fixes to
#     al-*, validate, record versions in upstream.lock + sources.md, and
#     after a y/N prompt commit and push to GitHub via up.sh.
#   - Garuda's BeautyLine fork is fetched for a report only: it is never
#     merged (Erik's decision, 2026-11-07).
#   - ./update-upstream.sh --check  only reports, changes nothing.
#
#   Why: the sync used to be done by hand every six months; one script
#   makes it repeatable and keeps or-* an exact upstream mirror while our
#   own work stays in al-*.
#
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ICONS="${SCRIPT_DIR}/usr/share/icons"
LOCK="${SCRIPT_DIR}/upstream.lock"
CANDY_GIT="https://github.com/EliverLara/candy-icons.git"
GARUDA_GIT="https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git"
PLING_BEAUTYLINE_ID="1425426"
STAMP="$(date +%Y-%m-%d)"
WORK=""
CHECK_ONLY=0

# Local files that are not upstream's and must survive the --delete sync
RSYNC_KEEP=(--exclude=index.theme --exclude=.git --exclude=.github --exclude=.directory --exclude='* *' --exclude='*(copy*'
            --filter='P places/16/folder-library.svg')

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
trap '[[ -n "${WORK}" ]] && rm -rf "${WORK}"' EXIT

#####################################################################
# Functions
#####################################################################
parse_args() {
    case "${1:-}" in
        "") ;;
        --check) CHECK_ONLY=1 ;;
        *) log_error "Unknown option: $1 (use --check for a report only)"; exit 1 ;;
    esac
}

require_tools() {
    local tool
    for tool in git curl rsync python3 rsvg-convert; do
        command -v "${tool}" >/dev/null 2>&1 || { log_error "Missing tool: ${tool}"; exit 1; }
    done
}

load_lock() {
    CANDY_COMMIT="" BEAUTYLINE_VERSION="" BEAUTYLINE_CHANGED="" GARUDA_COMMIT="" GARUDA_TAG="" CHECKED=""
    # shellcheck source=/dev/null
    [[ -f "${LOCK}" ]] && source "${LOCK}"
    log_info "Last check: ${CHECKED:-never} | Candy ${CANDY_COMMIT:-?} | BeautyLine ${BEAUTYLINE_VERSION:-?} (${BEAUTYLINE_CHANGED:-?})"
}

git_pull() {
    log_section "Git pull"
    git -C "${SCRIPT_DIR}" pull || log_warn "Git pull failed — continuing with local state"
    if [[ -n "$(git -C "${SCRIPT_DIR}" status --porcelain)" ]]; then
        log_warn "Working tree has uncommitted changes — they will be part of the push"
        git -C "${SCRIPT_DIR}" status --short | head -20
    fi
}

fetch_candy() {
    log_section "Candy icons — GitHub master"
    git clone -q --depth 1 "${CANDY_GIT}" "${WORK}/candy"
    NEW_CANDY_COMMIT="$(git -C "${WORK}/candy" rev-parse --short HEAD)"
    NEW_CANDY_DATE="$(git -C "${WORK}/candy" log -1 --format=%cs)"
    echo "  upstream ${NEW_CANDY_COMMIT} (${NEW_CANDY_DATE}), recorded ${CANDY_COMMIT:-none}"
    python3 -I "${SCRIPT_DIR}/tools/compare_trees.py" "${WORK}/candy" "${ICONS}/or-candy-icons" \
        --list "${WORK}/candy.diff"
}

fetch_beautyline() {
    local info url
    log_section "BeautyLine — Pling ${PLING_BEAUTYLINE_ID} (original by sajjad606)"
    info="$(python3 -I "${SCRIPT_DIR}/tools/pling_latest.py" "${PLING_BEAUTYLINE_ID}" BeautyLine)"
    IFS=$'\t' read -r NEW_BL_VERSION NEW_BL_CHANGED url <<< "${info}"
    echo "  Pling ${NEW_BL_VERSION} (changed ${NEW_BL_CHANGED}), recorded ${BEAUTYLINE_VERSION:-none} (${BEAUTYLINE_CHANGED:-none})"
    BL_DIR=""
    if [[ "${NEW_BL_VERSION}" == "${BEAUTYLINE_VERSION}" && "${NEW_BL_CHANGED}" == "${BEAUTYLINE_CHANGED}" ]]; then
        echo "  unchanged — nothing to download"
        return
    fi
    mkdir -p "${WORK}/beautyline"
    curl -fsSL -o "${WORK}/beautyline.tar.gz" "${url}"
    tar -xf "${WORK}/beautyline.tar.gz" -C "${WORK}/beautyline"
    BL_DIR="$(dirname "$(find "${WORK}/beautyline" -maxdepth 2 -name index.theme | head -1)")"
    python3 -I "${SCRIPT_DIR}/tools/compare_trees.py" "${BL_DIR}" "${ICONS}/or-beautyline" --contexts-only \
        --list "${WORK}/beautyline.diff"
}

report_garuda() {
    log_section "Garuda BeautyLine fork — report only, never merged"
    git clone -q --depth 1 "${GARUDA_GIT}" "${WORK}/garuda"
    git -C "${WORK}/garuda" fetch -q --depth 1 --tags || true
    NEW_GARUDA_COMMIT="$(git -C "${WORK}/garuda" rev-parse --short HEAD)"
    NEW_GARUDA_TAG="$(git -C "${WORK}/garuda" tag --sort=-v:refname | head -1)"
    echo "  ${NEW_GARUDA_TAG:-no tag} ${NEW_GARUDA_COMMIT}, recorded ${GARUDA_TAG:-none} ${GARUDA_COMMIT:-none}"
    [[ "${NEW_GARUDA_COMMIT}" != "${GARUDA_COMMIT}" ]] && echo "  ${CYAN}Garuda moved since the last check${RESET}"
    python3 -I "${SCRIPT_DIR}/tools/compare_trees.py" "${WORK}/garuda" "${ICONS}/or-beautyline" --contexts-only
}

sync_trees() {
    local ctx
    log_section "Sync or-candy-icons and or-beautyline"
    rsync -a --delete "${RSYNC_KEEP[@]}" "${WORK}/candy/" "${ICONS}/or-candy-icons/"
    if [[ -n "${BL_DIR}" ]]; then
        # only the contexts we vendor; Pling's root AUTHORS/COPYING/ReadMe stay out
        for ctx in "${ICONS}"/or-beautyline/*/; do
            ctx="$(basename "${ctx}")"
            if [[ -d "${BL_DIR}/${ctx}" ]]; then
                rsync -a --delete "${RSYNC_KEEP[@]}" "${BL_DIR}/${ctx}/" "${ICONS}/or-beautyline/${ctx}/"
            fi
        done
    fi
    echo "  done"
}

apply_fixes() {
    log_section "Re-apply Plasma hook + QtSvg fixes (al-* only)"
    python3 -I "${SCRIPT_DIR}/tools/neo_candy_plasma.py" "${ICONS}"
}

validate() {
    local diff rel theme
    local files=()
    log_section "Validate"
    bash "${SCRIPT_DIR}/check-icons.sh" "${SCRIPT_DIR}" || { log_error "check-icons.sh failed — fix before pushing"; exit 1; }
    # QtSvg check on the icons this sync brought in or changed
    for diff in candy beautyline; do
        [[ -f "${WORK}/${diff}.diff" ]] || continue
        theme="or-candy-icons"
        [[ "${diff}" == "beautyline" ]] && theme="or-beautyline"
        while IFS=$'\t' read -r kind rel; do
            if [[ "${kind}" != "removed" && "${rel}" == *.svg && -f "${ICONS}/${theme}/${rel}" ]]; then
                files+=("${ICONS}/${theme}/${rel}")
            fi
        done < "${WORK}/${diff}.diff"
    done
    if (( ${#files[@]} )); then
        python3 -I "${SCRIPT_DIR}/tools/qt_check.py" "${files[@]}"
    fi
}

write_records() {
    log_section "Record versions"
    cat > "${LOCK}" <<EOF
# Written by update-upstream.sh — the upstream state or-* was last synced to
CANDY_COMMIT=${NEW_CANDY_COMMIT}
CANDY_DATE=${NEW_CANDY_DATE}
BEAUTYLINE_VERSION=${NEW_BL_VERSION}
BEAUTYLINE_CHANGED=${NEW_BL_CHANGED}
GARUDA_COMMIT=${NEW_GARUDA_COMMIT}
GARUDA_TAG=${NEW_GARUDA_TAG}
CHECKED=${STAMP}
EOF
    cat > "${SCRIPT_DIR}/sources.md" <<EOF
# Sources

neo-candy-icons combines two icon themes. Their upstream copies live in
\`usr/share/icons/or-candy-icons\` and \`usr/share/icons/or-beautyline\`, and are
synced by \`update-upstream.sh\`. Our own work lives in the \`al-*\` themes.

| Theme | Source | Synced to | Upstream date |
|---|---|---|---|
| Candy icons | https://github.com/EliverLara/candy-icons (also https://www.pling.com/p/1305251/) | master \`${NEW_CANDY_COMMIT}\` | ${NEW_CANDY_DATE} |
| BeautyLine | https://www.pling.com/p/1425426/ (original by sajjad606) | ${NEW_BL_VERSION} | ${NEW_BL_CHANGED%%T*} |

Not merged, checked for information: Garuda's BeautyLine fork
https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline (${NEW_GARUDA_TAG} \`${NEW_GARUDA_COMMIT}\`).
It reaches users only through \`Inherits=BeautyLine\` when the \`beautyline\` package is installed.

Last upstream check: ${STAMP}
EOF
    echo "  upstream.lock and sources.md written"
}

save_notes() {
    local dir
    dir="${SCRIPT_DIR}/versions/$(date +%Y-%m-%d_%H%M)-upstream"
    mkdir -p "${dir}"
    cp "${WORK}"/*.diff "${dir}/" 2>/dev/null || true
    cp "${WORK}/report.log" "${dir}/NOTES.txt"
    echo "  notes in ${dir}"
}

ask_push() {
    local answer=""
    log_section "Changes"
    git -C "${SCRIPT_DIR}" status --short | awk '{print $2}' | cut -d/ -f1-5 | sort | uniq -c | sort -rn | head -15
    if [[ -z "$(git -C "${SCRIPT_DIR}" status --porcelain)" ]]; then
        log_info "Nothing changed — no push needed"
        return
    fi
    if [[ -t 0 ]]; then
        read -r -p "Push to GitHub now (commit + push via up.sh)? [y/N] " answer
    fi
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        COMMIT_MSG="upstream sync ${STAMP}: candy ${NEW_CANDY_COMMIT}, beautyline ${NEW_BL_VERSION}" bash "${SCRIPT_DIR}/up.sh"
        log_info "Pushed. Test the theme, then run flow-neo-candy-icons to build the package"
    else
        log_info "Not pushed. Test first, then run ./up.sh (or flow-neo-candy-icons, which pushes and builds)"
    fi
}

#####################################################################
# Main
#####################################################################
main() {
    parse_args "$@"
    require_tools
    WORK="$(mktemp -d)"
    exec > >(tee "${WORK}/report.log") 2>&1
    load_lock
    (( CHECK_ONLY )) || git_pull
    fetch_candy
    fetch_beautyline
    report_garuda
    if (( CHECK_ONLY )); then
        log_success "$(basename "$0") done — report only, nothing changed"
        return
    fi
    sync_trees
    apply_fixes
    validate
    write_records
    save_notes
    ask_push

    log_success "$(basename "$0") done"
}

main "$@"
