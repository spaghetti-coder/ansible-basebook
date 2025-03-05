#!/usr/bin/env bash

# shellcheck disable=SC2317
_envar_lib() (
  local THE_LIB="${FUNCNAME[0]}"
  local THE_TOOL=envar

  local GLOBAL_DIR="/etc/${THE_TOOL}"
  local USER_DIR_SUFFIX=".${THE_TOOL}.d"
  local BIN_FILE="/opt/spaghetti/${THE_TOOL}/bin/${THE_TOOL}.sh"
  local IGNORE_GLOBAL_FILE="${USER_DIR_SUFFIX}/_global.skip.sh"
  local IGNORE_SUFFIX_FILE="${USER_DIR_SUFFIX}/_suffix.skip.sh"
  local DEMO_FILE="${GLOBAL_DIR}/demo.skip.sh"
  local DEMO_DESK_FILE="${GLOBAL_DIR}/demo-desk.skip.sh"

  # Special marker for gen_* functions that allows skipping some code
  # blocks when running outside of envar function context
  local RUN_CONTEXT_ENVAR_zWilsdFI8I=true  # <- Ensure some unique var name

  req()     { printf -- '%s' "${ENVAR_REQ}${ENVAR_REQ:+$'\n'}"; }
  loaded()  { printf -- '%s' "${ENVAR_LOADED}${ENVAR_LOADED:+$'\n'}"; }
  desks()   { printf -- '%s' "${ENVAR_DESKS}${ENVAR_DESKS:+$'\n'}"; }

  gen_loader() {
    ${RUN_CONTEXT_ENVAR_zWilsdFI8I:-false} && {
      declare -f "${FUNCNAME[0]}" \
      | tail -n +2 `# <- Remove function haeder` \
      | sed -e 's#{{\s*GLOBAL_DIR\s*}}#'"${GLOBAL_DIR}"'#g' \
            -e 's#{{\s*USER_DIR_SUFFIX\s*}}#'"${USER_DIR_SUFFIX}"'#g' \
            -e 's#{{\s*IGNORE_GLOBAL_FILE\s*}}#'"${IGNORE_GLOBAL_FILE}"'#g' \
            -e 's#{{\s*IGNORE_SUFFIX_FILE\s*}}#'"${IGNORE_SUFFIX_FILE}"'#g'
      return
    }

    ENVAR_LOADED=""
    ENVAR_REQ=""

    # shellcheck disable=SC2030
    ENVAR_FILES="$(
      GLOBAL_DIR='{{ GLOBAL_DIR }}'
      USER_DIR_SUFFIX='{{ USER_DIR_SUFFIX }}'
      IGNORE_GLOBAL_FILE='{{ IGNORE_GLOBAL_FILE }}'

      {
        find_query=(
          -maxdepth 1 -type f # -readable # <- Not supported by BusyBox find
            '(' -name '*.sh' -not -name '*.skip.sh' ')'
            -o '(' -name '*.env' -not -name '*.skip.env' ')'
        )

        if [ -r "${GLOBAL_DIR}" ] && ! cat ~/"${IGNORE_GLOBAL_FILE}" &>/dev/null; then
          find -L "${GLOBAL_DIR}" "${find_query[@]}" | sort -n
        fi
        if [ -r ~/"${USER_DIR_SUFFIX}" ]; then
          find -L ~/"${USER_DIR_SUFFIX}" "${find_query[@]}" | sort -n
        fi
      }
    )"

    # Load environments
    [ -n "${ENVAR_FILES}" ] && while read -r _envar_file; do
      ENVAR_REQ+="${ENVAR_REQ:+$'\n'}${_envar_file}"
      [ -r "${_envar_file}" ] || { echo "Envar: can't open '${_envar_file}'" >&2; continue; }

      # shellcheck disable=SC1090
      . "${_envar_file}"
      ENVAR_LOADED+="${ENVAR_LOADED:+$'\n'}${_envar_file}"
    done <<< "${ENVAR_FILES}"

    # BusyBox realpath doesn't support '--', but stdouts file real path
    if [ -n "${ENVAR_DESK}" ] && ENVAR_DESK="$(realpath -- "${ENVAR_DESK}" 2>/dev/null | grep '.\+')"; then
      # shellcheck disable=SC2030
      ENVAR_DESKS="$(
        # https://unix.stackexchange.com/a/194790 modified for last wins
        tac <<< "${ENVAR_DESKS:+${ENVAR_DESKS}$'\n'}${ENVAR_DESK}" \
        | cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2- | tac
      )"
    fi

    # Load desks
    [ -n "${ENVAR_DESKS}" ] && while read -r _envar_file; do
      ENVAR_REQ+="${ENVAR_REQ:+$'\n'}${_envar_file}"
      [ -r "${_envar_file}" ] || { echo "Envar: can't open '${_envar_file}'" >&2; continue; }

      # shellcheck disable=SC1090
      . "${_envar_file}"
      ENVAR_LOADED+="${ENVAR_LOADED:+$'\n'}${_envar_file}"
    done <<< "${ENVAR_DESKS}"

    unset _envar_file

    # Set PS1
    ENVAR_PS1_ORIGIN="${ENVAR_PS1_ORIGIN-${PS1}}"
    [ -n "${ENVAR_DESK}" ] && PS1="$(
      # shellcheck disable=SC2030
      IGNORE_SUFFIX_FILE='{{ IGNORE_SUFFIX_FILE }}'

      if ! [ -e ~/"${IGNORE_SUFFIX_FILE}" ]; then
        # shellcheck disable=SC1090
        if (unset -f envar_suffix; . "${ENVAR_DESK}" &>/dev/null; declare -F envar_suffix &>/dev/null); then
          declare candidate; candidate="$(envar_suffix | grep '.\+')" && {
            printf -- '%s' "${ENVAR_PS1_ORIGIN}"
            tail -n 1 <<< "${ENVAR_PS1_ORIGIN}" | grep -q '\s\+$' || printf -- ' '
            tail -n 1 <<< "${candidate}" | grep -q '\s\+$' || candidate+=' '
            printf -- '%s' "${candidate}"

            exit
          }
        else
          basename -- "${ENVAR_DESK}" | rev | cut -d'.' -f2- | rev | {
            printf -- '%s' "${ENVAR_PS1_ORIGIN}"
            tail -n 1 <<< "${ENVAR_PS1_ORIGIN}" | grep -q '\s\+$' || printf -- ' '
            printf -- '%s > ' "$(cat)"
          }

          exit
        fi
      fi

      printf -- '%s' "${ENVAR_PS1_ORIGIN}"
    )"
  }

  # shellcheck disable=SC2120
  gen_entrypoint() {
    ${RUN_CONTEXT_ENVAR_zWilsdFI8I:-false} && {
      declare -f "${FUNCNAME[0]}" | tail -n +2
      return
    }

    if (return 0 2>/dev/null); then
      eval "$(envar gen_loader)"
    else
      envar "${@}"
    fi
  }

  # shellcheck disable=SC2016
  make_bin_file_code() {
    echo '#!/usr/bin/env bash'; echo
    declare -f -- "${THE_LIB}" | sed '/can_install_9eJxoPVOVB[=]/d'; echo
    declare -f -- "${THE_TOOL}"; echo
    echo 'eval "$('"${THE_TOOL}"' gen_entrypoint)"'
  }

  need_install() {
    # Compare to be installed code with current reflection, due to aliases
    # changing the internal representation of function (i.e. 'grep' => 'grep --color=auto')

    # shellcheck disable=SC2016,SC1090
    ! {
      make_bin_file_code | cmp -- - <(
        unset -f "${THE_LIB}" "${THE_TOOL}" &>/dev/null
        . "${BIN_FILE}" &>/dev/null

        make_bin_file_code
      ) \
      && cmp -- <(print_demo) "${DEMO_FILE}" \
      && cmp -- <(print_demo_desk) "${DEMO_DESK_FILE}"
    } &>/dev/null
  }

  install() {
    local can_install_9eJxoPVOVB=true

    ${can_install_9eJxoPVOVB-false} || {
      printf -- '%s\n' \
        "Can only install / upgrade with installation script. Last time saw it here:" \
        "  https://github.com/spaghetti-coder/ansible-basebook" \
        "Skipping ..." \
      >&2
      echo "unchanged"
      return
    }

    [ "$(id -u)" -eq 0 ] || {
      echo "Installation requires root privileges" >&2
      return 1
    }

    need_install || { echo "unchanged"; return; }

    local install_dir; install_dir="$(dirname -- "${BIN_FILE}")"
    (set -x; umask 0022; mkdir -p -- "${install_dir}") || return

    make_bin_file_code | (
      set -x
      tee -- "${BIN_FILE}" >/dev/null && chmod 0755 -- "${BIN_FILE}"
    ) || return

    # shellcheck disable=SC2031
    (set -x; umask 0022; mkdir -p -- "${GLOBAL_DIR}") || return

    print_demo | (set -x; umask 0022; tee -- "${DEMO_FILE}" >/dev/null) || return
    print_demo_desk | (set -x; umask 0022; tee -- "${DEMO_DESK_FILE}" >/dev/null) || return

    echo "done"
  }

  print_help() {
    local the_script="${0}"
    { cat -- "${0}" | head -c 10 | grep '#!'; } &>/dev/null || the_script=envar.sh
    the_script="$(basename -- "${the_script}")"

    # shellcheck disable=SC2001,SC2016,SC2031
    sed -e '/^\s*$/d' -e 's/^\s*//' -e 's/^,//' <<< "
      This tool unclutters you .bashrc by autoloading environments from ${GLOBAL_DIR}
      and ~/${USER_DIR_SUFFIX} directories and using desks.
     ,
      INITIALIZATION:
      ==============
      # Install the tool (requires root privileges)
      ${the_script} install
     ,
      # Initialize for the current user. Running under the root this operation will
      # install the tool when it's not installed yet
      ${the_script} init    # <- Implicitly with root argument
      . ~/.bashrc     # <- Refresh bash environment, see ${DEMO_FILE}
      declare -F ${THE_TOOL}    # <- Check the tool is loaded
     ,
      # Initialize for anouther user (requires root privileges)
      ${the_script} init another-user
     ,
      USAGE:
      ==============
      ${THE_TOOL} path/to/desk.sh   # <- Load desk, see ${DEMO_DESK_FILE}
      ${THE_TOOL} loaded            # <- View all loaded files
      ${THE_TOOL} desks             # <- View all loaded desk files
      ${THE_TOOL} req               # <- View all requested files
    "
  }

  print_demo() {
    # shellcheck disable=SC2001,SC2016,SC2031
    sed -e '/^\s*$/d' -e 's/^\s*//' -e 's/^,//' <<< '
      #!/usr/bin/env bash
     ,
      # All *.sh and *.env files under ~/'"${USER_DIR_SUFFIX}"' loaded to the
      # current shell but *.skip.sh and *.skip.env files, they are ignored.
      # Subdirectories are ignored.
      #
      # Same applies to '"${GLOBAL_DIR}"' directory. To disable it:
      #   touch ~/'"${IGNORE_GLOBAL_FILE}"'
      #
      # This is a demo env that will not be loaded and serves as an example
      # as if it is loaded
     ,
      MY_VAR="demo value"   # <- Will be exported to the current shell
     ,
      my_func() { echo "demo func"; } # <- Will be exported to the current shell
    '
  }

  print_demo_desk() {
    # shellcheck disable=SC2001,SC2016,SC2031
    sed -e '/^\s*$/d' -e 's/^\s*//' -e 's/^,//' <<< '
      #!/usr/bin/env bash
     ,
      # Desk files are meant to be loaded individually with:
      #   '"${THE_TOOL} path/to/desk-file.sh"'  # <- Only *.sh and *.env supported
      # This will load a subshell with environment from the desk
      #
      # By default loaded desk appends desk file name (without extension) and
      # arrow to PS1: '\''DEFAULT_PS1 DESK_SUFFIX > '\''
      #
      # ```
      # # Usage demo:
      # touch ~/'"${IGNORE_SUFFIX_FILE}"'   # <- Disable PS1 suffixing
      # '"${THE_TOOL} ${DEMO_DESK_FILE}"'       # <- Load the current desk
      # ```
     ,
      MY_VAR="demo value"
     ,
      # envar_suffix() { echo "my-desk > "; }   # <- Custom PS1 suffix
      # envar_suffix() { return; }              # <- Dont'\'' PS1 suffix the desk
    '
  }

  init() {
    local user="${1:-$(id -u -n)}"
    local changed=false

    user="$(id -u -n -- "${user}")" || return

    need_install && {
      echo "Installation or update required. Attempting ..." >&2

      local result; result="$(install)" || return
      [ "${result}" = 'done' ] && changed=true
    }

    if [ "$(id -u -n -- "${user}")" = "$(id -u -n)" ]; then
      if ! /usr/bin/env bash -i -c "
        unset -f -- '${THE_TOOL}'
        . ~/.bashrc; declare -F -- '${THE_TOOL}'
      " &>/dev/null; then
        {
          grep -q '.\+' ~/.bashrc 2>/dev/null && echo
          printf -- '%s\n' ". '${BIN_FILE}'"
        } | (
          set -x; umask 0077; tee -a ~/.bashrc >/dev/null
        ) || return

        changed=true
      fi

      if { cat ~/.bash_profile || ! cat ~/.profile; } &>/dev/null; then
        # .profile doesn't get loaded when .bash_profile exists

        if ! /usr/bin/env bash -i -c "
          unset -f -- '${THE_TOOL}'
          . ~/.bash_profile; declare -F -- '${THE_TOOL}'
        " &>/dev/null; then
          {
            grep -q '.\+' ~/.bash_profile 2>/dev/null && echo
            printf -- '%s\n' \
              'if [ -f ~/.bashrc ]; then' \
              '  . ~/.bashrc' \
              'fi'
          } | (
            set -x; umask 0077; tee -a ~/.bash_profile >/dev/null
          ) || return

          changed=true
        fi
      elif ! /usr/bin/env bash -i -c "
        unset -f -- '${THE_TOOL}'
        . ~/.profile; declare -F -- '${THE_TOOL}'
      " &>/dev/null; then
        {
          grep -q '.\+' ~/.profile 2>/dev/null && echo
          # shellcheck disable=SC2016
          printf -- '%s\n' \
            'if [ -n "$BASH_VERSION" ]; then' \
            '  if [ -f ~/.bashrc ]; then' \
            '    . ~/.bashrc' \
            '  fi' \
            'fi'
        } | (
          set -x; umask 0077; tee -a ~/.profile >/dev/null
        ) || return

        changed=true
      fi
    elif [[ $(id -u) -eq 0 ]]; then
      local result; result="$(
        su -l "${user}" -s /bin/bash -c "$(declare -f); ${THE_LIB} ${FUNCNAME[0]}"
      )" || return

      [ "${result}" = 'done' ] && changed=true
    else
      echo "Can't init for '${user}' without root privileges" >&2
      return 1
    fi

    if ${changed}; then
      echo "done"
    else
      echo "unchanged"
    fi
  }

  "${@}"
)

envar() {
  local arg="${1}"; shift

  local the_lib=_envar_lib
  declare -a IMPORTED=(
    # Action functions
    loaded
    desks
    req
    # Service functions
    gen_entrypoint
    gen_loader
    # Setup functions
    install
    init
  )

  if [[ "${arg}" =~ ^(-\?|-h|--help)$ ]]; then
    "${the_lib}" print_help; return
  fi

  printf -- '%s\n' "${IMPORTED[@]}" | grep -qFx -- "${arg}" && {
    "${the_lib}" "${arg}" "${@}"; return
  }

  if true \
      && grep -q -- '\.\(sh\|env\)$' <<< "${arg}" \
      && cat -- "${arg}" &>/dev/null \
  ; then
    # shellcheck disable=SC2031
    ENVAR_DESKS="${ENVAR_DESKS}" ENVAR_DESK="${arg}" /usr/bin/env bash
    return
  fi

  echo "Envar: Invalid command '${arg}'" >&2
  return 1
}

eval "$(envar gen_entrypoint)"
