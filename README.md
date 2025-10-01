# Netty

Netty is a small Bash-based network utility for quick host checks, ping/traceroute diagnostics, and port scanning.

DISCLAIMER: THIS TOOL IS MADE ONLY FOR LEARNING PURPOSES TO UNDERSTAND BASH SCRIPTING.
I DON'T RECCOMEND USING IT, OR CLONING IT ONTO YOUR SYSTEM AS IT PROBABLY CAN BE USED TO PERFORM A PRIVILEGE ESCALATION ON YOUR SYSTEM!!!! 

## Description

Netty validates and normalizes IPv4 addresses, performs ping checks, runs traceroute, and performs port scans using `nmap`. It also supports scanning entire subnets using `fping`. It is designed as a simple helper script for local or authorized testing.

## Usage

```bash
./Netty.sh -i <ip_address_or_cidr> [-p <port>] [-a] [-s] [-h]

Options

    -i Specify an IP address or CIDR (e.g. 192.168.1.10 or 192.168.1.0/24).

    -p Specify a port number to scan (optional).

    -a Scan all ports on the host (optional).

    -s Scan a subnet for live hosts (optional).

    -h Show help and usage information.

Examples

Scan a single host:

./Netty.sh -i 192.168.1.10

Scan a host on a specific port:

./Netty.sh -i 192.168.1.10 -p 22

Scan a host on all ports:

./Netty.sh -i 192.168.1.10 -a

Scan a CIDR network for live hosts:

./Netty.sh -i 192.168.1.0/24 -s

Notes

    The script will prompt for an IP address if none is provided on the command line.

    Port scan results are saved in scan_results.txt.

    All ports scan results are saved in all_ports_results.txt.

    Subnet scan results are saved in fping_results.txt.

This script is made only for learning purposes!

Disclaimer

Use this tool only on systems and networks you own or are authorized to test. Unauthorized scanning may be illegal.
