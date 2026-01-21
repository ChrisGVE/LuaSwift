#!/bin/bash
# LuaSwift Test Configuration
# Source this file to get test configuration variables
#
# Configuration is read from test-matrix.json for centralization.
# The same JSON file is used by GitHub CI workflows.
#
# When adding a new optional dependency:
#   1. Add it to scripts/test-matrix.json
#   2. Update Package.swift with the same env var pattern
#   3. CI workflow will automatically pick up the new dependency

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/test-matrix.json"

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

# Check config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# ============================================================
# LOAD CONFIGURATION FROM JSON
# ============================================================

# Load Lua versions
LUA_VERSIONS=()
while IFS= read -r line; do
    LUA_VERSIONS+=("$line")
done < <(jq -r '.lua_versions[] | "\(.code):\(.name)"' "$CONFIG_FILE")

DEFAULT_LUA_VERSION=$(jq -r '.default_lua_version' "$CONFIG_FILE")

# Load optional dependencies
OPTIONAL_DEPS=()
while IFS= read -r line; do
    OPTIONAL_DEPS+=("$line")
done < <(jq -r '.optional_dependencies[] | "\(.short):\(.name):\(.env_var | sub("LUASWIFT_INCLUDE_"; ""))"' "$CONFIG_FILE")

# Load dependency repos for cloning (stored as "name=repo" entries)
DEP_REPOS=()
while IFS= read -r line; do
    DEP_REPOS+=("$line")
done < <(jq -r '.optional_dependencies[] | "\(.name)=\(.repo)"' "$CONFIG_FILE")

# Helper to get repo URL for a dependency name
get_dep_repo() {
    local name="$1"
    for entry in "${DEP_REPOS[@]}"; do
        local entry_name="${entry%%=*}"
        if [ "$entry_name" = "$name" ]; then
            echo "${entry#*=}"
            return 0
        fi
    done
    return 1
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Get the number of optional dependencies
get_dep_count() {
    echo "${#OPTIONAL_DEPS[@]}"
}

# Get the number of Lua versions
get_lua_version_count() {
    echo "${#LUA_VERSIONS[@]}"
}

# Parse dependency entry: "N:NumericSwift:NUMERICSWIFT" -> parts
parse_dep() {
    local entry="$1"
    local field="$2"  # short, full, or env
    IFS=':' read -r short full env <<< "$entry"
    case "$field" in
        short) echo "$short" ;;
        full) echo "$full" ;;
        env) echo "$env" ;;
    esac
}

# Parse Lua version entry: "54:Lua 5.4" -> parts
parse_lua_version() {
    local entry="$1"
    local field="$2"  # code or name
    IFS=':' read -r code name <<< "$entry"
    case "$field" in
        code) echo "$code" ;;
        name) echo "$name" ;;
    esac
}

