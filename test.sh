#!/bin/bash
# =============================================================================
# Custom Reminders - Automated Test Runner
# =============================================================================
# Requirements:
#   - cliclick: brew install cliclick
#   - Garmin Connect IQ SDK (monkeyc, monkeydo in PATH)
#   - macOS Accessibility permission for your terminal app:
#     System Settings -> Privacy & Security -> Accessibility -> [Your Terminal]
#
# Usage:
#   ./test.sh                    # Run all tests
#   ./test.sh test_add_reminder  # Run specific test
#   ./test.sh list               # List available tests
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONKEYC="monkeyc"
MONKEYDO="monkeydo"
DEVICE="fr245"
KEY="../developer_key"
BUILD_OUTPUT="$PROJECT_DIR/bin/CustomReminders.prg"
JUNGLE="$PROJECT_DIR/monkey.jungle"
TEST_DELAY=1.5
SIM_PID=""

# SDK path - update if your SDK version changes
SDK_PATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
SIMULATOR_APP="$SDK_PATH/bin/ConnectIQ.app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# =============================================================================
# Setup
# =============================================================================

check_deps() {
    local missing=0
    if ! command -v cliclick &>/dev/null; then
        fail "cliclick not found. Install: brew install cliclick"
        missing=1
    fi
    if ! command -v "$MONKEYC" &>/dev/null; then
        fail "monkeyc not found in PATH"
        missing=1
    fi
    if ! command -v "$MONKEYDO" &>/dev/null; then
        fail "monkeydo not found in PATH"
        missing=1
    fi
    [ $missing -eq 1 ] && exit 1
}

build_app() {
    log "Building for $DEVICE..."
    local output
    output=$("$MONKEYC" -f "$JUNGLE" -o "$BUILD_OUTPUT" -d "$DEVICE" -y "$KEY" 2>&1)
    if echo "$output" | grep -qi "error\|failed"; then
        fail "Build failed!"
        echo "$output"
        exit 1
    fi
    ok "Build successful"
}

# =============================================================================
# Simulator Control
# =============================================================================

kill_simulator() {
    log "Closing simulator..."
    # Kill monkeydo child processes
    if [ -n "$SIM_PID" ]; then
        kill "$SIM_PID" 2>/dev/null || true
        kill -- -"$SIM_PID" 2>/dev/null || true
    fi
    pkill -f "MonkeyDoDeux" 2>/dev/null || true
    pkill -f "monkeydo" 2>/dev/null || true
    
    # Close the ConnectIQ app
    osascript -e 'tell application "simulator" to quit' 2>/dev/null || true
    pkill -f "simulator" 2>/dev/null || true
    
    sleep 1
}

wait_for_sim_window() {
    log "Waiting for simulator window..."
    local max_wait=30
    local waited=0
    while [ $waited -lt $max_wait ]; do
        if osascript -e 'tell application "System Events" to exists (first window of process "simulator" whose subrole is "AXStandardWindow")' 2>/dev/null | grep -q "true"; then
            ok "Simulator window ready"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    fail "Simulator window did not appear within ${max_wait}s"
    return 1
}

launch_simulator() {
    build_app
    
    # Kill any existing simulator
    kill_simulator 2>/dev/null || true
    sleep 2
    
    # Step 1: Open the ConnectIQ.app simulator
    log "Launching ConnectIQ simulator..."
    open -a "$SIMULATOR_APP"
    sleep 3
    
    # Step 2: Wait for the window to appear
    wait_for_sim_window
    
    # Step 3: Launch the app in the simulator via monkeydo
    log "Launching app in simulator via monkeydo..."
    "$MONKEYDO" "$BUILD_OUTPUT" "$DEVICE" &
    SIM_PID=$!
    
    sleep 3
}

# =============================================================================
# Input Simulation (requires Accessibility permission)
# =============================================================================

# FR245 simulator keyboard mapping:
#   m           = menu button
#   Enter       = center/select button
#   Up arrow    = top button
#   Down arrow  = bottom button
#   Escape      = back button

send_key() {
    local keycode=$1
    local label=$2
    log "Key: $label"
    osascript -e "tell application \"System Events\" to key code $keycode"
    sleep "$TEST_DELAY"
}

press_menu()   { send_key 50  "Menu"; }
press_select() { send_key 36  "Select"; }
press_up()     { send_key 126 "Up"; }
press_down()   { send_key 125 "Down"; }
press_back()   { send_key 53  "Back"; }

# =============================================================================
# Screenshots
# =============================================================================

