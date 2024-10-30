#!/bin/bash

# Check if the user provided a filename
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ip_list_file>"
    exit 1
fi

# Get the filename from the arguments
IP_LIST_FILE=$1

# Function to run the first nmap scan
run_nmap_scan1() {
    local ip=$1
    echo "Running nmap against IP: $ip with options: -sC -sV -T4 -Pn --max-retries 1 --max-scan-delay 20"
    nmap -sC -sV -T4 -Pn --max-retries 1 --max-scan-delay 20 "$ip" -oG nmap_output
}

# Function to run the second nmap scan
run_nmap_scan2() {
    local ip=$1
    echo "Running nmap against IP: $ip to scan all ports"
    nmap -p- --min-rate=10000 -sU "$ip"
}

# Function to check for open SMB ports
check_smb_ports() {
    local ip=$1
    echo "Checking for open SMB ports (139, 445)..."
    if grep -q -E '139/open|445/open' nmap_output; then
        echo "SMB ports found, proceeding with smbmap, smbclient, and enum4linux scans."
        run_smbmap "$ip"
        run_smbclient "$ip"
        run_enum4linux "$ip"
    else
        echo "No SMB ports found."
    fi
}

# Function to check for open web ports and color the output
check_web_ports() {
    local ip=$1
    echo "Checking for open web ports (80, 8080, 443)..."
    if grep -q -E '80/open|8080/open|443/open' nmap_output; then
        echo -e "\033[1;32mWeb ports found on IP: $ip\033[0m"  # Fluorescent green
    else
        echo "No web ports found."
    fi
}

# Function to run smbmap
run_smbmap() {
    echo "Running smbmap against IP: $1"
    smbmap -H "$1"
}

# Function to run smbclient
run_smbclient() {
    echo "Running smbclient against IP: $1"
    smbclient -L "$1" -N
}

# Function to run enum4linux
run_enum4linux() {
    echo "Running enum4linux against IP: $1"
    enum4linux -a "$1"
}

# Read IP addresses from the file and execute scans
while IFS= read -r ip; do
    echo "Processing IP: $ip"
    run_nmap_scan1 "$ip"
    check_web_ports "$ip"
    check_smb_ports "$ip"
    run_nmap_scan2 "$ip"
done < "$IP_LIST_FILE"