# Generate all 2^n dependency combinations
# Outputs one combination per line like "0 0 0" (all off) to "1 1 1" (all on)
# Use: while IFS= read -r combo; do ... done < <(generate_dep_combinations)
generate_dep_combinations() {
    local n=${#OPTIONAL_DEPS[@]}
    local total=$((1 << n))  # 2^n combinations

    for ((i=0; i<total; i++)); do
        local combo=""
        for ((j=0; j<n; j++)); do
            local bit=$(( (i >> j) & 1 ))
            if [ -n "$combo" ]; then
                combo="$combo $bit"
            else
                combo="$bit"
            fi
        done
        echo "$combo"
    done
}

# Generate combination name from bits
# Input: "1 0 1" -> "N+P" or "Standalone" for "0 0 0"
generate_combo_name() {
    local bits="$1"
    IFS=' ' read -ra bit_array <<< "$bits"
    local name=""
    local has_any=false

    for i in "${!bit_array[@]}"; do
        if [ "${bit_array[$i]}" = "1" ]; then
            local short=$(parse_dep "${OPTIONAL_DEPS[$i]}" "short")
            if [ -n "$name" ]; then
                name="$name+$short"
            else
                name="$short"
            fi
            has_any=true
        fi
    done

    if [ "$has_any" = false ]; then
        echo "Standalone"
    else
        echo "$name"
    fi
}

# Set environment variables for a dependency combination
# Input: "1 0 1" -> sets LUASWIFT_INCLUDE_NUMERICSWIFT=1, etc.
set_dep_env_vars() {
    local bits="$1"
    IFS=' ' read -ra bit_array <<< "$bits"

    for i in "${!bit_array[@]}"; do
        local env_suffix=$(parse_dep "${OPTIONAL_DEPS[$i]}" "env")
        export "LUASWIFT_INCLUDE_$env_suffix=${bit_array[$i]}"
    done
}

# Print current dependency configuration
print_dep_config() {
    for dep in "${OPTIONAL_DEPS[@]}"; do
        local env_suffix=$(parse_dep "$dep" "env")
        local full=$(parse_dep "$dep" "full")
        local var_name="LUASWIFT_INCLUDE_$env_suffix"
        local value="${!var_name:-1}"
        echo "  $var_name=$value ($full)"
    done
}

# Clone missing dependencies
clone_missing_deps() {
    local bits="$1"
    IFS=' ' read -ra bit_array <<< "$bits"

    for i in "${!bit_array[@]}"; do
        if [ "${bit_array[$i]}" = "1" ]; then
            local full=$(parse_dep "${OPTIONAL_DEPS[$i]}" "full")
            local parent_dir="$(cd "$SCRIPT_DIR/../.." && pwd)"

            if [ ! -d "$parent_dir/$full" ]; then
                local repo=$(get_dep_repo "$full")
                echo "Cloning $full from $repo..."
                git clone --depth 1 "$repo" "$parent_dir/$full"
            fi
        fi
    done
}

# Check if all required dependencies are cloned
check_deps_cloned() {
    local missing=()
    for dep in "${OPTIONAL_DEPS[@]}"; do
        local full=$(parse_dep "$dep" "full")
        local env_suffix=$(parse_dep "$dep" "env")
        local var_name="LUASWIFT_INCLUDE_$env_suffix"
        local value="${!var_name:-1}"
        local parent_dir="$(cd "$SCRIPT_DIR/../.." && pwd)"

        if [ "$value" = "1" ] && [ ! -d "$parent_dir/$full" ]; then
            missing+=("$full")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies (clone to parent directory):"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        return 1
    fi
    return 0
}

# Generate GitHub Actions matrix JSON for dependencies
generate_ci_dep_matrix() {
    local n=${#OPTIONAL_DEPS[@]}
    local total=$((1 << n))
    echo "["

    for ((i=0; i<total; i++)); do
        local combo=""
        local json_entry="{"

        for ((j=0; j<n; j++)); do
            local bit=$(( (i >> j) & 1 ))
            local env_suffix=$(parse_dep "${OPTIONAL_DEPS[$j]}" "env")
            local env_lower=$(echo "$env_suffix" | tr '[:upper:]' '[:lower:]')
            json_entry="$json_entry\"$env_lower\": \"$bit\", "
            combo="$combo$bit "
        done

        local name=$(generate_combo_name "${combo% }")
        json_entry="$json_entry\"name\": \"$name\"}"

        if [ $i -lt $((total - 1)) ]; then
            json_entry="$json_entry,"
        fi

        echo "  $json_entry"
    done

    echo "]"
}

# Generate GitHub Actions matrix JSON for Lua versions
generate_ci_lua_matrix() {
    echo "["
    local count=0
    local total=${#LUA_VERSIONS[@]}

    for lv in "${LUA_VERSIONS[@]}"; do
        ((count++))
        local code=$(parse_lua_version "$lv" "code")
        local name=$(parse_lua_version "$lv" "name")
        local entry="{\"lua-version\": \"$code\", \"name\": \"$name\"}"

        if [ $count -lt $total ]; then
            entry="$entry,"
        fi
        echo "  $entry"
    done

    echo "]"
}
