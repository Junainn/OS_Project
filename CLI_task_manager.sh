#!/bin/bash

USERS_FILE="users.txt"
LOG_FILE="actions.log"
SESSION_ACTIONS=0
SESSION_KILLS=0
SESSION_ERRORS=0

# Color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"


log_action() {
    TS="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "$TS | User: $USERNAME | $1 | PID: $2 | CMD: $3 | $4" >> "$LOG_FILE"
}

pause() {
    read -p "Press Enter to continue..."
}

start_busy_process() {
    echo -e "${YELLOW}Starting busy process: 'yes > /dev/null &'${RESET}"
    yes > /dev/null &
    BPID=$!
    echo -e "${GREEN}Started busy process with PID: $BPID${RESET}"
    log_action "STARTED_BUSY_PROCESS" "$BPID" "yes" "Started 'yes' process"
    pause
}


login() {
    for attempt in {1..3}; do
        echo "Default username: 'system', password: 'system'"
        read -p "Username: " USERNAME
        read -s -p "Password: " PASSWORD
        echo
        if grep -q "^$USERNAME:$PASSWORD$" "$USERS_FILE" 2>/dev/null; then
            echo -e "${GREEN}Login successful!${RESET}"
            log_action "LOGIN" "-" "-" "User '$USERNAME' logged in"
            return 0
        else
            echo -e "${RED}Login failed. Try again...${RESET}"
        fi
    done
    echo -e "${RED}Exceeded login attempts. Exiting.${RESET}"
    exit 1
}


processes_menu() {
    while true; do
        clear
        echo -e "${CYAN}===== Processes =====${RESET}"
        echo "1. Show Processes"
        echo "2. Filter Processes"
        echo "3. Sort Processes"
        echo "4. Terminate a Process"
        echo "5. Back to Main Menu"
        echo
        read -p "Enter your choice [1-5]: " PROC_CHOICE
        case "$PROC_CHOICE" in
            1) show_processes ;;
            2) filter_processes ;;
            3) sort_processes ;;
            4) terminate_process ;;
            5) break ;;
            *) echo -e "${RED}Invalid choice!${RESET}"; pause ;;
        esac
    done
}

show_processes() {
    echo
    echo "Sort by:"
    echo "1. CPU (most active first)"
    echo "2. Memory (most used first)"
    read -p "Select sorting [1-2]: " sort_option
    [[ "$sort_option" == "1" ]] && SORT="-%cpu" || SORT="-%mem"

    echo -e "${YELLOW}PID     USER     %MEM   %CPU   STATE  COMMAND${RESET}"
    ps -eo pid,user,%mem,%cpu,state,comm --sort=$SORT | tail -n +2 | head -15 | \
    awk -v red="$RED" -v green="$GREEN" -v yellow="$YELLOW" -v reset="$RESET" '
        $5 != "Z" {
            color=reset;
            if ($3 >= 10.0) color=red;
            else if ($4 >= 10.0) color=green;
            else if ($2 == ENVIRON["USER"]) color=yellow;
            printf "%s%-7s %-8s %-6s %-6s %-6s %s%s\n", color, $1, $2, $3, $4, $5, $6, reset
        }'
    echo
    pause
}

filter_processes() {
    read -p "Enter name/user/pattern to filter: " pattern
    echo -e "${YELLOW}PID     USER     %MEM   %CPU   STATE  COMMAND${RESET}"
    ps -eo pid,user,%mem,%cpu,state,comm | grep -i --color=never "$pattern" | tail -n +2 | head -15 | \
    awk -v yellow="$YELLOW" -v reset="$RESET" '$5 != "Z" {printf "%s%-7s %-8s %-6s %-6s %-6s %s%s\n", yellow, $1, $2, $3, $4, $5, $6, reset}'
    echo
    pause
}

sort_processes() {
    echo "Sort by:"
    echo "1. Memory"
    echo "2. CPU"
    echo "3. PID"
    echo "4. User"
    read -p "Choose [1-4]: " opt
    case "$opt" in
        1) SORT="-%mem" ;;
        2) SORT="-%cpu" ;;
        3) SORT="pid" ;;
        4) SORT="user" ;;
        *) echo -e "${RED}Invalid.${RESET}"; pause; return ;;
    esac
    echo -e "${YELLOW}PID     USER     %MEM   %CPU   STATE  COMMAND${RESET}"
    ps -eo pid,user,%mem,%cpu,state,comm --sort=$SORT | tail -n +2 | head -15 | \
    awk -v cyan="$CYAN" -v reset="$RESET" '$5 != "Z" {printf "%s%-7s %-8s %-6s %-6s %-6s %s%s\n", cyan, $1, $2, $3, $4, $5, $6, reset}'
    echo
    pause
}

