#!/bin/bash

INTERFACE="wlo1"

# ROFI_THEME_PATH=""
TPATH="$HOME/temp/iwd_rofi_menu_files"

RAW_NETWORK_FILE="$TPATH/iwd_rofi_menu_ssid_raw.txt"                        # stores iwctl get-networks output
NETWORK_FILE="$TPATH/iwd_rofi_menu_ssid_structured.txt"                     # stores formatted output (SSID,Security,Signal Strength)
RAW_METADATA_FILE="$TPATH/iwd_rofi_menu_metadata_raw.txt"                   # stores iwctl show output
METADATA_FILE="$TPATH/iwd_rofi_menu_metadata_structured.txt"                # stores formatted output for iwctl show
TEMP_PASSWORD_FILE="$TPATH/iwd_rofi_menu_temp_ssid_password.txt"            # stores passphrase

CLEAN_UP_LIST=(
            "$RAW_NETWORK_FILE" \
            "$NETWORK_FILE" \
            "$RAW_METADATA_FILE" \
            "$METADATA_FILE" \
            "$TEMP_PASSWORD_FILE" \
            "$TPATH" \
            )
MENU_OPTIONS=(
            "󱛄  Refresh" \
            "  Enable Wi-Fi" \
            "󰖪  Disable Wi-Fi" \
            "󱚾  Network Info" \
            "󱚸  Scan Networks" \
            "󱚽  Connect" \
            "󱛅  Disconnect" \
            )
 
wifi=()                                                                 # stores network info [signal_strength, SSID, (security)]
ssid=()                                                                 # stores network SSIDs

mkdir -p "$TPATH"

function power_on() {
    nmcli radio wifi on
    sleep 2
}

function power_off() {
    nmcli radio wifi off
}

function disconnect() {
    nmcli device disconnect "$INTERFACE"
}

function check_interface_status() {
    local status=$(nmcli device status | awk -v iface="$INTERFACE" '$1 == iface {print $3}')
    case "$status" in
        connected|disconnected)
            echo "ON"
            ;;
        unavailable|unmanaged|missing)
            echo "OFF"
            ;;
        *)
            echo "OFF"
            ;;
    esac
}


