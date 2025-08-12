# Function to execute a command in each (sub)directory
# Usage:
#   recur [-p|--parallel] [-r|--recursive] [--max-depth N] [--exclude pat] [-n|--dry-run] [-L|--list] [-f|--force] -- <command ...>
recur() {
    # Ensure zsh uses 0-based arrays like bash (no effect in bash)
    [[ -n $ZSH_VERSION ]] && setopt local_options KSH_ARRAYS
    
    # Use zsh colors if available
    local use_colors=false
    local dir_color header_color cmd_color info_color hint_color success_color
    if [[ -n $ZSH_VERSION ]] && whence -w colors >/dev/null 2>&1; then
        use_colors=true
        # Let zsh handle colors function loading
        colors >/dev/null 2>&1
        dir_color=$fg_bold[blue]
        header_color=$fg_bold[cyan]
        cmd_color=$fg[yellow]
        info_color=$fg[green]
        hint_color=$fg[cyan]
        success_color=$fg_bold[green]
        reset_color=${reset_color:-$'\e[0m'}
    fi

    local parallel=false recursive=false max_depth= dry_run=false list_only=false force=false
    local expand=false
    # Default directories/files to skip descending into (can be extended with --exclude)
    local -a default_excludes=( # treat as "do not descend / skip if directory (or just prune the file match)"
        .git
        node_modules
        .venv
        .env
        .envs
        .env.d
        dist
        build
        target
        .cache
        .mypy_cache
        .pytest_cache
        .terraform
        .idea
        .vscode
    )
    # Working excludes array (starts with defaults, user can append)
    local -a excludes=("${default_excludes[@]}")
    local -a cmd_parts=()

    # Parse flags until -- or first command token
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--parallel) parallel=true; shift ;;
            -r|--recursive) recursive=true; shift ;;
            --max-depth) shift; [[ $1 =~ ^[0-9]+$ ]] || { echo "Invalid --max-depth"; return 1; }; max_depth=$1; shift ;;
            --exclude) shift; [[ -n $1 ]] || { echo "Missing pattern after --exclude"; return 1; }; excludes+=("$1"); shift ;;
            -n|--dry-run) dry_run=true; shift ;;
            -L|--list) list_only=true; shift ;;
            -f|--force) force=true; shift ;;
            -x|--expand) expand=true; shift ;;
            --) shift; break ;;
            -h|--help)
                echo "Usage: recur [-p] [-r] [--max-depth N] [--exclude pat] [-n] [-L] [-f] [-x] -- <command ...>"
                echo "Defaults excluded: ${default_excludes[*]}"
                echo "  -x / --expand : with -n, show per-directory expanded commands"
                return 0 ;;
            -*) echo "Unknown flag: $1"; return 1 ;;
            *) break ;;
        esac
    done

    # Remaining args = command
    (( $# == 0 )) && { echo "No command specified. Use -- to separate flags from command."; return 1; }
    cmd_parts=("$@")

    # Confirmation for obvious destructive rm unless forced
    if ! $force && [[ ${cmd_parts[0]} == rm ]]; then
        for a in "${cmd_parts[@]}"; do
            [[ $a == -rf || $a == -fr ]] && {
                read -r "?Confirm running '${cmd_parts[*]}' in multiple dirs (y/N): " ans
                [[ $ans == [Yy]* ]] || { echo "Aborted."; return 1; }
                break
            }
        done
    fi

    # Collect directories
    local -a dirs=()
    if $recursive; then
        # Build find command as array
        local -a find_cmd=(find .)
        [[ -n $max_depth ]] && find_cmd+=(-maxdepth "$max_depth")
        # Prune expression
        if ((${#excludes[@]})); then
            find_cmd+=( \( )
            local first=true
            for ex in "${excludes[@]}"; do
                $first || find_cmd+=(-o)
                first=false
                find_cmd+=( -name "$ex" )
            done
            # CLOSE the group, then prune
            find_cmd+=( \) -prune -o )
        fi
        find_cmd+=( -type d -print0 )
        while IFS= read -r -d '' d; do
            [[ $d == . ]] && continue
            dirs+=("${d#./}")
        done < <("${find_cmd[@]}")
    else
        for d in */; do
            [[ -d $d ]] || continue
            local base=${d%/}
            for ex in "${excludes[@]}"; do
                [[ $base == "$ex" ]] && continue 2
            done
            dirs+=("$base")
        done
    fi

    (( ${#dirs[@]} == 0 )) && { echo "No target directories."; return 0; }

    # Modify output with colors
    if $list_only; then
        $use_colors && printf "${header_color}Found directories:${reset_color}\n"
        printf '%s\n' "${dirs[@]}"
        return 0
    fi

    $use_colors && {
        printf "${header_color}Command:${reset_color} ${cmd_color}%s${reset_color}\n" "${cmd_parts[*]}"
        printf "${header_color}Target directories:${reset_color} ${info_color}%d${reset_color}\n" "${#dirs[@]}"
    } || {
        echo "Command: ${cmd_parts[*]}"
        echo "Dirs: ${#dirs[@]}"
    }
    
    $dry_run && {
        if $list_only || ! $expand; then
            $use_colors && printf "${header_color}DRY-RUN directories:${reset_color}\n" || printf 'DRY-RUN directories:\n'
            $use_colors && printf "  ${info_color}%s${reset_color}\n" "${dirs[@]}" || printf '  %s\n' "${dirs[@]}"
        fi
        if $expand; then
            $use_colors && printf "${header_color}DRY-RUN expanded commands:${reset_color}\n" || printf 'DRY-RUN expanded commands:\n'
            for dir in "${dirs[@]}"; do
                # Build prefixed variant (skip command itself and obvious flags / absolute / ./ ../)
                local -a expanded_parts=()
                local i
                for ((i=0; i<${#cmd_parts[@]}; i++)); do
                    local part=${cmd_parts[i]}
                    if (( i == 0 )) || [[ $part == -* || $part == /* || $part == ./* || $part == ../* ]]; then
                        expanded_parts+=("$part")
                    else
                        expanded_parts+=("$dir/$part")
                    fi
                done
                # Form 1: actual execution form (cd dir && cmd args...)
                if $use_colors; then
                    printf "  ${hint_color}(cd %s &&${reset_color}" "$dir"
                    for p in "${cmd_parts[@]}"; do
                        printf " ${cmd_color}%q${reset_color}" "$p"
                    done
                    printf "${hint_color} )${reset_color}\n"
                    printf "      ${hint_color}->${reset_color}"
                    for p in "${expanded_parts[@]}"; do
                        printf " ${cmd_color}%q${reset_color}" "$p"
                    done
                else
                    printf '  (cd %s &&' "$dir"
                    for p in "${cmd_parts[@]}"; do
                        printf ' %q' "$p"
                    done
                    printf ' )\n'
                    printf '      ->'
                    for p in "${expanded_parts[@]}"; do
                        printf ' %q' "$p"
                    done
                fi
                printf '\n'
            done
        fi
        return 0
    }

    # Execution output
    if $parallel; then
        if command -v parallel &>/dev/null; then
            local tag_format=">>> {1}"
            $use_colors && tag_format="${dir_color}>>> {1}${reset_color}"
            printf '%s\n' "${dirs[@]}" | parallel --no-notice --tagstring "$tag_format" bash -c '
                cd "$1" || exit 1
                "${@:2}"
            ' bash {} "${cmd_parts[@]}"
        else
            for dir in "${dirs[@]}"; do
                (
                    cd "$dir" || exit
                    if $use_colors; then
                        printf "\n${dir_color}>>> %s${reset_color}\n" "$dir"
                    else
                        echo -e "\n>>> $dir"
                    fi
                    "${cmd_parts[@]}"
                ) &
            done
            wait
        fi
    else
        for dir in "${dirs[@]}"; do
            (
                cd "$dir" || exit
                if $use_colors; then
                    printf "\n${dir_color}>>> %s${reset_color}\n" "$dir"
                else
                    echo -e "\n>>> $dir"
                fi
                "${cmd_parts[@]}"
            )
        done
    fi
    
    if $use_colors; then
        printf "${success_color}Done.${reset_color}\n"
    else
        echo "Done."
    fi
}