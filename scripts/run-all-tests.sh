#!/bin/bash
set -euo pipefail

# LuaSwift Comprehensive Test Runner
# Runs tests across all Lua versions and dependency combinations
#
# Usage:
#   ./scripts/run-all-tests.sh                    # Run all tests
#   ./scripts/run-all-tests.sh --deps-only        # Only dependency combinations
#   ./scripts/run-all-tests.sh --lua-only         # Only Lua versions
#   ./scripts/run-all-tests.sh --quick            # Quick test (default Lua, all deps)
#   ./scripts/run-all-tests.sh --lua 54           # Test specific Lua version only
#   ./scripts/run-all-tests.sh --combo "1 1 1"    # Test specific combination only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source configuration
source "$SCRIPT_DIR/test-config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Options
DEPS_ONLY=false
LUA_ONLY=false
QUICK=false
SPECIFIC_LUA=""
SPECIFIC_COMBO=""
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --deps-only|-d)
            DEPS_ONLY=true
            shift
            ;;
        --lua-only|-l)
            LUA_ONLY=true
            shift
            ;;
        --quick|-q)
            QUICK=true
            shift
            ;;
        --lua)
            SPECIFIC_LUA="$2"
            shift 2
            ;;
        --combo)
            SPECIFIC_COMBO="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "LuaSwift Comprehensive Test Runner"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deps-only, -d   Only test dependency combinations (default Lua)"
            echo "  --lua-only, -l    Only test Lua versions (all deps)"
            echo "  --quick, -q       Quick test (default Lua, all deps only)"
            echo "  --lua VERSION     Test specific Lua version (51, 52, 53, 54, 55)"
            echo "  --combo BITS      Test specific combination (e.g., '1 0 1')"
            echo "  --verbose, -v     Show detailed output"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                        # Full test matrix"
            echo "  $0 --deps-only            # All dep combinations with Lua 5.4"
            echo "  $0 --lua-only             # All Lua versions with all deps"
            echo "  $0 --lua 51               # Test only Lua 5.1"
            echo "  $0 --combo '1 1 0'        # Test only N+A combination"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Results tracking
declare -a PASSED_TESTS=()
declare -a FAILED_TESTS=()
START_TIME=$(date +%s)

# Test result files - persistent in /tmp with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="/tmp/luaswift_test_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

# No cleanup - logs persist in /tmp for review

# Main log file
MAIN_LOG="$RESULTS_DIR/run.log"

# Log function - outputs to both stdout and log file
log() {
    echo -e "$1"
    # Strip ANSI codes for log file
    echo -e "$1" | perl -pe 's/\e\[[0-9;]*m//g' >> "$MAIN_LOG"
}

# Run a single test configuration
run_test() {
    local lua_version="$1"
    local dep_bits="$2"
    local combo_name=$(generate_combo_name "$dep_bits")
    local lua_name=""

    # Get Lua version name
    for lv in "${LUA_VERSIONS[@]}"; do
        local code=$(parse_lua_version "$lv" "code")
        if [ "$code" = "$lua_version" ]; then
            lua_name=$(parse_lua_version "$lv" "name")
            break
        fi
    done

    local test_name="$lua_name / $combo_name"
    local log_file="$RESULTS_DIR/test_${lua_version}_${dep_bits// /_}.log"

    if [ "$VERBOSE" = true ]; then
        log "${CYAN}Testing: $test_name${NC}"
    fi

    # Set environment
    export LUASWIFT_LUA_VERSION="$lua_version"
    set_dep_env_vars "$dep_bits"

    # Clean and build
    cd "$PROJECT_ROOT"
    swift package clean > /dev/null 2>&1 || true

    local build_ok=false
    local test_ok=false

    # Build
    if swift build > "$log_file" 2>&1; then
        build_ok=true
    fi

    # Test (only if build succeeded)
    if [ "$build_ok" = true ]; then
        if swift test >> "$log_file" 2>&1; then
            # Check for pass indicators
            if grep -qE "(Test run with .* passed|Test Suite.*passed)" "$log_file"; then
                test_ok=true
            fi
        fi
    fi

    # Record result
    if [ "$build_ok" = true ] && [ "$test_ok" = true ]; then
        echo "PASS:$test_name" >> "$RESULTS_DIR/results.txt"
        if [ "$VERBOSE" = true ]; then
            log "  ${GREEN}PASS${NC}"
        fi
        return 0
    else
        echo "FAIL:$test_name" >> "$RESULTS_DIR/results.txt"
        if [ "$VERBOSE" = true ]; then
            log "  ${RED}FAIL${NC}"
            if [ "$build_ok" = false ]; then
                log "  Build failed"
            else
                log "  Tests failed"
            fi
        fi
        # Save error log
        cp "$log_file" "$RESULTS_DIR/error_${lua_version}_${dep_bits// /_}.log"
        return 1
    fi
}