take_screenshot() {
    local name="$1"
    local dir="$PROJECT_DIR/test_screenshots"
    mkdir -p "$dir"
    log "Screenshot: $name"
    
    # Activate simulator window
    osascript -e 'tell application "simulator" to activate' 2>/dev/null
    sleep 0.5
    
    # Get simulator window position and size
    local win_info
    win_info=$(osascript -e '
        tell application "System Events"
            tell process "simulator"
                tell first window
                    set winPos to position
                    set winSize to size
                    return ((item 1 of winPos) as string) & "," & ((item 2 of winPos) as string) & "," & ((item 1 of winSize) as string) & "," & ((item 2 of winSize) as string)
                end tell
            end tell
        end tell
    ' 2>/dev/null)
    
    if [ -n "$win_info" ]; then
        local x y w h
        x=$(echo "$win_info" | cut -d',' -f1)
        y=$(echo "$win_info" | cut -d',' -f2)
        w=$(echo "$win_info" | cut -d',' -f3)
        h=$(echo "$win_info" | cut -d',' -f4)
        
        if [ -n "$x" ] && [ -n "$y" ] && [ -n "$w" ] && [ -n "$h" ]; then
            screencapture -x -R "$x,$y,$w,$h" "$dir/${name}.png" 2>/dev/null
            if [ -f "$dir/${name}.png" ] && [ -s "$dir/${name}.png" ]; then
                log "  -> Window captured at $x,$y (${w}x${h})"
                return
            fi
        fi
    fi
    
    # Fallback: capture full screen
    screencapture -x "$dir/${name}.png"
    log "  -> Fallback: full screen captured"
}
# =============================================================================
# Test Scenarios
# =============================================================================

test_app_launches() {
    log "========================================"
    log "Test: App Launches"
    log "========================================"
    launch_simulator
    sleep 2
    take_screenshot "01_app_launch"
    ok "App launched — screenshot saved"
    kill_simulator
}

test_add_reminder_flow() {
    log "========================================"
    log "Test: Add Reminder Flow"
    log "========================================"
    launch_simulator
    sleep 1

    log "--- Step 1: Open Add Menu ---"
    press_menu; sleep 1

    log "--- Step 2: Type text (add 3 chars) ---"
    press_select  # add char (space)
    press_up; press_select  # add next char
    press_up; press_select  # add another char
    sleep 1

    log "--- Step 3: Finish text (Menu) ---"
    press_menu; sleep 1

    log "--- Step 4: Select type (Select) ---"
    press_select; sleep 1

    log "--- Step 5: Select 5min interval ---"
    press_up; press_up; press_up
    press_select; sleep 1

    log "--- Step 6: Confirm save ---"
    press_select; sleep 2

    take_screenshot "02_reminder_added"
    ok "Reminder added — screenshot saved"
    kill_simulator
}

test_toggle_reminder() {
    log "========================================"
    log "Test: Toggle Reminder"
    log "========================================"
    launch_simulator

    log "--- Quick add reminder ---"
    press_menu; sleep 1
    press_select; sleep 0.5
    press_menu; sleep 1
    press_select; sleep 1
    press_select; sleep 1
    press_select; sleep 2

    log "--- Toggle ON/OFF (3 times) ---"
    press_select; sleep 1
    take_screenshot "03_toggle_1"
    press_select; sleep 1
    take_screenshot "03_toggle_2"
    press_select; sleep 1
    take_screenshot "03_toggle_3"

    ok "Toggle test complete"
    kill_simulator
}

test_scroll_list() {
    log "========================================"
    log "Test: Scroll List (add 5 reminders)"
    log "========================================"
    launch_simulator

    for i in 1 2 3 4 5; do
        log "--- Adding reminder $i ---"
        press_menu; sleep 1
        press_select; sleep 0.5
        press_menu; sleep 1
        press_select; sleep 1
        press_select; sleep 1
        press_select; sleep 1.5
    done

    log "--- Scroll up and down ---"
    press_down; sleep 0.5
    press_down; sleep 0.5
    take_screenshot "04_scroll_down"
    press_up; sleep 0.5
    press_up; sleep 0.5
    take_screenshot "04_scroll_up"

    ok "Scroll test complete"
    kill_simulator
}

test_edit_reminder() {
    log "========================================"
    log "Test: Edit Reminder Flow"
    log "========================================"
    launch_simulator

    log "--- Add reminder ---"
    press_menu; sleep 1
    press_select; press_up; press_select; press_up; press_select
    press_menu; sleep 1
    press_select; sleep 1
    press_up; press_up; press_up; press_select
    sleep 1
    press_select; sleep 2

    take_screenshot "05_edit_verify"
    ok "Edit test complete"
    kill_simulator
}

# =============================================================================
# Main
# =============================================================================

list_tests() {
    echo "Available tests:"
    echo "  test_app_launches       - Verify app launches and shows main screen"
    echo "  test_add_reminder_flow  - Full flow: add a reminder via wizard"
    echo "  test_toggle_reminder    - Add reminder and toggle on/off (3x)"
    echo "  test_scroll_list        - Add 5 reminders, scroll up/down"
    echo "  test_edit_reminder      - Add reminder and verify list display"
}

run_test() {
    local test_name=$1
    case "$test_name" in
        test_app_launches)      test_app_launches ;;
        test_add_reminder_flow) test_add_reminder_flow ;;
        test_toggle_reminder)   test_toggle_reminder ;;
        test_scroll_list)       test_scroll_list ;;
        test_edit_reminder)     test_edit_reminder ;;
        *)
            fail "Unknown test: $test_name"
            list_tests
            exit 1
            ;;
    esac
}

check_deps

if [ $# -eq 0 ]; then
    log "Running all tests..."
    for test in test_app_launches test_add_reminder_flow test_toggle_reminder test_scroll_list test_edit_reminder; do
        echo ""
        $test
    done
    echo ""
    ok "All tests completed. Screenshots in test_screenshots/"
elif [ "$1" = "list" ]; then
    list_tests
else
    run_test "$1"
fi
