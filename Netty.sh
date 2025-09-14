#!/bin/bash


GREEN='\033[0;32m'
GRAY='\033[1;30m'
NC='\033[0m'

echo -e "  g${GRAY}========================================${NC}"
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
        test_ip 
    fi
}

# Tests if the IP is reachable or not
test_ip () {
    status="Alive"
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
}

# Help flag response
show_help() {
  echo "Usage: $0 -p <port> -i <ip_address> -c <cidr> [-h]"
  echo ""
  echo "Options:"
  echo "  -p    Specify port number"
  echo "  -i    Specify IP address"
  echo "  -h    Show this help message"
}


while getopts "p:i:h:c:" opt; do
    case $opt in
        p) port=$OPTARG; ;; # Flag for specifing the port
        h) show_help; exit 0 ;; # Flag for help
        i) ip_address=$OPTARG; ;; # Flag for specifing the ip address
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
