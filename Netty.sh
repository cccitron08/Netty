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
        alive_ip
    fi
}

ip_address=8.8.8.8

alive_ip () {
    status="Alive"
    ping_test=$(ping -i 1.5 -c 3 -q "$ip_address") 
    if [[ "$ping_test" == *"0% packet loss"* ]]; then
        echo IP "$ip_address" passed ping test
    else
        echo IP "$ip_address" failed ping test
        status="Unreachable"
    fi
    traceroute_test=$(traceroute -n -q 1 "$ip_address" | awk '{print $1, $2}')
    echo "$traceroute_test"
    if [[ "$traceroute_test" == *"$ip_address" ]]; then
        echo IP "$ip_address" passed traceroute test
    else
        echo IP "$ip_address" failed traceroute test
        status="Unreachable"
    fi
    if [[ "$status" == "Alive" ]]; then
        echo Target "$ip_address" is alive!
    else
        echo Target "$ip_address" in unreachable!
    fi

}
alive_ip