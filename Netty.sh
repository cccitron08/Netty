#!/bin/bash

############################################################
#                   Network Scan Script                   #
#   Validates IP/CIDR, optionally scans ports or subnet   #
#   Written for Bash, uses ping, traceroute, nmap, fping  #
############################################################

#------------------------------------------
# Flags and Configuration
#------------------------------------------
scan_all_ports=false       # If -a flag is set, scan all ports
subnet_scan=false         # If -s flag is set, scan a subnet

# Terminal colors
COLOR_GREEN='\033[0;32m'
COLOR_GRAY='\033[1;30m'
COLOR_NONE='\033[0m'

#------------------------------------------
# Banner
#------------------------------------------
echo -e "  ${COLOR_GRAY}========================================${COLOR_NONE}"
echo -e "\t${COLOR_GRAY} _   _      _   _         ${COLOR_NONE}"
echo -e "\t${COLOR_GREEN}| \\ | | ___| |_| |_ _   _ ${COLOR_NONE}"
echo -e "\t${COLOR_GRAY}|  \\| |/ _ \\ __| __| | | |${COLOR_NONE}"
echo -e "\t${COLOR_GREEN}| |\\  |  __/ |_| |_| |_| |${COLOR_NONE}"
echo -e "\t${COLOR_GRAY}|_| \\_|\\___|\\__|\\__|\\__, |${COLOR_NONE}"
echo -e "\t${COLOR_GRAY}                    |___/ ${COLOR_NONE}"
echo -e "  ${COLOR_GRAY}========================================${COLOR_NONE}"

#------------------------------------------
# Function: Display Help
#------------------------------------------
show_help() {
    echo "Usage: $0 -p <port> -i <ip_address> -c <cidr> [-h]"
    echo ""
    echo "Options:"
    echo "  -p    Specify port number"
    echo "  -i    Specify IP address"
    echo "  -h    Show this help message"
    echo "  -a    Scan all ports"
    echo "  -s    Scan a subnet"
}

#------------------------------------------
# Function: Validate and Normalize IP
#------------------------------------------
validate_ip () {
    ip_status="Valid"

    # Ask user for IP if not provided
    if [[ -z "$target_ip" ]]; then
        read -p "Enter an IP address (e.g., 127.0.0.1): " target_ip
    fi

    # Extract CIDR only if present
    if [[ "$target_ip" == */* ]]; then
        target_cidr="/${target_ip##*/}"
    else
        target_cidr=""
    fi

    # Remove spaces and CIDR for validation
    target_ip=$(echo "$target_ip" | tr -d ' ' | cut -d'/' -f1)
    
    # Split IP into octets
    IFS='. ' read -ra ip_octets <<< "$target_ip"

    # Validate digits and dots
    if [[ "${target_ip//./}" =~ ^[[:digit:]]+$ ]]; then
        for octet in "${ip_octets[@]}"; do
            if [ "${#octet}" -gt 3 ] || (( octet > 255 )); then
                echo -e "Error: IP $target_ip has invalid octet: $octet"
                ip_status="Invalid"
            fi
        done

        # Pad missing octets with zeros
        while [ "${#ip_octets[@]}" -lt 4 ]; do
            ip_octets+=("0")
        done    
    else 
        echo "Error: IP must contain only digits and dots!"
        ip_status="Invalid"
    fi

    # If valid, reconstruct IP and proceed
    if [[ "$ip_status" == "Valid" ]]; then
        target_ip="${ip_octets[0]}.${ip_octets[1]}.${ip_octets[2]}.${ip_octets[3]}${target_cidr}"
        echo -e "${COLOR_GREEN}Normalized IP: $target_ip${COLOR_NONE}"

        # Choose scan method
        if ! $subnet_scan; then
            run_ping_test
        else
            run_subnet_scan
        fi
    fi
}

#------------------------------------------
# Function: Ping and Traceroute Test
#------------------------------------------
run_ping_test () {
    host_status="Alive"

    # Ping the host
    ping_output=$(ping -i 1.5 -c 3 -q "$target_ip")
    if [[ "$ping_output" == *"0% packet loss"* ]]; then
        echo -e "${COLOR_GREEN}Ping successful: $target_ip$target_cidr${COLOR_NONE}"
    else
        echo -e "${COLOR_GRAY}Ping failed: $target_ip${COLOR_NONE}"
        host_status="Unreachable"
    fi

    # Traceroute test
    traceroute_output=$(traceroute -n -q 1 "$target_ip" | awk '{print $1, $2}')
    if [[ "$traceroute_output" == *"$target_ip" ]]; then
        echo -e "${COLOR_GREEN}Traceroute successful: $target_ip${COLOR_NONE}"
    else
        echo -e "${COLOR_GRAY}Traceroute failed: $target_ip${COLOR_NONE}"
        host_status="Unreachable"
    fi

    # Proceed if host is alive
    if [[ "$host_status" == "Alive" ]]; then
        echo -e "${COLOR_GREEN}Target $target_ip is alive!${COLOR_NONE}"
        run_port_scan
    else
        echo -e "${COLOR_GRAY}Target $target_ip is unreachable!${COLOR_NONE}"
    fi
}

#------------------------------------------
# Function: Perform Port Scan
#------------------------------------------
run_port_scan () {
    echo -e "${COLOR_GRAY}Starting port scan for $target_ip...${COLOR_NONE}"

    # Scan top ports if no specific port provided
    if [[ -z "$target_port" ]]; then
        echo "No port specified. Scanning top 1000 common ports..."
        scan_output=$(nmap "$target_ip" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo "Port scan results saved in scan_results.txt"
        echo "$scan_output" > scan_results.txt
    else
        echo "Scanning port $target_port..."
        port_output=$(nmap "$target_ip" -p "$target_port" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo "Port scan results saved in scan_results.txt"
        echo "$port_output" > scan_results.txt
    fi

    # Scan all ports if -a flag is set
    if $scan_all_ports; then
        echo "Flag -a set: Scanning all ports..."
        all_ports_output=$(nmap -p- --open "$target_ip" | awk '/^PORT/ || /^[0-9]+\/tcp/ { print }')
        echo "Saving results to all_ports_results.txt"
        echo "$all_ports_output" > all_ports_results.txt
    fi

    echo -e "${COLOR_GREEN}Port scan completed for $target_ip${COLOR_NONE}"
}

#------------------------------------------
# Function: Scan Subnet using fping
#------------------------------------------
run_subnet_scan () {
    echo -e "${COLOR_GRAY}Scanning subnet for live hosts...${COLOR_NONE}"
    fping -a -g "$target_ip" 2>/dev/null | tee ./fping_results.txt
    echo -e "${COLOR_GREEN}Subnet scan completed.${COLOR_NONE}"
    echo -e "${COLOR_GREEN}Results saved in fping_results.txt.${COLOR_NONE}"
}   

#------------------------------------------
# Command-line Argument Parsing
#------------------------------------------
while getopts "p:i:h:as" opt; do
    case $opt in
        p) target_port=$OPTARG ;;       # Port number
        h) show_help; exit 0 ;;         # Show help
        i) target_ip=$OPTARG ;;         # Target IP address
        a) scan_all_ports=true ;;       # Scan all ports flag
        s) subnet_scan=true ;;          # Subnet scan flag
        *) echo "Invalid option"; show_help; exit 1 ;;
    esac
done

#------------------------------------------
# Validate Port Number if Provided
#------------------------------------------
if [[ -n "$target_port" && ! "$target_port" =~ ^[0-9]+$ ]]; then
    echo "Error: Port must be a number (0-65535)"
    exit 1
else
    validate_ip
fi
