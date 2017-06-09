#!/usr/bin/env bash
# -*- coding: utf-8; sh-shell: bash; -*-

export PATH="@DEPENDENCIES@/bin"

function sgr () { printf '\e[%dm%s\e[0m' "$1" "$2"; }

function nixFormatHelp () {
    echo "Usage: nix-format [--help|--version]"
    echo "       nix-format convert INPUT OUTPUT"
    echo "       nix-format replace FILE"
    echo "       nix-format check   FILE"
    echo ""
    echo "In $(sgr 1 indent) mode, read the INPUT file, format it, and write"
    echo "the resultant text to the OUTPUT file."
    echo ""
    echo "In $(sgr 1 replace) mode, read the given FILE, format it, and write"
    echo "the resultant text back to the same file."
    echo ""
    echo "In $(sgr 1 check) mode, read the given FILE, format it, and if the"
    echo "formatted text is different than the original, show an error."
}

function nixFormatVersion () {
    echo "nix-format version @VERSION@"
}

function nixFormatConvert () {
    local INPUT OUTPUT

    INPUT="$1"
    OUTPUT="$2"

    emacs --quick --script "@NIX_FORMAT_SCRIPT@" "$INPUT" "$OUTPUT" &>/dev/null
}

function nixFormatReplace () {
    local FILE TEMPORARY

    FILE="$1"
    TEMPORARY="$(mktemp -d --tmpdir nix-format.XXXXX)"

    cp "${FILE}" "${TEMPORARY}/input.nix"

    nixFormatConvert "${TEMPORARY}/input.nix" "${TEMPORARY}/output.nix"

    cp "${TEMPORARY}/output.nix" "${FILE}"

    rm -rf "${TEMPORARY}"
}

function nixFormatCheck () {
    local FILE TEMPORARY DIFFERENCE

    FILE="$1"
    TEMPORARY="$(mktemp -d --tmpdir nix-format.XXXXX)"

    cp "${FILE}" "${TEMPORARY}/input.nix"

    nixFormatConvert "${TEMPORARY}/input.nix" "${TEMPORARY}/output.nix"

    DIFFERENCE="$(diff "${TEMPORARY}/input.nix" "${TEMPORARY}/output.nix")"

    if test -z "${DIFFERENCE}"; then
        return 0
    else
        meld "${TEMPORARY}/input.nix" "${TEMPORARY}/output.nix"
        return 100
    fi

    rm -rf "${TEMPORARY}"
}

function checkFile () {
    local FILE

    FILE="${1}"

    test -e "${FILE}" || {
        echo "'${FILE}' does not exist" > /dev/stderr
        return 2
    }

    test -f "${FILE}" || {
        echo "'${FILE}' is not a file" > /dev/stderr
        return 3
    }
}

function checkReadable () {
    test -r "${1}" || {
        echo "'${1}' is not readable" > /dev/stderr
        return 4
    }
}

function checkWritable () {
    local RESOLVED

    RESOLVED="$(readlink -f "${1}")"

    if test -e "${RESOLVED}"; then
        test -w "${RESOLVED}" || {
            echo "'${1}' is not writable" > /dev/stderr
            return 5
        }
    else
        test -w "$(dirname "${RESOLVED}")" || {
            echo "'${1}' is not writable" > /dev/stderr
            return 5
        }
    fi
}

function nixFormat () {
    if [[ "$*" = "--help" ]]; then
        nixFormatHelp
        return 0
    elif [[ "$*" = "--version" ]]; then
        nixFormatVersion
        return 0
    elif [[ "${1}" = "convert" ]]; then
        (( $# == 3 )) || {
            echo "Wrong number of arguments for $(sgr 1 convert)" > /dev/stderr
            return 1
        }

        checkFile "${2}"     || return "$?"
        checkReadable "${2}" || return "$?"
        checkWritable "${3}" || return "$?"

        nixFormatConvert "${2}" "${3}"
    elif [[ "${1}" = "replace" ]]; then
        (( $# == 2 )) || {
            echo "Wrong number of arguments for $(sgr 1 replace)" > /dev/stderr
            return 1
        }

        checkFile "${2}"     || return "$?"
        checkReadable "${2}" || return "$?"
        checkWritable "${2}" || return "$?"

        nixFormatReplace "${2}"
    elif [[ "${1}" = "check" ]]; then
        (( $# == 2 )) || {
            echo "Wrong number of arguments for $(sgr 1 check)" > /dev/stderr
            return 1
        }

        checkFile "${2}"     || return "$?"
        checkReadable "${2}" || return "$?"

        nixFormatCheck "${2}"
    else
        echo "Could not parse arguments: '$*'" > /dev/stderr
        nixFormatHelp
        return 6
    fi
    return 0
}

nixFormat "$@"
exit "$?"
