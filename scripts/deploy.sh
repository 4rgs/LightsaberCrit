#!/usr/bin/env bash
set -euo pipefail

addon_name="LightsaberCrit"
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zip_path="${repo_dir}/${addon_name}.zip"

rm -f "$zip_path"

target_dir="${WOW_ADDONS_DIR:-}"

if [[ -z "$target_dir" ]]; then
    parent_dir="$(dirname "$repo_dir")"
    if [[ "$(basename "$parent_dir")" == "AddOns" ]]; then
        target_dir="$parent_dir"
    fi
fi

if [[ -z "$target_dir" ]]; then
    candidates=(
        "/Applications/World of Warcraft/_classic_era_/Interface/AddOns"
        "/Applications/World of Warcraft/_classic_/Interface/AddOns"
        "/Applications/World of Warcraft/_retail_/Interface/AddOns"
        "$HOME/Applications/World of Warcraft/_classic_era_/Interface/AddOns"
        "$HOME/Applications/World of Warcraft/_classic_/Interface/AddOns"
        "$HOME/Applications/World of Warcraft/_retail_/Interface/AddOns"
    )
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate" ]]; then
            target_dir="$candidate"
            break
        fi
    done
fi

if [[ -z "$target_dir" ]]; then
    echo "ERROR: WOW_ADDONS_DIR is not set and no AddOns folder found." >&2
    echo "Set WOW_ADDONS_DIR or run: WOW_ADDONS_DIR=/path/to/Interface/AddOns scripts/deploy.sh" >&2
    exit 1
fi

dest_dir="${target_dir}/${addon_name}"
mkdir -p "$dest_dir"

if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude ".git" \
        --exclude ".DS_Store" \
        --exclude "${addon_name}.zip" \
        --exclude "node_modules" \
        --exclude "dist" \
        --exclude "build" \
        "$repo_dir/" "$dest_dir/"
else
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"
    cp -a "$repo_dir/." "$dest_dir/"
    rm -rf "$dest_dir/.git" \
        "$dest_dir/.DS_Store" \
        "$dest_dir/${addon_name}.zip" \
        "$dest_dir/node_modules" \
        "$dest_dir/dist" \
        "$dest_dir/build"
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "ERROR: zip is not installed." >&2
    exit 1
fi

(
    cd "$(dirname "$repo_dir")"
    zip -r "$zip_path" "$addon_name" \
        -x "$addon_name/.git/*" \
           "$addon_name/.DS_Store" \
           "$addon_name/${addon_name}.zip" \
           "$addon_name/node_modules/*" \
           "$addon_name/dist/*" \
           "$addon_name/build/*"
)

echo "Deployed to: $dest_dir"
echo "Created zip: $zip_path"
