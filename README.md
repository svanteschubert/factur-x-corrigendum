# Factur-X 1.09 / ZUGFeRD 2.5 Corrigendum

This repository is a public, self-contained demonstration of the
Factur-X 1.09 EXTENDED `LineStatusReasonCode` regression and its correction.

- `src/test/resources/releases/` contains the supplied original release
  directories unchanged, including their examples and documentation.
- `master` retains their original precompiled XSLT; the ZF25 DE/EN EXTENDED
  validators are the regression artefacts.
- `fix` overlays only each profile's XSLT with its newly generated validator.
  It never modifies examples, XSD, code lists, documentation, or other
  release files.

## Regression demonstration on `fix`

```sh
mvn clean install
```

This command succeeds. It regenerates the validators below `target/`, copies
only the 25 generated release XSLT files into their existing release folders,
and validates the official X20 EXTENDED example with `GROUP` lines without the
three false BT-131 tax-base assertions described in the bug report.

## Regenerate the corrigendum

The Maven build uses `com.helger.maven:ph-schematron-maven-plugin`, the same
Schematron-to-XSLT conversion mechanism used by eInvoicing-EN16931.

```sh
mvn generate-resources
```

The Maven phase creates 25 release-specific validators and five corrected
EXTENDED overrides in `target/generated-xslt/`, mirroring the five original
release directories. On this branch the platform-independent Maven Ant task
then copies only those 25 generated `.xsl`/`.xslt` files into their
corresponding profile directories. Schematron files and examples are excluded.
`target/` remains an ignored intermediate directory.

The Maven coordinates are `com.schubert-consulting.factur-x:factur-x-corrigendum`.

The validators are generated separately for ZF25 DE, ZF25 EN, FINAL DE, FINAL
EN, and FINAL FR with the plugin's `de`, `en`, and `fr` language settings.
