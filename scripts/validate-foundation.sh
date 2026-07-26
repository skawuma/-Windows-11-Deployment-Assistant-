#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"

required_directories="
backend
frontend
powershell
docs
docs/contracts
docs/reference
scripts
"

required_files="
README.md
CHANGELOG.md
DECISIONS.md
SPRINT-STATUS.md
.gitignore
backend/README.md
frontend/README.md
powershell/README.md
docs/architecture.md
docs/README.md
docs/implementation-guide.md
docs/device-to-dashboard-interaction.md
docs/field-workflow-reference.md
docs/requirements-reconciliation.md
docs/development-standards.md
docs/contracts/json-schema-direction.md
docs/toolchain-and-environments.md
docs/security-and-privacy.md
docs/reference/original-version-1-readme.md
"

for directory in ${required_directories}; do
    if [ ! -d "${PROJECT_ROOT}/${directory}" ]; then
        echo "FAIL: missing required directory: ${directory}" >&2
        exit 1
    fi
done

for file in ${required_files}; do
    if [ ! -f "${PROJECT_ROOT}/${file}" ]; then
        echo "FAIL: missing required file: ${file}" >&2
        exit 1
    fi
done

for phrase in \
    "must never collect or store passwords" \
    "Technical evidence" \
    "User attestations" \
    "Technician validations" \
    "Enterprise approvals"; do
    if ! grep -Fqi "${phrase}" "${PROJECT_ROOT}/docs/security-and-privacy.md"; then
        echo "FAIL: security boundary is missing phrase: ${phrase}" >&2
        exit 1
    fi
done

for component in \
    "Java" \
    "Spring Boot" \
    "Angular" \
    "Node.js" \
    "Maven" \
    "PostgreSQL"; do
    if ! grep -Fq "${component}" "${PROJECT_ROOT}/docs/toolchain-and-environments.md"; then
        echo "FAIL: toolchain baseline is missing component: ${component}" >&2
        exit 1
    fi
done

if find "${PROJECT_ROOT}" -path "${PROJECT_ROOT}/.git" -prune -o \
    -type f \( -name ".env" -o -name "*.p12" -o -name "*.pfx" -o -name "*.jks" \) \
    -print | grep -q .; then
    echo "FAIL: a secret-bearing file pattern exists in the workspace" >&2
    exit 1
fi

echo "PASS: Sprint 1 foundation structure and governance checks succeeded."
