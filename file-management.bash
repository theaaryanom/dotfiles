
# ==========================================================
# VOID - FILE MANAGEMENT
# ==========================================================

# START FUNCTION: mkcd
# Create a directory and navigate into it.
# Usage: mkcd <directory>

mkcd() {
    if (( $# != 1 )); then
        printf 'Usage: mkcd <directory>\n'
        return 2
    fi

    mkdir -p -- "$1" && builtin cd -- "$1"
}
# END FUNCTION: mkcd


# START FUNCTION: extract
# Extract supported archive formats.
# Usage: extract <archive> [destination]

extract() {
    if (( $# < 1 || $# > 2 )); then
        printf 'Usage: extract <archive> [destination]\n'
        return 2
    fi

    local archive="$1"
    local destination="${2:-.}"
    local filename="${archive##*/}"
    local output
    local status

    if [[ ! -f "$archive" ]]; then
        printf 'Error: Archive not found: %s\n' "$archive"
        return 1
    fi

    [[ "$archive" = /* ]] || archive="$PWD/$archive"

    mkdir -p -- "$destination" || return 1

    case "$filename" in
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$destination"
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$archive" -C "$destination"
            ;;
        *.tar.xz|*.txz)
            tar -xJf "$archive" -C "$destination"
            ;;
        *.tar.zst)
            tar --zstd -xf "$archive" -C "$destination"
            ;;
        *.tar)
            tar -xf "$archive" -C "$destination"
            ;;
        *.zip)
            command -v unzip >/dev/null 2>&1 || {
                printf 'Error: unzip is not installed.\n'
                return 1
            }
            unzip -q "$archive" -d "$destination"
            ;;
        *.gz)
            output="${filename%.gz}"
            gzip -dc -- "$archive" > "$destination/$output"
            ;;
        *.bz2)
            output="${filename%.bz2}"
            bzip2 -dc -- "$archive" > "$destination/$output"
            ;;
        *.xz)
            output="${filename%.xz}"
            xz -dc -- "$archive" > "$destination/$output"
            ;;
        *.7z)
            command -v 7z >/dev/null 2>&1 || {
                printf 'Error: 7z is not installed.\n'
                return 1
            }
            7z x -y "-o$destination" "$archive"
            ;;
        *.rar)
            if command -v unrar >/dev/null 2>&1; then
                unrar x -o+ "$archive" "$destination/"
            elif command -v 7z >/dev/null 2>&1; then
                7z x -y "-o$destination" "$archive"
            else
                printf 'Error: Install unrar or 7z.\n'
                return 1
            fi
            ;;
        *)
            printf 'Error: Unsupported archive format: %s\n' "$filename"
            return 2
            ;;
    esac

    status=$?

    if (( status == 0 )); then
        printf 'Extraction completed: %s\n' "$destination"
    else
        printf 'Extraction failed: %s\n' "$filename"
    fi

    return "$status"
}
# END FUNCTION: extract

# START FUNCTION: fileinfo
# Display detailed file information.
# Usage: fileinfo <file> [file...]

fileinfo() {
    if (( $# == 0 )); then
        printf 'Usage: fileinfo <file> [file...]\n'
        return 2
    fi

    local target

    for target in "$@"; do

        if [[ ! -e "$target" && ! -L "$target" ]]; then
            printf '\nError: File not found: %s\n' "$target"
            continue
        fi

        printf '\n========== %s ==========\n' "$target"

        stat --printf='Type: %F\nSize: %s bytes\nPermissions: %A (%a)\nOwner: %U:%G\nModified: %y\n' -- "$target"

        printf 'MIME/Type: '
        file -b -- "$target"

        if [[ -L "$target" ]]; then
            printf 'Symlink target: '
            readlink -- "$target"
        fi

    done
}
# END FUNCTION: fileinfo

# ==========================================================
# END FILE MANAGEMENT
# ==========================================================
