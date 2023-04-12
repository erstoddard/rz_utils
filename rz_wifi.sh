#!/bin/bash

# Function to reset interface
function reset_interface()
{
    # Kill WPA supplicant if running
    killall wpa_supplicant &> /dev/null

    # Reset interface
    ifconfig mlan0 down
    ifconfig mlan0 up
}

# Function to scan networks
function scan_networks()
{
    # Get array of SSIDs
    readarray SSID_LIST < <(iwlist mlan0 s | grep SSID | cut -f2- -d: | grep -v '""')

    # Export list
    export SSID_LIST
}

function print_ssid_list()
{
    INDEX=0;
    for SSID in "${SSID_LIST[@]}"; do
        echo -ne "\t ${INDEX}: ${SSID}"
        INDEX=$((INDEX+1))
    done;
}

# Function to prompt for ssid
function prompt_ssid()
{
    clear
    echo "Discovered Networks:"

    while : ; do
        # Print List
        print_ssid_list

        # Prompt for input
        echo -n "Selection: "
        read SELECTION

        # Get selected SSID
        SELECTED_SSID=${SSID_LIST[${SELECTION}]}
        SELECTED_SSID=$(echo ${SELECTED_SSID//[$'\t\r\n']} | tr -d '"')

        # Check if entry exists
        if [ -z "${SELECTED_SSID}" ]; then
            clear
            echo "Invalid Selection."
        else
            export SELECTED_SSID
            break
        fi;
    done;
}

# Function to prompt password
function prompt_password()
{
    clear

    echo -n "Enter Password for ${SELECTED_SSID}: "
    read -s PSK
    echo ""
    export PSK
}

# Function to configure and connect
function configure_and_connect()
{
    # Update configuration
    echo "wpa_passphrase \"${SELECTED_SSID}\" \"${PSK}\""
    wpa_passphrase "${SELECTED_SSID}" "${PSK}" > /etc/wpa_supplicant.conf

    # Start access point
    wpa_supplicant -B -i mlan0 -c /etc/wpa_supplicant.conf

    # Obtain IP Address
    udhcpc -i mlan0 -n -R
}

# Entrypoint
function main()
{
    # Clean slate
    clear

    # Scan for networks
    echo "Scanning networks..."
    scan_networks

    # Prompt for SSID
    prompt_ssid
    echo "Selected SSID: ${SELECTED_SSID}"

    # Prompt for password
    prompt_password

    configure_and_connect
}

# Call entrypoint
main "$@"