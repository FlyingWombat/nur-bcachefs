#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git jq
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

rev=$(jq -r '.rev' ./version.json)
url=$(jq -r '.url' ./version.json)
kernelVersion=$(jq -r '.kernelVersion' ./version.json)

echo "$url $rev $kernelVersion"

nix-prefetch-git --no-deepClone "$url" "$rev" | jq --arg ver "$kernelVersion" '.kernelVersion = $ver' > ./version.json
