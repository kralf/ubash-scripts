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

# Configure a Linux network gateway
# See usage for a description of the arguments

. ../ubash/global.sh

script_init "Configure Linux network gateway" \
  "INPUT-IF" GWINPUTIF "eth0" "gateway input interface" \
  "OUTPUT-IF" GWOUTPUTIF "eth1" "gateway output interface"

script_setopt "--target" "DIR" FULLBACKUPTARGET "/home/backups/full" \
  "backup target directory"

script_checkopts $*

message_start "configuring gateway at interface $GWINTERFACE"

script_checkroot

message_start "flushing all IP filter tables"
execute "iptables --flush"
execute "iptables --table nat --flush"
execute "iptables --delete-chain"
execute "iptables --table nat --delete-chain"
message_end

message_start "adding IP forwarding and masquerading rules"
execute "iptables --table nat --append POSTROUTING --out-interface \
  $GWOUTPUTIF -j MASQUERADE"
execute "iptables --append FORWARD --in-interface $GWINPUTIF -j ACCEPT"
message_end

message_start "enabling kernel packet forwarding"
execute "echo 1 > /proc/sys/net/ipv4/ip_forward"
message_end

log_clean

message_end "success, gateway configured"