terminate_process() {
    echo -e "${YELLOW}Current Processes:${RESET}"
    ps -eo pid,user,%mem,%cpu,state,comm --sort=-%cpu | tail -n +2 | head -15 | \
    awk -v red="$RED" -v green="$GREEN" -v yellow="$YELLOW" -v reset="$RESET" '
        $5 != "Z" {
            color=reset;
            if ($3 >= 10.0) color=red;
            else if ($4 >= 10.0) color=green;
            else if ($2 == ENVIRON["USER"]) color=yellow;
            printf "%s%-7s %-8s %-6s %-6s %-6s %s%s\n", color, $1, $2, $3, $4, $5, $6, reset
        }'
    echo
    read -p "Enter PID to kill (or 'b' to go back): " PID
    if [[ "$PID" =~ ^[bB]$ ]]; then
        echo "Cancelled, going back."
        pause
        return
    fi
    if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid PID.${RESET}"
        SESSION_ERRORS=$((SESSION_ERRORS+1))
        log_action "KILL_FAILED" "$PID" "-" "Invalid PID"
        pause; return
    fi
    PROC_USER=$(ps -p "$PID" -o user=)
    PROC_NAME=$(ps -p "$PID" -o comm=)
    PROC_STATE=$(ps -p "$PID" -o state=)
    if [[ -z "$PROC_NAME" || "$PROC_STATE" =~ "Z" ]]; then
        echo -e "${RED}PID not found or is a zombie.${RESET}"
        SESSION_ERRORS=$((SESSION_ERRORS+1))
        log_action "KILL_FAILED" "$PID" "-" "PID not found or zombie"
        pause; return
    fi
    if [[ "$PROC_USER" != "$USERNAME" ]]; then
        echo -e "${RED}Warning:${RESET} ${YELLOW}You are about to kill a process owned by $PROC_USER. This may require 'sudo' and could destabilize your session!${RESET}"
        read -p "Are you sure? [y/N]: " sure
        [[ ! "$sure" =~ ^[Yy]$ ]] && echo "Cancelled." && pause && return
    fi
    read -p "Are you sure you want to kill PID $PID ($PROC_NAME)? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        if kill -15 "$PID" 2>/dev/null; then
            echo -e "${GREEN}Process $PID ($PROC_NAME) terminated.${RESET}"
            SESSION_KILLS=$((SESSION_KILLS+1))
            log_action "KILLED" "$PID" "$PROC_NAME" "Normal kill"
        else
            echo -e "${RED}Failed: Try force kill with kill -9.${RESET}"
            SESSION_ERRORS=$((SESSION_ERRORS+1))
            log_action "KILL_FAILED" "$PID" "$PROC_NAME" "Termination failed"
        fi
    else
        echo "Cancelled."
    fi
    SESSION_ACTIONS=$((SESSION_ACTIONS+1))
    pause
}

view_history() {
    echo -e "${CYAN}=== Action History ===${RESET}"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "No actions logged yet."
    echo
    pause
}

session_summary() {
    echo -e "${CYAN}=== Session Summary ===${RESET}"
    echo "User: $USERNAME"
    echo "Total kill actions : $SESSION_KILLS"
    echo "Total errors       : $SESSION_ERRORS"
    echo "Total actions      : $SESSION_ACTIONS"
    echo "Last 5 actions:"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "No actions logged yet."
    echo
    pause
}

main_menu() {
    while true; do
        clear
        echo -e "${CYAN}==========================${RESET}"
        echo -e "${CYAN}   Process Manager CLI    ${RESET}"
        echo -e "${CYAN}==========================${RESET}"
        echo "1. View Processes"
        echo "2. View Action History"
        echo "3. Session Summary"
        echo "4. Start Busy Process (for demo)"
        echo "5. Exit"
        echo
        read -p "Enter your choice [1-5]: " MENU_CHOICE
        case "$MENU_CHOICE" in
            1) processes_menu ;;
            2) view_history ;;
            3) session_summary ;;
            4) start_busy_process ;;
            5)
                echo "Exiting. Goodbye!"
                log_action "LOGOUT" "-" "-" "User exited"
                session_summary
                break
                ;;
            *) echo -e "${RED}Invalid choice!${RESET}"; pause ;;
        esac
    done
}

# --- Script Entry Point ---
login
main_menu
