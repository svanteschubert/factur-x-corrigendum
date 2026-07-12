# Sources

`src/test/resources/releases/` contains the supplied original ZF25 DE/EN and
FACTUR-X FINAL DE/EN/FR release directories. On `master`, their precompiled
XSLT remain unchanged. The ZF25 DE/EN EXTENDED XSLT are the unfixed regression
artefacts. The `fix` branch regenerates and replaces only XSLT files in place.

Each release contains its own Schematron inputs. The explicitly provided,
corrected DE EXTENDED Schematron is held outside the immutable release trees
under `src/test/resources/corrigendum/`; it generates the five EXTENDED
overrides and contains the corrected `LineStatusReasonCode` filter.

The generated XSLT uses the same `ph-schematron-maven-plugin` conversion
approach as the eInvoicing-EN16931 project.
