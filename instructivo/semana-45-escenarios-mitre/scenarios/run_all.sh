#!/usr/bin/env bash
# run_all.sh — ejecuta los 30 escenarios contra un honeypot y muestra el resumen
# Uso: bash /scenarios/run_all.sh [safe-honeypot | safe-honeypot-llm]
TARGET="${1:-safe-honeypot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# LLM backend runs Ollama per command; allow more time (default 45s, LLM 180s)
if echo "$TARGET" | grep -q "llm"; then
    export TIMEOUT=180
else
    export TIMEOUT=45
fi

echo "=== RUN ALL — ${TARGET} (timeout ${TIMEOUT}s/scenario) ==="
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
    elapsed_s=$(awk "BEGIN {printf \"%.1f\", $elapsed / 1000}")

    # [OK] = SSH connected and command ran (even if honeypot returned "not found")
    # [FAIL] = SSH connection itself failed (exit 255)
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
