#!/usr/bin/awk -f

#
# Parse lspci -xxx and output the needed setpci commands to restore PCI
# configuration space.  Output can be sourced to GRUB2
#
# Usage: lspci -xxx | awk -f lspci_parse.awk
#        lspci -xxx -s [[[[<domain>]:]<bus>]:][<slot>][.[<func>]] | awk -f lspci_parse.awk
#
# You will probably have to execute lspci as root.  Please read lspci(8) and setpci(8)
#

$1 ~ /^([0-9a-f]+:)?[0-9a-f]+:[0-9a-f]+.[0-9a-f]+$/ {
  device = $1
}
$1 ~ /^[0-9a-f]+0:$/ {
	high = substr($1, 1, length($1) - 2)
	printf "setpci -s %s %s0.L=%s%s%s%s\n", device, high, $5,  $4,  $3,  $2
	printf "setpci -s %s %s4.L=%s%s%s%s\n", device, high, $9,  $8,  $7,  $6
	printf "setpci -s %s %s8.L=%s%s%s%s\n", device, high, $13, $12, $11, $10
	printf "setpci -s %s %sc.L=%s%s%s%s\n", device, high, $17, $16, $15, $14
}
