#!/bin/bash

all_scan=false
fping_scan=false

GREEN='\033[0;32m'
GRAY='\033[1;30m'
NC='\033[0m'

echo -e "  ${GRAY}========================================${NC}"
echo -e "\t${GRAY} _   _      _   _         ${NC}"
echo -e "\t${GREEN}| \\ | | ___| |_| |_ _   _ ${NC}"
echo -e "\t${GRAY}|  \\| |/ _ \\ __| __| | | |${NC}"
echo -e "\t${GREEN}| |\\  |  __/ |_| |_| |_| |${NC}"
echo -e "\t${GRAY}|_| \\_|\\___|\\__|\\__|\\__, |${NC}"
echo -e "\t${GRAY}                    |___/ ${NC}"
echo -e "  ${GRAY}========================================${NC}"
# Function to validate and normalize IP address
ip_range () {
    valid_ip="Valid"

    # User set IP
    if [[ -z "$ip_address" ]]; then
        read -p "Please enter an IP address, e.g. 127.0.0.1: " ip_address
    fi

    # Gets CIDR
    cidr="/${ip_address##*/}"
    echo $cidr

    # Remove spaces first
    ip_address=$(echo "$ip_address" | tr -d ' ' | cut -d'/' -f1)
    
    # Split into octets
    IFS='. ' read -ra octet <<< "$ip_address"

    # Check only digits and dots
    if [[ "${ip_address//./}" =~ ^[[:digit:]]+$ ]]; then
        for i in "${octet[@]}"; do
            # Check length and range
            if [ "${#i}" -gt 3 ] || (( i > 255 )); then
                echo -e "IP: "$ip_address" \t Invalid value: $i"
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
        ip_address="${octet[0]}.${octet[1]}.${octet[2]}.${octet[3]}${cidr}"
        echo "IP:$ip_address" 
        echo $fping_scan
        if ! $fping_scan; then
            test_ip
        else
            subnet_ping
        fi
    fi
}

# Tests if the IP is reachable or not
test_ip () {
    status="Alive"
    echo $fping_scan
    ping_test=$(ping -i 1.5 -c 3 -q "$ip_address")  # Pings the IP
    if [[ "$ping_test" == *"0% packet loss"* ]]; then
        echo IP "$ip_address""$cidr": passed ping test
    else
        echo IP "$ip_address": failed ping test
        status="Unreachable"
    fi
    traceroute_test=$(traceroute -n -q 1 "$ip_address" | awk '{print $1, $2}') # Traceroute the IP
    if [[ "$traceroute_test" == *"$ip_address" ]]; then
        echo IP "$ip_address": passed traceroute test
    else
        echo IP "$ip_address": failed traceroute test
        status="Unreachable"
    fi
    if [[ "$status" == "Alive" ]]; then
        echo Target "$ip_address": is alive!
        port_scan
    else
        echo Target "$ip_address": in unreachable!
    fi

}

port_scan () {
    if [[ -z "$port" ]]; then
        echo No port specified, scanning TOP 1000 common ports!
        top_scan=$(nmap "$ip_address" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo Port scan results saved in "scan_results.txt"g
        echo "$top_scan" > scan_results.txt
    else
        echo Scanning port "$port"
        port_scan=$(nmap "$ip_address" -p "$port" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo Port scan results saved in "scan_results.txt"
        echo "$port_scan" > scan_results.txt
    fi
    if $all_scan; then
        echo Flag -a specified, scanning all ports!
        all_port_scan=$(nmap -p- --open "$ip_address" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo Saving results into "all_ports_results.txt"
        echo "$all_port_scan" > all_ports_results.txt
    fi
}

subnet_ping () {
    fping -a -g "$ip_address" 2>/dev/null | tee ./fping_results.txt
}

# Help flag response
show_help() {
  echo "Usage: $0 -p <port> -i <ip_address> -c <cidr> [-h]"
  echo ""
  echo "Options:"
  echo "  -p    Specify port number"
  echo "  -i    Specify IP address"
  echo "  -h    Show this help message"
  echo "  -a    Scan all ports"
  echo "  -s    Pings a subnet"
}


while getopts "p:i:h:c:a s" opt; do
    case $opt in
        p) port=$OPTARG; ;; # Flag for specifing the port
        h) show_help; exit 0 ;; # Flag for help
        i) ip_address=$OPTARG; ;; # Flag for specifing the ip address
        a) all_scan=true; ;;  # Flag for nmap to scan all ports
        s) fping_scan=true; ;; # Flag for fping to scan whole subnet
        *) echo "invalid option";show_help; exit 1 ; # Invalid option response
    esac
done

# Check if the variable $port is non-empty AND not a valid number
if [[ -n "$port" && ! "$port" =~ ^[0-9]+$ ]]; then
    # If $port contains something but it's not a number, print an error message
    echo "Port can only be a number 0-65535"
    # Exit the script with a non-zero status to indicate an error
    exit 1
else
    ip_range
fi
