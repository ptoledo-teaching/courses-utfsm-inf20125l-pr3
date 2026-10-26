#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPOSITORY="${WORKSPACE}/repositorio"
MATERIAL="${WORKSPACE}/material"
SOURCE="${REPOSITORY}/registro.c"
PROGRAM="${REPOSITORY}/registro"
PASSES=0
FAILURES=0

pass() {
    printf 'PASS: %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

check() {
    local description="$1"
    shift

    if "$@"; then
        pass "${description}"
    else
        fail "${description}"
    fi
}

repository_exists() {
    [[ -d "${REPOSITORY}/.git" ]] || return 1
    git -C "${REPOSITORY}" rev-parse --is-inside-work-tree \
        >/dev/null 2>&1
}

file_is_tracked() {
    local path="$1"

    repository_exists || return 1
    git -C "${REPOSITORY}" ls-files --error-unmatch -- "${path}" \
        >/dev/null 2>&1
}

commit_file_matches() {
    local commit="$1"
    local repository_path="$2"
    local expected_path="$3"

    git -C "${REPOSITORY}" show "${commit}:${repository_path}" \
        2>/dev/null | cmp -s -- - "${expected_path}"
}

commit_changes_only() {
    local commit="$1"
    shift
    local expected=""
    local paths=()

    mapfile -t paths < <(git -C "${REPOSITORY}" diff-tree \
        --no-commit-id --name-only -r "${commit}" 2>/dev/null | sort)
    (( ${#paths[@]} == $# )) || return 1
    for expected in "$@"; do
        printf '%s\n' "${paths[@]}" | grep -Fxq "${expected}" || return 1
    done
}

find_initial_material_commit() {
    local commit=""

    repository_exists || return 1
    while IFS= read -r commit; do
        if commit_file_matches "${commit}" registro.c \
            "${MATERIAL}/registro.c" && \
           commit_file_matches "${commit}" descripcion.txt \
            "${MATERIAL}/descripcion.txt" && \
           commit_changes_only "${commit}" descripcion.txt registro.c; then
            printf '%s\n' "${commit}"
            return 0
        fi
    done < <(git -C "${REPOSITORY}" rev-list --reverse HEAD 2>/dev/null)
    return 1
}

initial_material_is_in_history() {
    find_initial_material_commit >/dev/null
}

source_uses_version_two() {
    [[ -f "${SOURCE}" ]] || return 1
    grep -Eq '^#define[[:space:]]+VERSION_ACTUAL[[:space:]]+2[[:space:]]*$' \
        "${SOURCE}"
}

source_has_ordered_versions() {
    local initial_commit=""
    local commit=""

    initial_commit="$(find_initial_material_commit)" || return 1
    while IFS= read -r commit; do
        [[ "${commit}" == "${initial_commit}" ]] && continue
        git -C "${REPOSITORY}" merge-base --is-ancestor \
            "${initial_commit}" "${commit}" 2>/dev/null || continue
        if git -C "${REPOSITORY}" show "${commit}:registro.c" \
            2>/dev/null | \
            grep -Eq '^#define[[:space:]]+VERSION_ACTUAL[[:space:]]+2[[:space:]]*$' && \
           commit_changes_only "${commit}" registro.c; then
            return 0
        fi
    done < <(git -C "${REPOSITORY}" rev-list --reverse HEAD 2>/dev/null)
    return 1
}

is_binary_executable() {
    local description=""

    [[ -f "${PROGRAM}" && -x "${PROGRAM}" ]] || return 1
    description="$(file -b -- "${PROGRAM}")"
    [[ "${description}" == ELF*executable* ]]
}

program_reports_version_two() {
    is_binary_executable || return 1
    [[ "$("${PROGRAM}" 2>/dev/null)" == 'Versión actual: 2' ]]
}

executable_is_ignored() {
    [[ -f "${PROGRAM}" ]] || return 1
    file_is_tracked .gitignore || return 1
    if file_is_tracked registro; then
        return 1
    fi
    git -C "${REPOSITORY}" check-ignore -q -- registro
}

gitignore_has_own_commit() {
    local commit=""

    repository_exists || return 1
    while IFS= read -r commit; do
        if commit_changes_only "${commit}" .gitignore; then
            return 0
        fi
    done < <(git -C "${REPOSITORY}" rev-list --reverse HEAD -- .gitignore \
        2>/dev/null)
    return 1
}

repository_is_clean() {
    local status=""

    repository_exists || return 1
    status="$(git -C "${REPOSITORY}" status --porcelain \
        --untracked-files=all 2>/dev/null)"
    [[ -z "${status}" ]]
}

repository_is_synchronized() {
    local local_commit=""
    local upstream_commit=""

    repository_exists || return 1
    git -C "${REPOSITORY}" rev-parse --abbrev-ref \
        --symbolic-full-name '@{upstream}' >/dev/null 2>&1 || return 1
    local_commit="$(git -C "${REPOSITORY}" rev-parse HEAD \
        2>/dev/null)" || return 1
    upstream_commit="$(git -C "${REPOSITORY}" rev-parse '@{upstream}' \
        2>/dev/null)" || return 1
    [[ "${local_commit}" == "${upstream_commit}" ]]
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio PR3   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check "[2] Existe el repositorio clonado" repository_exists
check "[3] Los archivos iniciales están registrados en un mismo commit" initial_material_is_in_history
check "[4] registro.c utiliza la versión 2" source_uses_version_two
check "[4] registro.c conserva las versiones 1 y 2 en commits separados" source_has_ordered_versions
check "[5] registro existe como binario ejecutable" is_binary_executable
check "[5] registro produce la salida esperada" program_reports_version_two
check "[5] registro está ignorado y no está registrado" executable_is_ignored
check "[5] .gitignore fue registrado en un commit separado" gitignore_has_own_commit
check "[5] El local está sincronizado con origin" repository_is_synchronized
check "[5] El repositorio no tiene cambios pendientes" repository_is_clean
check "[6.1] check.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
