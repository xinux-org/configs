#!/bin/bash

# shellcheck disable=SC2164
cd "$(dirname "$0")"

# Update all submodules
git submodule update --remote --merge
git add .
git commit -m "Updating submodules"
git push