#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SBE_VERSION="${SBE_VERSION:-1.36.2}"
SBE_GROUP="uk.co.real-logic"
SBE_ARTIFACT="sbe-all"
M2_REPO="${M2_REPO:-${HOME}/.m2/repository}"
SBE_JAR="${M2_REPO}/${SBE_GROUP//./\/}/${SBE_ARTIFACT}/${SBE_VERSION}/${SBE_ARTIFACT}-${SBE_VERSION}.jar"
SCHEMA="${ROOT_DIR}/test/example-schema.xml"
EXT_SCHEMA="${ROOT_DIR}/test/example-extension-schema.xml"
CODEGEN_SCHEMA="${ROOT_DIR}/test/resources/java-code-generation-schema.xml"
OUT_DIR="${ROOT_DIR}/test/java-fixtures/generated"
CLASS_DIR="${ROOT_DIR}/test/java-fixtures/classes"
FIXTURE_OUT="${ROOT_DIR}/test/java-fixtures/car-example.bin"
EXT_FIXTURE_OUT="${ROOT_DIR}/test/java-fixtures/car-extension.bin"
CODEGEN_FIXTURE_OUT="${ROOT_DIR}/test/java-fixtures/codegen-global-keywords.bin"
JAVA_OPTS=(--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED)

rm -rf "${OUT_DIR}" "${CLASS_DIR}"
mkdir -p "${OUT_DIR}" "${CLASS_DIR}" "${ROOT_DIR}/test/java-fixtures"

if ! command -v mvn >/dev/null 2>&1; then
  echo "mvn is required to download sbe-all from Maven (missing on PATH)." >&2
  exit 1
fi

mvn -q dependency:get -Dartifact="${SBE_GROUP}:${SBE_ARTIFACT}:${SBE_VERSION}" -Dtransitive=false

if [[ ! -f "${SBE_JAR}" ]]; then
  echo "sbe-all jar not found at ${SBE_JAR} after Maven download." >&2
  exit 1
fi

java "${JAVA_OPTS[@]}" -Dsbe.keyword.append.token=_ -Dsbe.target.language=java -Dsbe.output.dir="${OUT_DIR}" -jar "${SBE_JAR}" "${SCHEMA}"
java "${JAVA_OPTS[@]}" -Dsbe.keyword.append.token=_ -Dsbe.target.language=java -Dsbe.output.dir="${OUT_DIR}" -jar "${SBE_JAR}" "${EXT_SCHEMA}"
java "${JAVA_OPTS[@]}" -Dsbe.keyword.append.token=_ -Dsbe.target.language=java -Dsbe.output.dir="${OUT_DIR}" -jar "${SBE_JAR}" "${CODEGEN_SCHEMA}"

JAVA_SOURCES=$(find "${OUT_DIR}" -name '*.java')

javac -cp "${SBE_JAR}" -d "${CLASS_DIR}" ${JAVA_SOURCES} \
  "${ROOT_DIR}/scripts/GenerateCarFixture.java" \
  "${ROOT_DIR}/scripts/GenerateExtensionFixture.java" \
  "${ROOT_DIR}/scripts/GenerateCodeGenFixture.java"

java "${JAVA_OPTS[@]}" -cp "${SBE_JAR}:${CLASS_DIR}" GenerateCarFixture "${FIXTURE_OUT}"
java "${JAVA_OPTS[@]}" -cp "${SBE_JAR}:${CLASS_DIR}" GenerateExtensionFixture "${EXT_FIXTURE_OUT}"
java "${JAVA_OPTS[@]}" -cp "${SBE_JAR}:${CLASS_DIR}" GenerateCodeGenFixture "${CODEGEN_FIXTURE_OUT}"

echo "Wrote fixture to ${FIXTURE_OUT}"
echo "Wrote fixture to ${EXT_FIXTURE_OUT}"
echo "Wrote fixture to ${CODEGEN_FIXTURE_OUT}"
