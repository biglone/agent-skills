#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 */6 * * *}"
OUTPUT_FILE="${OUTPUT_FILE:-${SKILL_DIR}/references/question-bank-latest.md}"
LOG_FILE="${LOG_FILE:-${SKILL_DIR}/references/question-bank-update.log}"

CRON_CMD="${PYTHON_BIN} ${SCRIPT_DIR}/update_question_bank.py --output ${OUTPUT_FILE} >> ${LOG_FILE} 2>&1"
CRON_LINE="${CRON_SCHEDULE} ${CRON_CMD}"

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"
if printf "%s\n" "${CURRENT_CRON}" | grep -F "${CRON_CMD}" >/dev/null; then
  echo "Cron entry already exists:"
  printf "%s\n" "${CURRENT_CRON}" | grep -F "${CRON_CMD}"
  exit 0
fi

{
  printf "%s\n" "${CURRENT_CRON}"
  printf "%s\n" "${CRON_LINE}"
} | crontab -

echo "Installed cron entry:"
echo "${CRON_LINE}"
