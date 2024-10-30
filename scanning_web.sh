#!/bin/bash

# Check if a hostname is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

HOSTNAME="$1"

# Run the first Nmap command
echo "Running Nmap service scan..."
nmap_results=$(nmap -sC -sV -T4 -Pn --max-retries 1 --max-scan-delay 20 "$HOSTNAME")

# Check for open web ports
echo "Checking for open web ports..."
open_ports=()
for port in 80 8080 443; do
    if echo "$nmap_results" | grep -q "$port/tcp.*open"; then
        open_ports+=("$port")
        echo "Port $port is open."
    fi
done

# If no web ports are found, exit
if [ ${#open_ports[@]} -eq 0 ]; then
    echo "No web ports found. Exiting."
    exit 0
fi

# Run the second Nmap command for UDP scans
echo "Running Nmap for UDP scans..."
nmap -p- --min-rate=10000 -sU "$HOSTNAME"

# Run Nikto on open web ports
for port in "${open_ports[@]}"; do
    echo "Running Nikto on port $port..."
    nikto -h "$HOSTNAME" -p "$port"
done

# Run FFUF on open web ports
for port in "${open_ports[@]}"; do
    echo "Running FFUF on port $port..."
    ffuf -u "http://$HOSTNAME:$port/FUZZ" -w /path/to/wordlist.txt
done

echo "All scans completed."
