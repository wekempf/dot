# Herdr configuration
if command -v herdr >/dev/null 2>&1 && command -v direnv >/dev/null 2>&1; then
  # Configure a directory to select a named Herdr session through direnv.
  herdr-root() {
    emulate -L zsh

    local target_path="$PWD"
    local session_name=""
    local envrc tmp declaration
    local session_name_pattern='^[A-Za-z0-9._-]+$'

    while (( $# )); do
      case "$1" in
        --path)
          (( $# >= 2 )) || {
            print -u2 "herdr-root: --path requires a value"
            return 2
          }
          target_path="$2"
          shift 2
          ;;
        --path=*)
          target_path="${1#*=}"
          shift
          ;;
        --session-name)
          (( $# >= 2 )) || {
            print -u2 "herdr-root: --session-name requires a value"
            return 2
          }
          session_name="$2"
          shift 2
          ;;
        --session-name=*)
          session_name="${1#*=}"
          shift
          ;;
        -h|--help)
          print "usage: herdr-root [--path PATH] [--session-name NAME]"
          return 0
          ;;
        *)
          print -u2 "herdr-root: unknown argument: $1"
          print -u2 "usage: herdr-root [--path PATH] [--session-name NAME]"
          return 2
          ;;
      esac
    done

    [[ -d "$target_path" ]] || {
      print -u2 "herdr-root: directory does not exist: $target_path"
      return 1
    }
    target_path="$(builtin cd -- "$target_path" && pwd -P)" || return 1

    [[ -n "$session_name" ]] || session_name="${target_path:t}"
    if (( ${#session_name} > 64 )) ||
       [[ "$session_name" == "." || "$session_name" == ".." ]] ||
       [[ ! "$session_name" =~ $session_name_pattern ]]; then
      print -u2 "herdr-root: session name must be 1-64 ASCII letters, numbers, '.', '_' or '-'"
      return 2
    fi

    envrc="$target_path/.envrc"
    tmp="$(mktemp "${TMPDIR:-/tmp}/herdr-root.XXXXXX")" || return 1
    declaration="export HERDR_SESSION=$session_name"

    if [[ -e "$envrc" ]]; then
      awk -v declaration="$declaration" '
        /^[[:space:]]*(export[[:space:]]+)?HERDR_SESSION[[:space:]]*=/ {
          if (!replaced) print declaration
          replaced = 1
          next
        }
        { print }
        END { if (!replaced) print declaration }
      ' "$envrc" >| "$tmp" || {
        rm -f -- "$tmp"
        print -u2 "herdr-root: failed to update $envrc"
        return 1
      }
    else
      print -r -- "$declaration" >| "$tmp" || {
        rm -f -- "$tmp"
        print -u2 "herdr-root: failed to create $envrc"
        return 1
      }
    fi

    if [[ -e "$envrc" ]]; then
      command cat -- "$tmp" >| "$envrc" || {
        rm -f -- "$tmp"
        print -u2 "herdr-root: failed to write $envrc"
        return 1
      }
      rm -f -- "$tmp"
    else
      command mv -- "$tmp" "$envrc" || {
        rm -f -- "$tmp"
        print -u2 "herdr-root: failed to create $envrc"
        return 1
      }
    fi

    direnv allow "$envrc" || return 1
    print "Configured $target_path to use Herdr session '$session_name'."
  }
fi
