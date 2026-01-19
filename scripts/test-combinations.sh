#!/bin/bash
set -euo pipefail

# Test all 8 optional dependency combinations for LuaSwift
# Usage:
#   ./scripts/test-combinations.sh           # Sequential execution
#   ./scripts/test-combinations.sh --parallel # Parallel execution

PARALLEL=false
if [ "${1:-}" = "--parallel" ]; then
  PARALLEL=true
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
FAILED_COMBINATIONS=()

# Test a single combination
test_combination() {
  local n=$1
  local a=$2
  local p=$3
  local combo_name=$4

  echo -e "${YELLOW}Testing combination: $combo_name${NC}"
  echo "  LUASWIFT_INCLUDE_NUMERICSWIFT=$n"
  echo "  LUASWIFT_INCLUDE_ARRAYSWIFT=$a"
  echo "  LUASWIFT_INCLUDE_PLOTSWIFT=$p"

  # Clean build directory
  swift package clean > /dev/null 2>&1 || true

  # Set environment variables and build
  export LUASWIFT_INCLUDE_NUMERICSWIFT=$n
  export LUASWIFT_INCLUDE_ARRAYSWIFT=$a
  export LUASWIFT_INCLUDE_PLOTSWIFT=$p

  if swift build > /dev/null 2>&1; then
    echo -e "  Build: ${GREEN}PASS${NC}"
  else
    echo -e "  Build: ${RED}FAIL${NC}"
    FAILED_COMBINATIONS+=("$combo_name (build)")
    return 1
  fi

  # Run tests - write to temp file to avoid SIGPIPE issues with pipefail
  local test_log="/tmp/luaswift_test_${n}${a}${p}_$$.log"
  swift test > "$test_log" 2>&1 || true

  # Check for new Swift Testing format or classic XCTest format
  if grep -qE "(Test run with .* passed|Test Suite.*passed)" "$test_log"; then
    echo -e "  Tests: ${GREEN}PASS${NC}"
    rm -f "$test_log"
    echo ""
    return 0
  else
    echo -e "  Tests: ${RED}FAIL${NC}"
    tail -20 "$test_log"  # Show last 20 lines for debugging
    rm -f "$test_log"
    FAILED_COMBINATIONS+=("$combo_name (tests)")
    echo ""
    return 1
  fi
}

# Test a combination in the background (for parallel mode)
test_combination_background() {
  local n=$1
  local a=$2
  local p=$3
  local combo_name=$4
  local log_file="/tmp/luaswift_test_${n}${a}${p}.log"

  # Run test and capture output
  if test_combination "$n" "$a" "$p" "$combo_name" > "$log_file" 2>&1; then
    echo -e "${GREEN}✓${NC} $combo_name" >> /tmp/luaswift_parallel_results.txt
  else
    echo -e "${RED}✗${NC} $combo_name" >> /tmp/luaswift_parallel_results.txt
    cat "$log_file" >> /tmp/luaswift_parallel_errors.txt
  fi
  rm -f "$log_file"
}

echo "========================================="
echo "LuaSwift Dependency Combinations Test"
echo "========================================="
echo ""

# Clear parallel result files if in parallel mode
if [ "$PARALLEL" = true ]; then
  rm -f /tmp/luaswift_parallel_results.txt /tmp/luaswift_parallel_errors.txt
  echo "Running tests in parallel..."
  echo ""
fi

# Define all 8 combinations
# Format: N A P "Name"
COMBINATIONS=(
  "0 0 0 Standalone"
  "1 0 0 NumericSwift-only"
  "0 1 0 ArraySwift-only"
  "0 0 1 PlotSwift-only"
  "1 1 0 NumericSwift+ArraySwift"
  "1 0 1 NumericSwift+PlotSwift"
  "0 1 1 ArraySwift+PlotSwift"
  "1 1 1 All-dependencies"
)

if [ "$PARALLEL" = true ]; then
  # Run all combinations in parallel
  for combo in "${COMBINATIONS[@]}"; do
    read -r n a p name <<< "$combo"
    test_combination_background "$n" "$a" "$p" "$name" &
  done

  # Wait for all background jobs
  wait

  # Display results
  echo ""
  echo "========================================="
  echo "Parallel Test Results"
  echo "========================================="
  if [ -f /tmp/luaswift_parallel_results.txt ]; then
    cat /tmp/luaswift_parallel_results.txt
  fi

  # Check for failures
  if [ -f /tmp/luaswift_parallel_errors.txt ]; then
    echo ""
    echo "========================================="
    echo "Failures"
    echo "========================================="
    cat /tmp/luaswift_parallel_errors.txt
    rm -f /tmp/luaswift_parallel_results.txt /tmp/luaswift_parallel_errors.txt
    exit 1
  fi

  rm -f /tmp/luaswift_parallel_results.txt
else
  # Run all combinations sequentially
  for combo in "${COMBINATIONS[@]}"; do
    read -r n a p name <<< "$combo"
    test_combination "$n" "$a" "$p" "$name" || true
  done

  echo "========================================="
  echo "Summary"
  echo "========================================="

  if [ ${#FAILED_COMBINATIONS[@]} -eq 0 ]; then
    echo -e "${GREEN}All 8 combinations passed!${NC}"
    exit 0
  else
    echo -e "${RED}Failed combinations:${NC}"
    for failed in "${FAILED_COMBINATIONS[@]}"; do
      echo -e "  ${RED}✗${NC} $failed"
    done
    exit 1
  fi
fi
