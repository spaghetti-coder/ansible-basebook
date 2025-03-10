#!/usr/bin/env bash

skeleton() (
  local BOOKSHELF_TGZ_URL='https://github.com/spaghetti-coder/ansible-bookshelf/archive/{{ BRANCH }}.tar.gz'
  declare -a COPY_PATHS=(
    ./.dev
    ./.editorconfig
    ./.gitignore
    ./ansible.cfg
    ./bin
    ./vendor/roles
    ./sample
  )
  declare -A COPY_MAP=(
    [skeleton/deps.ini]=./deps.ini
    [skeleton/playbook.yaml]=./playbook.yaml
    [skeleton/README.md]=./README.md
    [skeleton/requirements.yaml]=./requirements.yaml
    [skeleton/roles]=./roles
  )

  declare -A DEFAULTS=(
    [branch]=master
    [proj_dir]=.
  )

  declare -A ARGS=(
    [is_help]=false
    [branch]="${DEFAULTS[branch]}"
    [proj_dir]="${DEFAULTS[proj_dir]}"
  )

  parse_args() {
    while [ ${#} -gt 0 ]; do
      case "${1}" in
        -\?|-h|--help ) ARGS[is_help]=true ;;
        -b|--branch   ) ARGS[branch]="${2}"; shift ;;
        *             ) ARGS[proj_dir]="${1}" ;;
      esac

      shift
    done
  }

  trap_help() {
    ${ARGS[is_help]} || return

    local self; self=skel-init.sh
    grep -q '.\+' -- "${0}" && self="$(basename -- "${0}")"

    _text_fmt "
      Create ansible project skeleton.

      Usage:
      =====
      ${self} [-b|--branch BRANCH=${DEFAULTS[branch]}] [DEST_DIRECTORY=${DEFAULTS[proj_dir]}]

      Demo:
      ====
      ${self}                   # <- Create in the PWD, '${DEFAULTS[branch]}' git branch
      ${self} -b dev ./my/proj  # <- Explicite directory, 'dev' git branch
    "
  }

  init() {
    (set -x; mkdir -p -- "${ARGS[proj_dir]}") || return

    ! find -- "${ARGS[proj_dir]}" -mindepth 1 -maxdepth 1 | grep -q '.\+' || {
      echo "Can't create skeleton in non-empty directory: '${ARGS[proj_dir]}'" >&2
      return 1
    }

    local branch_repl; branch_repl="$(sed -e 's/[\/&]/\\&/g' <<< "${ARGS[branch]}")"
    # shellcheck disable=SC2001
    BOOKSHELF_TGZ_URL="$(sed -e 's/{{\s*BRANCH\s*}}/'"${branch_repl}"'/' <<< "${BOOKSHELF_TGZ_URL}")"
  }

  pull_base() {
    local dest="${1}"

    ( set -x
      curl -fsSL -- "${BOOKSHELF_TGZ_URL}" \
      | tar --strip-components 1 -xzf - -C "${dest}"
    )
  }

  copy_paths() {
    local src_dir="${1}"

    local dir name
    local o; for o in "${COPY_PATHS[@]}"; do
      dir="$(dirname -- "${o}")"
      name="$(basename -- "${o}")"

      ( set -x
        mkdir -p -- "${dir}" \
        && cp -r -- "${src_dir}/${o}" "${dir}/${name}"
      ) || return
    done

    # Cleanup sample vars
    .dev/sample-vars.sh
  }

  copy_mapped() {
    local src_dir="${1}"

    local src_file dest_file dest_dir
    for src_file in "${!COPY_MAP[@]}"; do
      dest_file="${COPY_MAP[${src_file}]}"
      dest_dir="$(dirname -- "${dest_file}")"

      ( set -x
        mkdir -p -- "${dest_dir}" \
        && cp -r -- "${src_dir}/${src_file}" "${dest_file}"
      ) || return
    done
  }

  _text_fmt() {
    local content; content="$(
      sed '/[^ ]/,$!d' <<< "${1-"$(cat)"}" | tac | sed '/[^ ]/,$!d' | tac
    )"
    local offset; offset="$(grep -o -m1 '^\s*' <<< "${content}")"
    sed -e 's/^\s\{0,'${#offset}'\}//' -e 's/\s\+$//' <<< "${content}"
  }

  main() {
    parse_args "${@}" || return
    trap_help && return
    init || return

    cd -- "${ARGS[proj_dir]}" || return

    local tmp_base; tmp_base="$(mktemp -d)" \
    && pull_base "${tmp_base}" \
    && copy_paths "${tmp_base}" \
    && copy_mapped "${tmp_base}" \
    || return

    (set -x; rm -rf "${tmp_base:?}")
  }

  main "${@}"
)

(return &>/dev/null) || skeleton "${@}"
