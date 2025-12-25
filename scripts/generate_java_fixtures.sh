#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SBE_VERSION="${SBE_VERSION:-1.36.2}"
SBE_GROUP="uk/co/real-logic"
SBE_ARTIFACT="sbe-all"
SBE_CACHE_DIR="${SBE_CACHE_DIR:-${HOME}/.cache/sbe}"
SBE_JAR="${SBE_CACHE_DIR}/${SBE_ARTIFACT}-${SBE_VERSION}.jar"
SBE_JAR_URL="https://repo1.maven.org/maven2/${SBE_GROUP}/${SBE_ARTIFACT}/${SBE_VERSION}/${SBE_ARTIFACT}-${SBE_VERSION}.jar"
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
mkdir -p "${OUT_DIR}" "${CLASS_DIR}" "${ROOT_DIR}/test/java-fixtures" "${SBE_CACHE_DIR}"

if [[ ! -f "${SBE_JAR}" ]]; then
  echo "Downloading sbe-all ${SBE_VERSION}..." >&2
  curl -fsSL "${SBE_JAR_URL}" -o "${SBE_JAR}"
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
