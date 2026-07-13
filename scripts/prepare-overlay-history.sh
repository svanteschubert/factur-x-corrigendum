#!/usr/bin/env bash
# Create reviewable normalized baseline/overwrite material. Never creates Git commits.
set -euo pipefail

usage() {
  echo "Usage: $0 {mustang|ph} {baseline|overwrite}" >&2
  exit 64
}

[[ $# == 2 ]] || usage
overlay_kind=$1
mode=$2
[[ $overlay_kind == mustang || $overlay_kind == ph ]] || usage
[[ $mode == baseline || $mode == overwrite ]] || usage

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_root="$repo_root/src/test/resources/releases"
mustang_root="${MUSTANG_ROOT:-$repo_root/../factur-x/Mustang}"

canonicalize_file() {
  local source=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  xmllint --c14n "$source" | sed 's/[[:blank:]]*$//' >"$destination"
}

canonicalize_master_file() {
  local repository_path=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  git -C "$repo_root" show "master:$repository_path" | xmllint --c14n - | sed 's/[[:blank:]]*$//' >"$destination"
}

release_xslt_for_schematron() {
  local schematron_dir=$1
  find "$schematron_dir" -maxdepth 2 -type f \( -name '*.xsl' -o -name '*.xslt' \) -print -quit
}

prepare_mustang() {
  local overlay_root="$repo_root/overlays/factur-x-github-de"
  local schema_root="$release_root/ZF25_DE/Schema"
  local mustang_xslt="$mustang_root/validator/src/main/resources/xslt/ZF_240"
  local mustang_schematron="$mustang_root/validator/src/main/resources/schematron/ZF_240"
  local corrected="$repo_root/src/test/resources/corrigendum/FACTUR-X_EXTENDED.sch"
  local count=0

  [[ -d $mustang_xslt && -d $mustang_schematron ]] || {
    echo "Mustang resources not found below $mustang_root" >&2
    exit 1
  }

  if [[ $mode == overwrite ]] && ! cmp -s "$mustang_schematron/FACTUR-X_EXTENDED.sch" "$corrected"; then
    echo "Mustang working-tree EXTENDED Schematron is not byte-identical to corrigendum source" >&2
    exit 1
  fi

  # A baseline is a full, normalized release view: both Schematron and XSLT.
  while IFS= read -r -d '' release_schematron; do
    canonicalize_master_file "${release_schematron#"$repo_root/"}" "$overlay_root/${release_schematron#"$repo_root/"}"
  done < <(find "$schema_root" -type f -name '*.sch' -print0)

  while IFS=':' read -r profile_dir xslt_dir file_name; do
    local release_xslt release_schematron
    release_xslt="$schema_root/$profile_dir/$xslt_dir/$file_name"
    release_schematron=$(find "$schema_root/$profile_dir" -maxdepth 1 -type f -name '*.sch' -print -quit)
    local destination="$overlay_root/${release_xslt#"$repo_root/"}"
    if [[ $mode == baseline ]]; then
      canonicalize_master_file "${release_xslt#"$repo_root/"}" "$destination"
    else
      canonicalize_file "$mustang_xslt/$file_name" "$destination"
      canonicalize_file "$mustang_schematron/${file_name%.xslt}.sch" "$overlay_root/${release_schematron#"$repo_root/"}"
    fi
    count=$((count + 1))
  done <<'PROFILES'
0_Factur-X_1.09_MINIMUM:_XSLT_MINIMUM:FACTUR-X_MINIMUM.xslt
1_Factur-X_1.09_BASICWL:_XSLT_BASIC-WL:FACTUR-X_BASIC-WL.xslt
2_Factur-X_1.09_BASIC:_XSLT_BASIC:FACTUR-X_BASIC.xslt
3_Factur-X_1.09_EN16931:_XSLT_EN16931:FACTUR-X_EN16931.xslt
4_Factur-X_1.09_EXTENDED:_XSLT_EXTENDED:FACTUR-X_EXTENDED.xslt
PROFILES

  if [[ $mode == overwrite ]]; then
    {
      echo "Mustang working-tree source"
      git -C "$mustang_root" rev-parse HEAD
      shasum -a 256 "$mustang_schematron/FACTUR-X_EXTENDED.sch"
    } >"$overlay_root/MUSTANG-SOURCE.txt"
  fi
  echo "Prepared $count Mustang DE XSLT files for $mode."
}

prepare_ph() {
  local overlay_root="$repo_root/overlays/ph-schematron"
  local generated_root="$repo_root/target/generated-xslt"
  local corrected="$repo_root/src/test/resources/corrigendum/FACTUR-X_EXTENDED.sch"
  local count=0

  if [[ $mode == overwrite ]]; then
    (cd "$repo_root" && mvn -B generate-resources)
  fi

  while IFS= read -r -d '' schematron; do
    local schematron_dir relative_dir release_xslt destination generated_xslt
    schematron_dir="$(dirname "$schematron")"
    relative_dir=${schematron_dir#"$release_root/"}
    release_xslt=$(release_xslt_for_schematron "$schematron_dir")
    destination="$overlay_root/${release_xslt#"$repo_root/"}"

    if [[ $mode == baseline ]]; then
      canonicalize_master_file "${schematron#"$repo_root/"}" "$overlay_root/${schematron#"$repo_root/"}"
      canonicalize_master_file "${release_xslt#"$repo_root/"}" "$destination"
    else
      if [[ $schematron_dir == *EXTENDED ]]; then
        generated_xslt="$generated_root/$relative_dir/FACTUR-X_EXTENDED.xslt"
      else
        generated_xslt="$generated_root/$relative_dir/$(basename "${schematron%.sch}").xslt"
      fi
      canonicalize_file "$generated_xslt" "$destination"
      if [[ $schematron_dir == *EXTENDED ]]; then
        canonicalize_file "$corrected" "$overlay_root/${schematron#"$repo_root/"}"
      fi
    fi
    count=$((count + 1))
  done < <(find "$release_root" -type f -name '*.sch' ! -path '*/Examples/*' ! -path '*/Beispiele/*' ! -path '*_ZUGFeRD 2.5 examples/*' -print0)

  echo "Prepared $count PH XSLT files for $mode."
}

case $overlay_kind in
  mustang) prepare_mustang ;;
  ph) prepare_ph ;;
esac
