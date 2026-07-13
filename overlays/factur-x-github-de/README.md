# Mustang DE XSLT overwrite overlay

This compact overlay contains five normalized XSLT files only. Their relative
paths mirror the XSLT locations below the ZF25 DE release tree:

```text
src/test/resources/releases/ZF25_DE/Schema/
```

They are comparison artefacts, not a complete release and not a replacement
for the original files under `src/test/resources/releases/`.

## Two-commit history

Create the original-release commit first:

```sh
scripts/prepare-overlay-history.sh mustang baseline
```

Commit that normalized baseline. Then run:

```sh
scripts/prepare-overlay-history.sh mustang overwrite
```

The second command replaces the same five normalized XSLT paths and five
normalized Schematron paths with the current Mustang working-tree material.
The script does not create a commit.

## Source

The overwrite input is the local Mustang sub-Git working tree:

```text
/Users/svanteschubert/dev/GitLab/awv/factur-x/Mustang/
validator/src/main/resources/{schematron,xslt}/ZF_240/
```

The Mustang working tree is intentionally used because its committed `HEAD`
is still the older 1.08 state. The script verifies that the working-tree
`FACTUR-X_EXTENDED.sch` is byte-identical to this repository's corrected
Schematron before copying it. The overlay is deliberately DE-only.

## Normalization

Every input was converted with:

```sh
xmllint --c14n INPUT.xslt | sed 's/[[:blank:]]*$//' > OUTPUT.xslt
```

This is XML Canonicalization 1.0 without comments. It removes the XML
declaration, canonicalizes XML syntax (including namespace and attribute
representation), and normalizes XML line-end handling. It does not change the
original Mustang file and is used solely to remove representation-level noise
when comparing it with the PH-generated overlay. The Mustang revision and the
raw SHA-256 value of its EXTENDED Schematron are recorded in
`MUSTANG-SOURCE.txt` during the overwrite step.
