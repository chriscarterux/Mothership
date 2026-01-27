#!/bin/bash
# AI Tool Adapter System
# Provides a unified interface for different AI coding assistants

# Supported tools and their invocation patterns
declare -A AI_TOOLS=(
    # Primary tools (user's preferred)
    ["claude"]="claude|--print|--file|Claude Code CLI"
    ["gemini"]="gemini|--prompt|--|Google Gemini CLI"
    ["codex"]="codex|--prompt|--|OpenAI Codex CLI"
    ["opencode"]="opencode|--prompt|--|OpenCode CLI"

    # Additional tools
    ["amp"]="amp|--prompt|--file|AMP Code CLI"
    ["cursor"]="cursor|--prompt|--|Cursor (via CLI)"
    ["custom"]="$CUSTOM_AI_CMD|$CUSTOM_PROMPT_FLAG|$CUSTOM_FILE_FLAG|Custom AI tool"
)

# Detect available AI tool (in order of preference)
detect_ai_tool() {
    # Check environment variable first
    if [[ -n "$AI_TOOL" ]]; then
        echo "$AI_TOOL"
        return 0
    fi

    # Auto-detect in order of preference
    local tools=("claude" "gemini" "codex" "opencode" "amp" "cursor")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "$tool"
            return 0
        fi
    done

    return 1
}

# Get tool configuration
get_tool_config() {
    local tool="$1"
    local field="$2"  # command, prompt_flag, file_flag, description

    local config="${AI_TOOLS[$tool]}"
    if [[ -z "$config" ]]; then
        echo ""
        return 1
    fi

    case "$field" in
        command)     echo "$config" | cut -d'|' -f1 ;;
        prompt_flag) echo "$config" | cut -d'|' -f2 ;;
        file_flag)   echo "$config" | cut -d'|' -f3 ;;
        description) echo "$config" | cut -d'|' -f4 ;;
    esac
}

# Invoke AI tool with prompt
invoke_ai() {
    local tool="$1"
    local prompt="$2"
    local prompt_file="$3"  # Optional: file containing the prompt

    local cmd=$(get_tool_config "$tool" "command")
    local prompt_flag=$(get_tool_config "$tool" "prompt_flag")
    local file_flag=$(get_tool_config "$tool" "file_flag")

    if [[ -z "$cmd" ]]; then
        echo "Error: Unknown AI tool '$tool'" >&2
        return 1
    fi

    # Build command based on tool capabilities
    case "$tool" in
        claude)
            # Claude Code uses --print for non-interactive mode
            if [[ -n "$prompt_file" ]]; then
                $cmd --print "$(cat "$prompt_file")" "$prompt"
            else
                $cmd --print "$prompt"
            fi
            ;;
        gemini)
            # Google Gemini CLI
            if [[ -n "$prompt_file" ]]; then
                $cmd "$prompt_flag" "$(cat "$prompt_file") $prompt"
            else
                $cmd "$prompt_flag" "$prompt"
            fi
            ;;
        codex)
            # OpenAI Codex CLI
            if [[ -n "$prompt_file" ]]; then
                $cmd "$prompt_flag" "$(cat "$prompt_file") $prompt"
            else
                $cmd "$prompt_flag" "$prompt"
            fi
            ;;
        opencode)
            # OpenCode CLI
            if [[ -n "$prompt_file" ]]; then
                $cmd "$prompt_flag" "$(cat "$prompt_file") $prompt"
            else
                $cmd "$prompt_flag" "$prompt"
            fi
            ;;
        *)
            # Generic invocation for other tools
            if [[ "$prompt_flag" != "--" ]]; then
                $cmd $prompt_flag "$prompt"
            else
                echo "$prompt" | $cmd
            fi
            ;;
    esac
}

# Check if tool supports a feature
tool_supports() {
    local tool="$1"
    local feature="$2"  # streaming, files, context, etc.

    case "$tool" in
        claude)
            case "$feature" in
                streaming|files|context|mcp) echo "yes" ;;
                *) echo "no" ;;
            esac
            ;;
        amp)
            case "$feature" in
                streaming|files|context) echo "yes" ;;
                *) echo "no" ;;
            esac
            ;;
        aider)
            case "$feature" in
                files|context|git) echo "yes" ;;
                streaming) echo "partial" ;;
                *) echo "no" ;;
            esac
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# List all supported tools
list_tools() {
    echo "Supported AI Tools:"
    echo ""
    for tool in "${!AI_TOOLS[@]}"; do
        local desc=$(get_tool_config "$tool" "description")
        local cmd=$(get_tool_config "$tool" "command")
        if command -v "$cmd" &> /dev/null 2>&1; then
            echo "  ✓ $tool - $desc (installed)"
        else
            echo "  · $tool - $desc"
        fi
    done
}

# Export functions for use in other scripts
export -f detect_ai_tool
export -f get_tool_config
export -f invoke_ai
export -f tool_supports
export -f list_tools
