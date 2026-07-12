package com.schubertconsulting.facturx;

import static org.junit.jupiter.api.Assertions.fail;

import java.io.StringReader;
import java.io.StringWriter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

/**
 * Regression case from FACTUR-X-1.09-EXTENDED-XSLT-BUG.
 *
 * <p>The official X20 EXTENDED example has two GROUP lines. They are not DETAIL lines and must
 * therefore be excluded from the tax-base (BT-131) summation. The assertion is deliberately scoped
 * to the three tax-base rules that the old XSLT incorrectly fires for this invoice.</p>
 */
class ExtendedStatusLineRegressionTest {

  private static final Path PROJECT_DIRECTORY = Path.of(System.getProperty("user.dir"));
  private static final Set<String> AFFECTED_RULE_IDS = Set.of(
      "FX-SCH-A-000412", "FX-SCH-A-000379", "FX-SCH-A-000380");
  private static final String REGRESSION_EXPLANATION = """
      Factur-X 1.09 EXTENDED regression detected.

      The distributed pre-compiled FACTUR-X_EXTENDED.xslt is missing the
      LineStatusReasonCode predicate in its BT-131 tax-base summations. The
      official X20 EXTENDED example contains GROUP lines. GROUP and INFORMATION
      lines are not DETAIL lines, so they must be excluded from those sums.

      Expected: the VAT taxable amount (BT-116) matches the sum of eligible
      invoice line net amounts (BT-131), and none of the affected tax-base rules
      fires.

      Actual: the old XSLT includes GROUP lines, producing false tax-base
      assertion failures: %s

      Resolution: regenerate the release XSLT from the current EXTENDED
      Schematron. Its IncludedSupplyChainTradeLineItem predicate retains only
      lines with no LineStatusReasonCode or with LineStatusReasonCode = DETAIL.
      """;

  @Test
  void groupLinesDoNotCauseTaxBaseValidationFailures() throws Exception {
    final Path invoice = PROJECT_DIRECTORY.resolve(
        "src/test/resources/releases/ZF25_DE/Beispiele/4. EXTENDED/X20_SubInvoiceLines_Buero_Material_Bsp3__/"
            + "X20_01_SubInvoiceLines_Buero_Material_Bsp3__.xml");
    final Path validator = PROJECT_DIRECTORY.resolve(
        "src/test/resources/releases/ZF25_DE/Schema/4_Factur-X_1.09_EXTENDED/"
            + "_XSLT_EXTENDED/FACTUR-X_EXTENDED.xslt");

    final TransformerFactory factory = new net.sf.saxon.TransformerFactoryImpl();
    final Transformer transformer = factory.newTransformer(new StreamSource(validator.toFile()));
    final StringWriter svrl = new StringWriter();
    transformer.transform(new StreamSource(invoice.toFile()), new StreamResult(svrl));

    final Document report = DocumentBuilderFactory.newInstance()
        .newDocumentBuilder()
        .parse(new InputSource(new StringReader(svrl.toString())));
    final NodeList failures = (NodeList) XPathFactory.newInstance().newXPath().evaluate(
        "//*[local-name()='failed-assert']", report, XPathConstants.NODESET);
    final List<String> affectedFailures = new ArrayList<>();
    for (int index = 0; index < failures.getLength(); index++) {
      final String ruleId = failures.item(index).getAttributes().getNamedItem("id").getNodeValue();
      if (AFFECTED_RULE_IDS.contains(ruleId)) {
        affectedFailures.add(ruleId);
      }
    }

    if (!affectedFailures.isEmpty()) {
      fail(REGRESSION_EXPLANATION.formatted(affectedFailures));
    }
  }
}
