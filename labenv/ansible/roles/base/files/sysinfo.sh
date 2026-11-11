#!/usr/bin/env bash
# sysinfo: korte systeeminformatie

GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
line()   { printf "${GREEN}%-12s${NC} %s\n" "$1" "$2"; }

header "SYSTEM"
line "Hostname:" "$(hostname)"
line "OS:"       "$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
line "Uptime:"   "$(uptime -p)"

header "RESOURCES"
line "CPU:"      "$(nproc) cores, load $(cut -d' ' -f1-3 /proc/loadavg)"
line "Memory:"   "$(free -h | awk '/^Mem/ {print $3 " used / " $2 " total"}')"
line "Disk /:"   "$(df -h / | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}')"

header "NETWORK"
line "IP:"       "$(hostname -I)"
line "Ports:"    "$(ss -Htln | awk '{print $4}' | awk -F: '{print $NF}' | sort -nu | tr '\n' ' ')"
echo