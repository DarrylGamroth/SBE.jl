#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SBE_JAR="${ROOT_DIR}/../simple-binary-encoding/sbe-all/build/libs/sbe-all-1.37.0-SNAPSHOT.jar"
SCHEMA="${ROOT_DIR}/test/example-schema.xml"
OUT_DIR="${ROOT_DIR}/test/java-fixtures/generated"
CLASS_DIR="${ROOT_DIR}/test/java-fixtures/classes"
FIXTURE_OUT="${ROOT_DIR}/test/java-fixtures/car-example.bin"
JAVA_OPTS=(--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED)

rm -rf "${OUT_DIR}" "${CLASS_DIR}"
mkdir -p "${OUT_DIR}" "${CLASS_DIR}" "${ROOT_DIR}/test/java-fixtures"

java "${JAVA_OPTS[@]}" -Dsbe.target.language=java -Dsbe.output.dir="${OUT_DIR}" -jar "${SBE_JAR}" "${SCHEMA}"

JAVA_SOURCES=$(find "${OUT_DIR}" -name '*.java')

javac -cp "${SBE_JAR}" -d "${CLASS_DIR}" ${JAVA_SOURCES} "${ROOT_DIR}/scripts/GenerateCarFixture.java"

java "${JAVA_OPTS[@]}" -cp "${SBE_JAR}:${CLASS_DIR}" GenerateCarFixture "${FIXTURE_OUT}"

echo "Wrote fixture to ${FIXTURE_OUT}"
