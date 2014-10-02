#!/bin/bash
############################################################################
#    Copyright (C) 2009 by Roland Philippsen, Ralf 'Decan' Kaestner        #
#    ralf.kaestner@gmail.com                                               #
#                                                                          #
#    This program is free software; you can redistribute it and#or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

# Create an external network loop between two local interfaces
# See usage for a description of the arguments

. ubash

script_init "Create an external network loop between two local interfaces" \
  "SRC-IF" LOOPSRCIF "eth0" "source interface" \
  "DST-IF" LOOPDSTIF "eth1" "destination interface"
script_setopt "--fake-src-ip" "" LOOPFAKESRCIP "192.168.0.1" \
  "fake source IP"
script_setopt "--fake-dst-ip" "" LOOPFAKEDSTIP "192.168.1.1" \
  "fake destination IP"
script_setopt "--disable|-d" "" LOOPDISABLE "false" \
  "disable network loop"

script_checkopts $*

message_start "configuring network loop between $LOOPSRCIF and $LOOPDSTIF"

script_checkroot

message_start "flushing all IP filter tables"
execute "iptables --flush"
execute "iptables --table nat --flush"
execute "iptables --delete-chain"
execute "iptables --table nat --delete-chain"
message_end

LOOPSRCMAC=`ifconfig $LOOPSRCIF | \
  grep "^.*HWaddr [0-9a-f:]\+ .*$" | \
  sed "s/^.*HWaddr \([0-9a-f:]\+\) .*$/\1/"`
LOOPDSTMAC=`ifconfig $LOOPDSTIF | \
  grep "^.*HWaddr [0-9a-f:]\+ .*$" | \
  sed "s/^.*HWaddr \([0-9a-f:]\+\) .*$/\1/"`
LOOPSRCIP=`ip addr show $LOOPSRCIF | \
  grep "^[ ]*inet [0-9\./]* .*$" | \
  sed "s/^[ ]*inet \([0-9\.]*\)[/0-9]* .*$/\1/"`
LOOPDSTIP=`ip addr show $LOOPDSTIF | \
  grep "^[ ]*inet [0-9\./]* .*$" | \
  sed "s/^[ ]*inet \([0-9\.]*\)[/0-9]* .*$/\1/"`

if true LOOPDISABLE; then
  message_start "removing network loop between $LOOPSRCIP and $LOOPDSTIP"
  execute "ip route del unicast $LOOPFAKEDSTIP dev $LOOPSRCIF"
  execute "arp -i $LOOPSRCIF -d $LOOPFAKEDSTIP"
  execute "ip route del unicast $LOOPFAKESRCIP dev $LOOPDSTIF"
  execute "arp -i $LOOPDSTIF -d $LOOPFAKESRCIP"
  message_end
else
  message_start "adding IP forwarding and masquerading rules"
  execute "iptables --table nat --append POSTROUTING -s $LOOPSRCIP \
    -d $LOOPFAKEDSTIP -j SNAT --to-source $LOOPFAKESRCIP"
  execute "iptables --table nat --append PREROUTING -d $LOOPFAKESRCIP \
    -j DNAT --to-destination $LOOPSRCIP"
  execute "iptables --table nat --append POSTROUTING -s $LOOPDSTIP \
    -d $LOOPFAKESRCIP -j SNAT --to-source $LOOPFAKEDSTIP"
  execute "iptables --table nat --append PREROUTING -d $LOOPFAKEDSTIP \
    -j DNAT --to-destination $LOOPDSTIP"
  message_end
  message_start "adding network loop between $LOOPSRCIP and $LOOPDSTIP"
  execute "ip route add unicast $LOOPFAKEDSTIP dev $LOOPSRCIF"
  execute "arp -i $LOOPSRCIF -s $LOOPFAKEDSTIP $LOOPDSTMAC"
  execute "ip route add unicast $LOOPFAKESRCIP dev $LOOPDSTIF"
  execute "arp -i $LOOPDSTIF -s $LOOPFAKESRCIP $LOOPSRCMAC"
  message_end
fi

log_clean

message_end "success, network loop configured"
