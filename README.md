# Netty

Netty is a small Bash-based network utility for quick host checks and port scanning.

## Description

Netty validates and normalizes IPv4 addresses, performs ping checks, runs traceroute, and performs port scans using nmap. It is designed as a simple helper script for local or authorized testing.

## Usage

```bash
./Netty.sh -i <ip_address_or_cidr> [-p <port>] [-c <cidr>] [-h]
```

### Options

* `-i`  Specify an IP address or CIDR (e.g. `192.168.1.10` or `192.168.1.0/24`).
* `-p`  Specify a port number to scan (optional).
* `-c`  Specify a CIDR suffix if needed (optional).
* `-h`  Show help and usage information.

## Examples

Scan a single host:

```bash
./Netty.sh -i 192.168.1.10
```

Scan a host on a specific port:

```bash
./Netty.sh -i 192.168.1.10 -p 22
```

Scan a CIDR network:

```bash
./Netty.sh -i 192.168.1.0/24
```

## Notes

* The script will prompt for an IP address if none is provided on the command line.
* The script writes port scan results to `scan_results.txt` in the working directory.

## Disclaimer

Use this tool only on systems and networks you own or are authorized to test. Unauthorized scanning may be illegal.

## License

MIT License
