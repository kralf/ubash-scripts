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

# Check the content of ISO images
# See usage for a description of the arguments

. ubash

script_init_array "Check the content of ISO images" \
  "IMAGE" ISO_CHECK_IMAGES "*.iso" "images to be checked"

script_setopt "--mount-point" "DIR" ISO_CHECK_MP "/mnt/iso" \
  "temporary image mount point"
script_setopt "--charset" "CHARSET" ISO_CHECK_CHARSET "iso8859-1" \
  "character set for name conversion"

script_setopt "--null-dev" "DEV" ISO_CHECK_NULL "/dev/null" \
  "null device to stream content to"

script_checkopts $*

message_start "checking images"

script_checkroot

for (( I=0; I < ${#ISO_CHECK_IMAGES[*]}; I++ )); do
  if [ -r "${ISO_CHECK_IMAGES[$I]}" ]; then
    message_start "checking image ${ISO_CHECK_IMAGES[$I]}"

    ISO_CHECK_CMD="mount -o loop,iocharset=$ISO_CHECK_CHARSET"
    ISO_CHECK_CMD="$ISO_CHECK_CMD \"${ISO_CHECK_IMAGES[$I]}\""
    execute "$ISO_CHECK_CMD \"$ISO_CHECK_MP\""
    ISO_CHECK_CMD="find \"$ISO_CHECK_MP\" -type f -print0"
    ISO_CHECK_CMD="$ISO_CHECK_CMD | xargs -0 -I F dd if=F of=$ISO_CHECK_NULL"
    execute "$ISO_CHECK_CMD"
    execute "umount \"$ISO_CHECK_MP\""

    message_end
  fi
done

log_clean

message_end "success, images checked"
