#!/usr/bin/env bash
# Install regenerated validators into the original release directories.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
release_root="$repo_root/src/test/resources/releases"
generated_root="$repo_root/target/generated-xslt"

if [[ ! -d "$generated_root" ]]; then
  echo "Generated XSLT files are missing. Run: mvn generate-resources" >&2
  exit 1
fi

updated=0

while IFS= read -r -d '' schematron; do
  source_dir=$(dirname "$schematron")
  relative_dir=${source_dir#"$release_root/"}
  generated_dir="$generated_root/$relative_dir"
  if [[ "$source_dir" == *EXTENDED ]]; then
    generated_xslt="$generated_dir/FACTUR-X_EXTENDED.xslt"
  else
    generated_xslt=$(find "$generated_dir" -maxdepth 1 -type f -name '*.xslt' -print -quit)
  fi
  target_dir=$(find "$source_dir" -maxdepth 1 -type d -name '_XSLT*' -print -quit)
  target_xslt=$(find "$target_dir" -maxdepth 1 -type f \( -name '*.xsl' -o -name '*.xslt' \) -print -quit)

  if [[ ! -f "$generated_xslt" || -z "$target_dir" || -z "$target_xslt" ]]; then
    echo "Cannot install generated XSLT for $schematron" >&2
    exit 1
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "Would update $target_xslt"
  else
    cp "$generated_xslt" "$target_xslt"
  fi
  updated=$((updated + 1))
done < <(find "$release_root" -type f -name '*.sch' ! -path '*/Examples/*' ! -path '*/Beispiele/*' ! -path '*_ZUGFeRD 2.5 examples/*' -print0)

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "Would update $updated release XSLT files in $release_root"
else
  echo "Updated $updated release XSLT files in $release_root"
fi
