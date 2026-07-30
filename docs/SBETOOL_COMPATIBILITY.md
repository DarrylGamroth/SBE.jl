# SbeTool Compatibility

SBE.jl's maintained compatibility reference is the exact `sbe.version` in
`test/sbetool/pom.xml`. CI uses Maven to read that version for both the `sbe-all`
artifact and the matching upstream Git tag. Dependabot proposes Maven updates, so
each repository commit remains reproducible while new SbeTool releases are tested
before their version pin is merged.

The current fixture baseline is SbeTool 1.39.0, tag `1.39.0`, commit
`e773b57cac6b2008ce30dd219a33de49766c6013`. The 83 XML resources from
`sbe-tool/src/test/resources` are vendored under `test/resources`; their source is
recorded in `test/resources/UPSTREAM_SBETOOL.toml`. If a dependency update changes
the upstream corpus, the byte comparison fails until the fixture changes and their
provenance are reviewed together.

The compatibility gate is `scripts/check_sbetool_schema_compat.jl`. CI checks out
the pinned upstream resources and compares them byte-for-byte with the vendored
copies. It then runs both implementations in SbeTool's default CLI mode and checks:

- the accept/reject result for every XML fixture;
- schema metadata and the complete decoded token stream for every fixture accepted
  by both implementations; and
- the upstream relative-XInclude fixture with XInclude enabled in both tools.

IR comparison normalizes two representation details that do not alter the schema or
wire format: an omitted `char` encoding is the SBE default `US-ASCII`, and the outer
offset in the captured type dictionary depends on which message occurrence an
implementation visits first. Message-token offsets are compared without that
normalization.

## Compatibility ledger

| ID | Requirement | Implementation | Verification evidence | State |
|---|---|---|---|---|
| SBE-COMPAT-FIXTURE-001 | Keep the upstream SbeTool XML corpus pinned and unmodified. | 83 resources plus `UPSTREAM_SBETOOL.toml`. | CI byte comparison against the Maven-pinned SbeTool tag. | Verified |
| SBE-COMPAT-SCHEMA-001 | Match SbeTool default-mode schema acceptance. | XML.jl parser and SBE validation in `src/ir_generator.jl`. | 83/83 accept/reject decisions in the compatibility gate. | Verified |
| SBE-COMPAT-IR-001 | Match SbeTool IR for schemas accepted in default mode. | XML-to-IR generation and `.sbeir` decoding. | Normalized metadata and token equality for all 70 accepted fixtures. | Verified |
| SBE-COMPAT-IR-CODEGEN-001 | Generate Julia codecs from Java-produced IR. | `generate_from_ir` and `@load_sbeir`. | The Maven-pinned SbeTool regenerates `ir-basic-schema.sbeir`; tests generate source and exercise an expansion-time encoder/decoder from that file. | Verified for the maintained IR fixture |
| SBE-COMPAT-XINCLUDE-001 | Resolve the relative XML include exercised by SbeTool's parser suite. | Path-aware `parse_xml_schema_file` and `generate_ir_file`. | `sub/basic-schema.xml` differential with SbeTool XInclude enabled. | Verified for the upstream relative XML case |
| SBE-COMPAT-WIRE-001 | Decode SbeTool output and produce the same bytes. | Generated Julia codecs. | Java-produced baseline, extension, and keyword fixtures in `test/test_java_fixtures.jl`; Julia output is byte-compared with each fixture. | Verified for the three maintained fixtures |
| SBE-COMPAT-WIRE-002 | Have a generated Java codec decode Julia output. | Baseline Julia encoder plus `VerifyCarFixture.java`. | Linux CI regenerates Java codecs and runs the Julia-to-Java baseline verifier. | Verified for the baseline fixture |
| SBE-COMPAT-PRECEDENCE-001 | Diagnose unsafe group and variable-data traversal using SbeTool's field-precedence semantics. | Opt-in IR-derived encoder/decoder state models selected with `precedence_checks=true`. | Focused valid, invalid, nested, versioned, completion, external-tail, byte-parity, and allocation cases use upstream `field-order-check-schema.xml`. | Verified for the maintained focused cases |
| SBE-COMPAT-XSD-001 | Match SbeTool's optional external-XSD validation mode. | No external-XSD processor is exposed. Semantic schema validation is covered by SBE-COMPAT-SCHEMA-001. | None. | Not supported |

## Scope of the claim

This evidence supports schema/IR compatibility and the wire cases listed above. It
does not claim that SBE.jl is a drop-in replacement for every Java SbeTool feature.
Java source formatting, DTO generation, language-specific output managers, Gradle
integration, and other Java-only unit tests are outside a Julia codec's compatibility
surface. Text-mode XInclude, XPointer, and XInclude fallback processing are also not
implemented.

This is not a formal FIX conformance certification. The historical FIX responder and
validator repository targets SbeTool 1.5.5; it is not part of SbeTool's current test
suite. The maintained gate instead uses the current SbeTool resources and current
SbeTool-generated IR and codecs as the reference oracle.

## Running the gate locally

Read the maintained version from the Maven test manifest:

```bash
SBE_VERSION="$(
  mvn --batch-mode --quiet --no-transfer-progress \
    --file test/sbetool/pom.xml \
    help:evaluate \
    -Dexpression=sbe.version \
    -DforceStdout \
    -Dstyle.color=never
)"
```

Then use the matching upstream checkout and Maven Central artifact:

```bash
julia --project=. scripts/check_sbetool_schema_compat.jl \
  /path/to/simple-binary-encoding/sbe-tool/src/test/resources \
  "/path/to/sbe-all-${SBE_VERSION}.jar"
```

The upstream Java baseline can be checked independently from the pinned SbeTool
checkout with:

```bash
./gradlew :sbe-tool:test --no-daemon
```

That Gradle task validates SbeTool itself; the SBE.jl compatibility gate is what
connects the upstream corpus and oracle output to this package.
