#!/bin/bash

while IFS= read -r line || [ -n "$line" ]; do

    [[ -z "$line" || "$line" == \#* ]] && continue

    repo=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^https?:\/\//) print $i}')
    repo=$(echo "$repo" | tr -d '\r' | xargs)

    if [ -z "$repo" ]; then
        echo "Línea ignorada: $line"
        continue
    fi

    name=$(basename "$repo" .git)
    dest="/data/compose/1/addons/$name"

    echo "Clonando (rápido): $repo"
    git clone --depth 1 --single-branch -b 19.0 "$repo" "$dest"

done < modules_install_19.txt
