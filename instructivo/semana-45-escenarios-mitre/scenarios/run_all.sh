#!/usr/bin/env bash
# run_all.sh — ejecuta los 30 escenarios contra un honeypot y muestra el resumen
# Uso: bash /scenarios/run_all.sh [safe-honeypot | safe-honeypot-llm]
TARGET="${1:-safe-honeypot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RUN ALL — ${TARGET} ==="
echo ""

passed=0
failed=0
total=0

for script in $(ls "${SCRIPT_DIR}"/s[0-9][0-9]_*.sh | sort); do
    name=$(basename "$script" .sh)
    start=$(date +%s%3N)
    output=$(bash "$script" "$TARGET" 2>&1)
    end=$(date +%s%3N)
    elapsed=$(( end - start ))
    elapsed_s=$(printf "%.1f" "$(echo "scale=1; $elapsed / 1000" | bc)")

    if echo "$output" | grep -q "\[OK\]"; then
        status="OK"
        passed=$(( passed + 1 ))
    else
        status="FAIL"
        failed=$(( failed + 1 ))
    fi

    total=$(( total + 1 ))
    printf "%-4s %-35s %s  %s s\n" "${name:0:3}" "${name:4}" "$status" "$elapsed_s"
done

echo ""
echo "---"
echo "${passed}/${total} OK · ${failed} FAIL"
