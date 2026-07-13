# PH Schematron generated XSLT overlay

This compact overlay contains 25 normalized XSLT files only. Their paths
mirror the existing XSLT locations beneath:

```text
src/test/resources/releases/
```

It covers five profiles for each of ZF25 DE, ZF25 EN, FINAL DE, FINAL EN, and
FINAL FR. It is a comparison artefact, not a complete release and not an
instruction to normalize the original release files.

## Two-commit history

Create the original-release commit first:

```sh
scripts/prepare-overlay-history.sh ph baseline
```

Commit that normalized baseline. Then run:

```sh
scripts/prepare-overlay-history.sh ph overwrite
```

The second command regenerates the XSLT and replaces the same 25 normalized
XSLT paths with the PH output. It also replaces the five EXTENDED Schematron
paths with the corrected normalized Schematron source. The script does not
create a commit.

## Source

The inputs were generated on the `fix` branch by:

```sh
mvn -B generate-resources
```

The build uses `com.helger.maven:ph-schematron-maven-plugin` 9.0.1. Regular
profile inputs come from the original release Schematron files. The five
EXTENDED outputs are subsequently generated from the corrected source at:

```text
src/test/resources/corrigendum/FACTUR-X_EXTENDED.sch
```

That corrected source is a byte-identical copy of the DE EXTENDED Schematron
from the local Factur-X source repository.

## Normalization

Every generated XSLT was converted with:

```sh
xmllint --c14n INPUT.xslt | sed 's/[[:blank:]]*$//' > OUTPUT.xslt
```

This is XML Canonicalization 1.0 without comments. It removes the XML
declaration, canonicalizes XML syntax (including namespace and attribute
representation), and normalizes XML line-end handling. It is intentionally
applied only to this overlay so comparisons do not contain XML formatting
noise; the generated and original release XSLT remain available unchanged.
