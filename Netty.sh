#!/bin/bash

# Function to validate and normalize IP address
ip_range () {
    valid_ip="Valid"

    # User set IP
    read -p "Please enter an IP address, e.g. 127.0.0.1: " ip_address

    # Split into octets
    IFS='. ' read -ra octet <<< "$ip_address"

    # Remove spaces first
    ip_address=$(echo "$ip_address" | tr -d ' ')

    # Check only digits and dots
    if [[ "${ip_address//./}" =~ ^[[:digit:]]+$ ]]; then
        for i in "${octet[@]}"; do
            # Check length and range
            if [ "${#i}" -gt 3 ] || (( i > 255 )); then
                echo -e "IP: $ip_address \t Invalid value: $i"
                valid_ip="Invalid"
            fi
        done

        # Add missing octets as 0
        while [ "${#octet[@]}" -lt 4 ]; do
            octet+=("0")
        done    
    else 
        echo "IP can only contain digits and dots!"
        valid_ip="Invalid"
    fi

    # If valid, restructure and print
    if [[ "$valid_ip" == "Valid" ]]; then
        ip_address="${octet[0]}.${octet[1]}.${octet[2]}.${octet[3]}"
        echo "IP: $ip_address"
    fi
}

# Run function
ip_range
