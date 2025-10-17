recur() {
    [[ -n $ZSH_VERSION ]] && setopt local_options KSH_ARRAYS

    # Colors (both zsh and bash)
    local use_colors=false dir_color header_color cmd_color info_color hint_color success_color error_color reset_color
    if [[ -t 1 ]]; then  # stdout is a terminal
        if [[ -n $ZSH_VERSION ]]; then
            use_colors=true
            autoload -U colors && colors
            dir_color=$'\e[1;34m'; header_color=$'\e[1;36m'; cmd_color=$'\e[33m'
            info_color=$'\e[32m'; hint_color=$'\e[36m'; success_color=$'\e[1;32m'
            error_color=$'\e[1;31m'; reset_color=$'\e[0m'
        elif [[ -n $BASH_VERSION ]]; then
            use_colors=true
            dir_color=$'\e[1;34m'; header_color=$'\e[1;36m'; cmd_color=$'\e[33m'
            info_color=$'\e[32m'; hint_color=$'\e[36m'; success_color=$'\e[1;32m'
            error_color=$'\e[1;31m'; reset_color=$'\e[0m'
        fi
    fi

    local parallel=false recursive=false max_depth= dry_run=false list_only=false force=false expand=false verbose=false jobs=0
    local -a default_excludes=(.git node_modules .venv .env .envs .env.d dist build target .cache .mypy_cache .pytest_cache .terraform .idea .vscode)
    local -a excludes=("${default_excludes[@]}")
    local -a cmd_parts=()

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
            -v|--verbose) verbose=true; shift ;;
            -j|--jobs) shift; [[ $1 =~ ^[0-9]+$ ]] || { echo "Invalid --jobs"; return 1; }; jobs=$1; shift ;;
            --) shift; break ;;
            -h|--help)
                echo "Usage: recur [-p] [-r] [--max-depth N] [--exclude pat] [-n] [-L] [-f] [-x] [-v] [-j N] -- <command ...>"
                echo "  -p / --parallel   : Run commands in parallel"
                echo "  -r / --recursive  : Search directories recursively"
                echo "  --max-depth N     : Limit recursion depth"
                echo "  --exclude pattern : Exclude directories matching pattern"
                echo "  -n / --dry-run    : Show what would be executed"
                echo "  -L / --list       : List directories only (with -n)"
                echo "  -f / --force      : Skip confirmation prompts"
                echo "  -x / --expand     : Show expanded commands (with -n)"
                echo "  -v / --verbose    : Show detailed execution info"
                echo "  -j / --jobs N     : Limit parallel jobs (requires GNU parallel)"
                echo "Defaults excluded: ${default_excludes[*]}"
                return 0 ;;
            -*) echo "Unknown flag: $1"; return 1 ;;
            *) break ;;
        esac
    done

    (( $# == 0 )) && { echo "No command specified. Use -- to separate flags from command."; return 1; }

    # Capture command
    cmd_parts=("$@")

    # Determine if we need shell evaluation
    needs_shell() {
        (( ${#cmd_parts[@]} == 1 )) && return 0
        
        local t joined="${cmd_parts[*]}"
        
        # Check for shell metacharacters (escape pipe and ampersand outside character class)
        [[ $joined =~ [\\\;\<\>\(\)\{\}\$\`\[\]\'\"] ]] && return 0
        [[ $joined == *'|'* || $joined == *'&'* ]] && return 0
        
        # Check for glob patterns
        [[ $joined =~ [\*\?] ]] && return 0
        [[ $joined == *'['* ]] && return 0
        
        # Check individual tokens for operators
        for t in "${cmd_parts[@]}"; do
            case $t in
                '&&'|'||'|'|'|';'|'>'|'<'|'>>'|'2>'|'2>&1'|'&') return 0 ;;
            esac
        done
        
        return 1
    }

    local use_shell=false
    local cmd_string=""
    
    if needs_shell; then
        use_shell=true
        cmd_string="${cmd_parts[*]}"
    fi

    # Confirm destructive commands
    if ! $force && ! $dry_run; then
        local needs_confirm=false
        if [[ ${cmd_parts[0]} == rm ]]; then
            local a
            for a in "${cmd_parts[@]}"; do
                [[ $a == -rf || $a == -fr || $a == -r || $a == -R || $a == --recursive ]] && {
                    needs_confirm=true
                    break
                }
            done
        fi
        
        if $needs_confirm; then
            local ans
            read -r "?${error_color}Warning:${reset_color} Confirm running '${cmd_parts[*]}' in multiple dirs (y/N): " ans
            [[ $ans == [Yy]* ]] || { echo "Aborted."; return 1; }
        fi
    fi

    # Collect directories
    local -a dirs=()
    if $recursive; then
        local -a find_cmd=(find .)
        [[ -n $max_depth ]] && find_cmd+=(-maxdepth "$max_depth")
        if ((${#excludes[@]})); then
            find_cmd+=( \( )
            local first=true ex
            for ex in "${excludes[@]}"; do
                $first || find_cmd+=(-o)
                first=false
                find_cmd+=( -name "$ex" )
            done
            find_cmd+=( \) -prune -o )
        fi
        find_cmd+=( -type d -print0 )
        while IFS= read -r -d '' d; do
            [[ $d == . ]] && continue
            dirs+=("${d#./}")
        done < <("${find_cmd[@]}")
    else
        local d base ex skip
        for d in */; do
            [[ -d $d ]] || continue
            base=${d%/}
            skip=false
            for ex in "${excludes[@]}"; do
                if [[ $base == "$ex" ]]; then
                    skip=true
                    break
                fi
            done
            $skip && continue
            dirs+=("$base")
        done
    fi

    (( ${#dirs[@]} == 0 )) && { echo "No target directories."; return 0; }

    # Header
    if $use_colors; then
        printf "${header_color}Command:${reset_color} ${cmd_color}%s${reset_color}\n" "${cmd_parts[*]}"
        printf "${header_color}Target directories:${reset_color} ${info_color}%d${reset_color}\n" "${#dirs[@]}"
        $parallel && printf "${header_color}Mode:${reset_color} ${info_color}Parallel${reset_color}\n"
    else
        echo "Command: ${cmd_parts[*]}"
        echo "Dirs: ${#dirs[@]}"
        $parallel && echo "Mode: Parallel"
    fi

    # Dry-run handling
    if $dry_run; then
        if $list_only || ! $expand; then
            $use_colors && printf "${header_color}DRY-RUN directories:${reset_color}\n" || printf 'DRY-RUN directories:\n'
            printf '  %s\n' "${dirs[@]}"
        fi
        if $expand; then
            $use_colors && printf "${header_color}DRY-RUN expanded commands:${reset_color}\n" || printf 'DRY-RUN expanded commands:\n'
            local dir p
            for dir in "${dirs[@]}"; do
                if $use_shell; then
                    if $use_colors; then
                        printf "  ${hint_color}(cd %s &&${reset_color} ${cmd_color}%s${reset_color} ${hint_color})${reset_color}\n" "$dir" "$cmd_string"
                    else
                        printf '  (cd %s && %s )\n' "$dir" "$cmd_string"
                    fi
                else
                    if $use_colors; then
                        printf "  ${hint_color}(cd %s &&${reset_color}" "$dir"
                        for p in "${cmd_parts[@]}"; do printf " ${cmd_color}%q${reset_color}" "$p"; done
                        printf "${hint_color} )${reset_color}\n"
                    else
                        printf '  (cd %s &&' "$dir"
                        for p in "${cmd_parts[@]}"; do printf ' %q' "$p"; done
                        printf ' )\n'
                    fi
                fi
            done
        fi
        return 0
    fi

    # Execute command in a directory
    execute_in_dir() {
        local dir=$1
        
        if $verbose && ! $parallel; then
            if $use_colors; then
                printf "\n${dir_color}>>> %s${reset_color}\n" "$dir"
            else
                printf '\n>>> %s\n' "$dir"
            fi
        fi
        
        cd "$dir" || return 1
        
        if $use_shell; then
            eval "$cmd_string"
        else
            "${cmd_parts[@]}"
        fi
    }

    # Track failures
    local -a failed_dirs=()
    local overall_status=0

    # Execution
    if $parallel; then
        if command -v parallel &>/dev/null; then
            local tag_format=">>> {1}"
            $use_colors && tag_format="${dir_color}>>> {1}${reset_color}"

            local parallel_opts=(--no-notice --tagstring "$tag_format")
            (( jobs > 0 )) && parallel_opts+=(--jobs "$jobs")

            # Prepare env vars for parallel workers and capture failures manually
            local RECUR_FAIL_FILE
            RECUR_FAIL_FILE=$(mktemp)
            export RECUR_FAIL_FILE

            if $use_shell; then
                export RECUR_CMD_STRING="$cmd_string"
                printf '%s\0' "${dirs[@]}" | parallel -0 "${parallel_opts[@]}" 'cd {} && ( eval "$RECUR_CMD_STRING" ) || echo {} >> "$RECUR_FAIL_FILE"'
            else
                local RECUR_ARGSTRING
                printf -v RECUR_ARGSTRING '%q ' "${cmd_parts[@]}"
                export RECUR_ARGSTRING
                printf '%s\0' "${dirs[@]}" | parallel -0 "${parallel_opts[@]}" 'cd {} && ( eval "set -- $RECUR_ARGSTRING"; "$@" ) || echo {} >> "$RECUR_FAIL_FILE"'
            fi

            if [[ -s $RECUR_FAIL_FILE ]]; then
                # Check if mapfile is available (Bash 4.0+)
                if type mapfile &>/dev/null; then
                    mapfile -t failed_dirs < "$RECUR_FAIL_FILE"
                else
                    # Fallback to a manual method if mapfile is not available
                    failed_dirs=()
                    while IFS= read -r line; do
                        failed_dirs+=("$line")
                    done < "$RECUR_FAIL_FILE"
                fi

                overall_status=1
                if $use_colors; then
                    printf "\n${error_color}Some directories failed.${reset_color}\n"
                else
                    echo -e "\nSome directories failed."
                fi
            fi

            rm -f "$RECUR_FAIL_FILE"
        else
            # Fallback: background processes with error tracking
            $verbose && echo "GNU parallel not found, using fallback parallel execution"
            set +m
            local temp_dir=$(mktemp -d)
            
            # Run all jobs in background, capturing output to temp files
            {
                local idx=0
                for dir in "${dirs[@]}"; do
                    {
                        if $use_colors; then
                            printf "\n${dir_color}>>> %s${reset_color}\n" "$dir"
                        else
                            printf '\n>>> %s\n' "$dir"
                        fi
                        
                        cd "$dir" || exit 1
                        
                        if $use_shell; then
                            eval "$cmd_string"
                        else
                            "${cmd_parts[@]}"
                        fi
                        
                        echo $? > "$temp_dir/$idx.exit"
                    } &
                    echo $! > "$temp_dir/$idx.pid"
                    ((idx++))
                done
                
                # Wait for all background jobs
                wait
            } 2>&1
            
            # Check exit codes
            local idx=0
            for dir in "${dirs[@]}"; do
                if [[ -f "$temp_dir/$idx.exit" ]]; then
                    local exit_code=$(cat "$temp_dir/$idx.exit")
                    if (( exit_code != 0 )); then
                        failed_dirs+=("$dir")
                        overall_status=1
                    fi
                fi
                ((idx++))
            done
            
            rm -rf "$temp_dir"
        fi
    else
        # Serial execution
        for dir in "${dirs[@]}"; do
            (
                set -o pipefail
                execute_in_dir "$dir"
            )
            local exit_code=$?
            if (( exit_code != 0 )); then
                failed_dirs+=("$dir")
                overall_status=1
                $use_colors && printf "${error_color}Failed in: %s${reset_color}\n" "$dir" || echo "Failed in: $dir"
            fi
        done
    fi

    # Report results
    if (( ${#failed_dirs[@]} > 0 )); then
        if $use_colors; then
            printf "\n${error_color}Failed in %d directories:${reset_color}\n" "${#failed_dirs[@]}"
        else
            printf '\nFailed in %d directories:\n' "${#failed_dirs[@]}"
        fi
        printf '  %s\n' "${failed_dirs[@]}"
        return "$overall_status"
    else
        $use_colors && printf "\n${success_color}Done. All succeeded.${reset_color}\n" || echo -e "\nDone. All succeeded."
        return 0
    fi
}