# Print header
print_header() {
    log ""
    log "${BLUE}=========================================${NC}"
    log "${BLUE}LuaSwift Comprehensive Test Runner${NC}"
    log "${BLUE}=========================================${NC}"
    log ""
    log "Configuration:"
    log "  Lua versions: $(get_lua_version_count)"
    log "  Optional dependencies: $(get_dep_count)"
    log "  Dependency combinations: $((1 << $(get_dep_count)))"
    log ""
}

# Print summary
print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    log ""
    log "${BLUE}=========================================${NC}"
    log "${BLUE}Test Summary${NC}"
    log "${BLUE}=========================================${NC}"

    # Count results
    local passed=0
    local failed=0
    declare -a failed_tests=()

    if [ -f "$RESULTS_DIR/results.txt" ]; then
        while IFS= read -r line; do
            local status="${line%%:*}"
            local name="${line#*:}"
            if [ "$status" = "PASS" ]; then
                ((passed++))
            else
                ((failed++))
                failed_tests+=("$name")
            fi
        done < "$RESULTS_DIR/results.txt"
    fi

    local total=$((passed + failed))

    log ""
    log "Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC} of $total total"
    log "Duration: ${duration}s"

    log ""
    log "Logs saved to: $RESULTS_DIR"

    if [ $failed -gt 0 ]; then
        log ""
        log "${RED}Failed tests:${NC}"
        for t in "${failed_tests[@]}"; do
            log "  ${RED}✗${NC} $t"
        done
        log ""
        log "Error logs: $RESULTS_DIR/error_*.log"
        return 1
    else
        log ""
        log "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# Main execution
main() {
    print_header

    # Check dependencies are available
    if ! check_deps_cloned 2>/dev/null; then
        log "${YELLOW}Warning: Some dependencies not found. They will be skipped.${NC}"
        log ""
    fi

    # Determine what to test
    local lua_versions_to_test=()
    local combinations_to_test=()

    # Determine Lua versions
    if [ -n "$SPECIFIC_LUA" ]; then
        lua_versions_to_test=("$SPECIFIC_LUA")
    elif [ "$DEPS_ONLY" = true ] || [ "$QUICK" = true ]; then
        lua_versions_to_test=("$DEFAULT_LUA_VERSION")
    else
        for lv in "${LUA_VERSIONS[@]}"; do
            lua_versions_to_test+=("$(parse_lua_version "$lv" "code")")
        done
    fi

    # Determine combinations
    if [ -n "$SPECIFIC_COMBO" ]; then
        combinations_to_test=("$SPECIFIC_COMBO")
    elif [ "$LUA_ONLY" = true ]; then
        # All deps on (all 1s)
        local all_on=""
        for ((i=0; i<${#OPTIONAL_DEPS[@]}; i++)); do
            all_on="$all_on 1"
        done
        combinations_to_test=("${all_on# }")
    elif [ "$QUICK" = true ]; then
        # All deps on
        local all_on=""
        for ((i=0; i<${#OPTIONAL_DEPS[@]}; i++)); do
            all_on="$all_on 1"
        done
        combinations_to_test=("${all_on# }")
    else
        # Generate all combinations
        while IFS= read -r combo; do
            combinations_to_test+=("$combo")
        done < <(generate_dep_combinations)
    fi

    # Calculate total tests
    local total_tests=$((${#lua_versions_to_test[@]} * ${#combinations_to_test[@]}))
    log "Running $total_tests test configurations..."
    log ""

    # Run tests
    local test_count=0
    for lua_ver in "${lua_versions_to_test[@]}"; do
        for combo in "${combinations_to_test[@]}"; do
            ((test_count++))
            local combo_name=$(generate_combo_name "$combo")

            # Get Lua name
            local lua_name="Lua $lua_ver"
            for lv in "${LUA_VERSIONS[@]}"; do
                local code=$(parse_lua_version "$lv" "code")
                if [ "$code" = "$lua_ver" ]; then
                    lua_name=$(parse_lua_version "$lv" "name")
                    break
                fi
            done

            log "[$test_count/$total_tests] Testing: $lua_name / $combo_name"
            if run_test "$lua_ver" "$combo"; then
                log "  ${GREEN}PASS${NC}"
            else
                log "  ${RED}FAIL${NC}"
            fi
        done
    done

    # Print summary
    print_summary
}

# Run main
cd "$PROJECT_ROOT"
main
