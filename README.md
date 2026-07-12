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

## Regression demonstration on `master`

```sh
mvn clean install
```

This command is expected to fail. It regenerates XSLT only below `target/` and
tests the unchanged original ZF25 DE validator against the official X20
EXTENDED example, which has `GROUP` lines. The three false BT-131 tax-base
assertions from the bug report therefore fail the regression test.

## Regenerate the corrigendum

The Maven build uses `com.helger.maven:ph-schematron-maven-plugin`, the same
Schematron-to-XSLT conversion mechanism used by eInvoicing-EN16931.

```sh
mvn generate-resources
./regenerate-releases.sh
```

The first command creates 25 release-specific validators and five corrected
EXTENDED overrides in `target/generated-xslt/`, mirroring the five original
release directories. The second command installs only the generated XSLT files
in their corresponding profile directories under
`src/test/resources/releases/`; it does not traverse example directories.
`target/` is an ignored intermediate directory and is not part of either
release state.

The Maven coordinates are `com.schubert-consulting.factur-x:factur-x-corrigendum`.

The validators are generated separately for ZF25 DE, ZF25 EN, FINAL DE, FINAL
EN, and FINAL FR with the plugin's `de`, `en`, and `fr` language settings.