function check_wifi_status() {
    local status=$(nmcli radio wifi)
    if [[ "$status" == "enabled" ]]; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# Store Network Info in files for later processing
# Issue: IF SSID contains 2 or more consecutive spaces it causes problem
#       cause the way formatting has been performed
function helper_get_networks() {
    # get networks using nmcli
    nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list > "$RAW_NETWORK_FILE"

    {
        # Add header
        echo "SSID,SECURITY,SIGNAL"

        # See iwctl get-networks output
        # Remove non-printable characters, then perform a loop
        local i=1
        local wifi_status=$(check_wifi_status)
        sed $'s/[^[:print:]\t]//g' "$RAW_NETWORK_FILE" | while read -r line; do
            # Skip the first 4 lines
            if (( i < 5 )); then
                ((i++))
                continue
            # 5th line
            elif (( i == 5 )); then
                # Depending upon wifi connection status, leading characters changes
                # Might be different on other versions, devices
                # Pull Request, If you find any better way of doing this. Thanks
                if [[ "$wifi_status" == "ON" ]]; then
                    line="${line:18}"
                else
                    line="${line:9}"
                fi
                # Replace 2 or more consecutive spaces with commas
                echo "$line" | sed 's/  \+/,/g'
                ((i++))
                continue
            fi
            # Skip non-empty lines & Replace 2 or more consecutive spaces with commas
            if [[ -z "$line" ]]; then
                continue
            fi
            echo "$line" | sed 's/  \+/,/g'
        done
    } > "$NETWORK_FILE"

    #   <number of filled star>[1;90m<number of empty star>[0m -> ██░░
    sed -e 's/\*\*\*\*\[1;90m\[0m/████/g' \
        -e 's/\*\*\*\[1;90m\*\[0m/███░/g' \
        -e 's/\*\*\[1;90m\*\*\[0m/██░░/g' \
        -e 's/\*\[1;90m\*\*\*\[0m/█░░░/g' \
        -e 's/\[1;90m\*\*\*\*\[0m/░░░░/g' \
        -e 's/\*\*\*\*/████/g' \
        "$NETWORK_FILE" > "${NETWORK_FILE}.tmp" && mv "${NETWORK_FILE}.tmp" "$NETWORK_FILE"
}

# Forwads the stored network info to rofi [Signal Strength SSID (Security)]
function get_networks() {
    ssid=()
    wifi=()
    declare -A seen_ssids

    while IFS=: read -r ssid_name security signal; do
        # Skip hidden networks
        [[ -z "$ssid_name" ]] && continue

        # Skip duplicates (keep first strongest signal)
        if [[ -n "${seen_ssids[$ssid_name]}" ]]; then
            continue
        fi
        seen_ssids["$ssid_name"]=1

        ssid+=("$ssid_name")
        if [[ "$security" == "--" ]]; then
            wifi+=("$ssid_name (Open, $signal%)")
        else
            wifi+=("$ssid_name ($security, $signal%)")
        fi
    done < <(nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list | sort -t: -k3 -nr)
}

# 2 Issues found in this function
function connect_to_network() {
    local selected_ssid="${ssid[$1]}"

    # Check if already connected
    if nmcli -t -f NAME connection show --active | grep -Fxq "$selected_ssid"; then
        rofi -e "Already connected to $selected_ssid"
        return
    fi

    # Check if network requires a password
    local sec=$(nmcli -t -f SSID,SECURITY dev wifi list | grep "^$selected_ssid:" | cut -d: -f2)
    if [[ "$sec" == "--" ]]; then
        nmcli device wifi connect "$selected_ssid"
    else
        local password
        password=$(rofi -dmenu -password -p "Password for $selected_ssid:")
        if [[ -z "$password" ]]; then
            rofi -e "No password entered."
            return
        fi
        nmcli device wifi connect "$selected_ssid" password "$password"
    fi
}


function helper_wifi_status() {
    nmcli -t -f ALL device wifi list > "$RAW_METADATA_FILE"

    {
        # Add Return and Refresh Options
        echo "󱚷  Return"
        echo "󱛄  Refresh"

        # See iwctl show output
        # Remove non-printable characters, then perform a loop
        local i=1
        sed $'s/[^[:print:]\t]//g' "$RAW_METADATA_FILE" | while read -r line; do
            # Skip the first 5 lines
            if (( i <= 5 )); then
                ((i++))
                continue
            fi
            # Skip non-empty lines
            if [[ -z "$line" ]]; then
                continue
            fi
            # Replace 2 or more consecutive spaces with commas
            echo "$line" | sed -e 's/  \+/,/g'
        done
    } > "$METADATA_FILE"

    # store the 2nd column
    while IFS=, read -r key value; do
        local list+=("$value")
    done < "$METADATA_FILE"

    echo "${list[@]}"
}

# print wifi metadata
function wifi_status() {
    # stores the values od the metadata
    local values=($(helper_wifi_status))

    # adjast spacing dynamically
    local data=$(awk -F',' '
    BEGIN { max_key_length = 0; }
    {
        # Find the maximum length of the first column
        if (length($1) > max_key_length) max_key_length = length($1);
        keys[NR] = $1;
        values[NR] = $2;
    }
    END {
        for (i = 1; i <= NR; i++) {
            # Adjust spacing dynamically to align the second column
            printf "%-*s  %s\n", max_key_length, keys[i], values[i];
        }
    }' "$METADATA_FILE")

    local selected_index=$(
        echo -e "$data" | \
        rofi -dmenu -mouse -i -p "Network Info:" \
            -theme-str 'window { width: 700px; height: 400px; }' \
            -theme-str 'entry { width: 700px; }' \
            -format i \
    )

    # Return
    if (( selected_index == 0 )); then
        return
    # Refresh
    elif (( selected_index == 1 )); then
        wifi_status
        return
    fi

    # Copies the selected feild into clipboard
    echo "${values["$selected_index"]}" | xclip -selection clipboard
}

function scan() {
    nmcli dev wifi rescan
    sleep 2
    get_networks

    menu=("󱚷  Return" "󱛇  Rescan")
    for net in "${wifi[@]}"; do
        menu+=("$net")
    done

    while :; do
        selected_wifi_index=$(
            printf "%s\n" "${menu[@]}" | \
            rofi -dmenu -mouse -i -p "SSID:" \
                -theme-str 'window { width: 400px; height: 300px; }' \
                -theme-str 'entry { width: 400px; }' \
                -format i
        )

        # Return
        if [[ -z "$selected_wifi_index" || "$selected_wifi_index" == "0" ]]; then
            return
        # Rescan
        elif [[ "$selected_wifi_index" == "1" ]]; then
            nmcli dev wifi rescan
            sleep 2
            get_networks
            menu=("󱚷  Return" "󱛇  Rescan")
            for net in "${wifi[@]}"; do
                menu+=("$net")
            done
            continue
        # Connect
        else
            connect_to_network "$((selected_wifi_index - 2))"
            return
        fi
    done
}


function rofi_cmd() {
    local options="${MENU_OPTIONS[0]}"
    local interface_status=$(check_interface_status)
    local wifi_status=$(check_wifi_status)

    if [[ "$interface_status" == "OFF" ]]; then
        options+="\n${MENU_OPTIONS[1]}"
    else
        options+="\n${MENU_OPTIONS[2]}"
        if [[ "$wifi_status" == "OFF" ]]; then
            options+="\n${MENU_OPTIONS[1]}"
        else
            options+="\n${MENU_OPTIONS[3]}"
            options+="\n${MENU_OPTIONS[4]}"
            options+="\n${MENU_OPTIONS[5]}"
            options+="\n${MENU_OPTIONS[6]}"
        fi
    fi

    local choice=$(echo -e "$options" | \
                    rofi -dmenu -mouse -i -p "Wi-Fi Menu:" \
                    -theme-str 'window { width: 400px; height: 200px; }' \
                    -theme-str 'entry { width: 400px; }' \
                )

    echo "$choice"
}

function run_cmd() {
    case "$1" in
        # Refresh menu
        "${MENU_OPTIONS[0]}")
            sleep 2
            main
            ;;
        # Turn on Wi-Fi Interface
        "${MENU_OPTIONS[1]}")
            power_on
            main
            ;;
        # Turn off Wi-Fi Interface
        "${MENU_OPTIONS[2]}")
            power_off
            ;;
        # Connection Status
        "${MENU_OPTIONS[3]}")
            wifi_status
            main
            ;;
        # List Networks | Connect
        "${MENU_OPTIONS[4]}" | "${MENU_OPTIONS[5]}")
            scan
            main
            ;;
        # Disconnect
        "${MENU_OPTIONS[6]}")
            disconnect
            ;;
        *)
            return
            ;;
    esac
}

function clean_up() {
    for item in "${CLEAN_UP_LIST[@]}"; do
        if [[ -e "$item" ]]; then
            if [[ -d "$item" ]]; then
                rmdir "$item"
            else
                rm "$item"
            fi
        fi
    done
}

function main() {
    local chosen_option=$(rofi_cmd)
    run_cmd "$chosen_option"
    clean_up
}

main