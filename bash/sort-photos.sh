#!/bin/bash

# Sort photos and videos into:
# Destination/YYYY/YYYY-MM/
#
# Usage:
#   ./sort-photos.sh "/path/to/source" "/path/to/destination"

set -u

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source-folder> <destination-folder>"
    exit 1
fi

SOURCE="${1%/}"
DESTINATION="${2%/}"

if [ ! -d "$SOURCE" ]; then
    echo "Error: Source folder does not exist:"
    echo "$SOURCE"
    exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
    echo "Error: exiftool is not installed."
    echo "Install it with:"
    echo "  brew install exiftool"
    exit 1
fi

mkdir -p "$DESTINATION"

copied=0
skipped=0
failed=0

copy_with_unique_name() {
    local source_file="$1"
    local target_directory="$2"
    local filename
    local basename
    local extension
    local target
    local counter

    filename="$(basename "$source_file")"

    # Separate filename and extension.
    if [[ "$filename" == *.* ]]; then
        basename="${filename%.*}"
        extension=".${filename##*.}"
    else
        basename="$filename"
        extension=""
    fi

    target="$target_directory/$filename"
    counter=1

    # If a file with the same name exists, add a numeric suffix.
    while [ -e "$target" ]; do
        target="$target_directory/${basename}_$counter${extension}"
        counter=$((counter + 1))
    done

    if cp -p "$source_file" "$target"; then
        echo "Copied: $source_file"
        echo "     -> $target"
        copied=$((copied + 1))
    else
        echo "Failed: $source_file" >&2
        failed=$((failed + 1))
    fi
}

while IFS= read -r -d '' file; do
    relative_date=""

    # Prefer the original camera capture date.
    relative_date="$(exiftool \
        -s3 \
        -d "%Y/%Y-%m" \
        -DateTimeOriginal \
        "$file" 2>/dev/null)"

    # Fall back to media creation date.
    if [ -z "$relative_date" ]; then
        relative_date="$(exiftool \
            -s3 \
            -d "%Y/%Y-%m" \
            -CreateDate \
            "$file" 2>/dev/null)"
    fi

    # Fall back to the file's modification date.
    if [ -z "$relative_date" ]; then
        relative_date="$(exiftool \
            -s3 \
            -d "%Y/%Y-%m" \
            -FileModifyDate \
            "$file" 2>/dev/null)"
    fi

    if [ -z "$relative_date" ]; then
        echo "Skipped—no usable date: $file"
        skipped=$((skipped + 1))
        continue
    fi

    target_directory="$DESTINATION/$relative_date"
    mkdir -p "$target_directory"

    copy_with_unique_name "$file" "$target_directory"

done < <(
    find "$SOURCE" -type f \( \
        -iname "*.jpg"  -o \
        -iname "*.jpeg" -o \
        -iname "*.heic" -o \
        -iname "*.heif" -o \
        -iname "*.png"  -o \
        -iname "*.tif"  -o \
        -iname "*.tiff" -o \
        -iname "*.dng"  -o \
        -iname "*.raf"  -o \
        -iname "*.nef"  -o \
        -iname "*.cr2"  -o \
        -iname "*.cr3"  -o \
        -iname "*.arw"  -o \
        -iname "*.orf"  -o \
        -iname "*.rw2"  -o \
        -iname "*.mov"  -o \
        -iname "*.mp4"  -o \
        -iname "*.m4v" \
    \) -print0
)

echo
echo "Finished."
echo "Copied: $copied"
echo "Skipped: $skipped"
echo "Failed: $failed"