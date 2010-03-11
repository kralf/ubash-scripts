#!/bin/bash
############################################################################
#    Copyright (C) 2007 by Ralf 'Decan' Kaestner                           #
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

# Encode x264 video
# See usage for a description of the arguments

. ubash

script_init "Two-pass encode x264 video" \
  "FILE" X264INPUTMASK "" "input file (mask)"

script_setopt "--output|-o" "FILE" X264OUTPUT "out.mkv" \
  "optional output video file"
script_setopt "--bitrate" "RATE" X264BITRATE "4000" "bitrate used for encoding"
script_setopt "--framerate" "RATE" X264FRAMERATE "" \
  "optional framerate used for encoding"
script_setopt "--size" "WIDTH:HEIGHT" X264SIZE "" \
  "optional frame size of target video"
script_setopt "--audio" "CODEC" X264AUDIO "copy" \
  "audio codec used for encoding"

script_setopt "--firstpass" "" X264FSTPASS "false" "perform first pass only"
script_setopt "--secondpass" "" X264SNDPASS "false" "perform second pass only"
script_setopt "--end" "SECONDS" X264END "" "optional end of input in seconds"

script_setopt "--mencoder" "BIN" X264MENCODER "/usr/bin/mencoder" \
  "path to the mencoder binary executable"

script_setopt "--mail" "ADDRESS" X264MAIL "" \
  "recipient to be notified on completion"

script_checkopts $*

message_start "encoding input file(s) $X264INPUTMASK"

if false X264SNDPASS; then
  message_start "first pass"

  X264CMD="$X264MENCODER -ovc x264 -nosound -o 1.$X264OUTPUT"
  X264CMD="$X264CMD -x264encopts pass=1:subq=5:8x8dct:frameref=2:bframes=3:"
  X264CMD="${X264CMD}b_pyramid:weight_b:bitrate=$X264BITRATE:qcomp=0.6 -noskip"
  [ "$FRAMERATE" != "" ] && X264CMD="$X264CMD -ofps $X264FRAMERATE"
  [ "$X264SIZE" != "" ] && X264CMD="$X264CMD -vf scale=$X264SIZE"
  [ "$X264END" != "" ] && X264CMD="$X264CMD -endpos $X264END"

  execute "$X264CMD $X264INPUTMASK"

  message_end
fi

if false X264FSTPASS; then
  message_start "second pass"

  X264CMD="$X264MENCODER -ovc x264 -oac $X264AUDIO -o 2.$X264OUTPUT"
  X264CMD="$X264CMD -x264encopts pass=2:subq=5:8x8dct:frameref=2:bframes=3:"
  X264CMD="${X264CMD}b_pyramid:weight_b:bitrate=$X264BITRATE:qcomp=0.6 -noskip"
  [ "$FRAMERATE" != "" ] && X264CMD="$X264CMD -ofps $X264FRAMERATE"
  [ "$X264SIZE" != "" ] && X264CMD="$X264CMD -vf scale=$X264SIZE"
  [ "$X264END" != "" ] && X264CMD="$X264CMD -endpos $X264END"

  execute "$X264CMD $X264INPUTMASK"

  message_end

  execute "mv 2.$X264OUTPUT $X264OUTPUT"
else
  execute "mv 1.$X264OUTPUT $X264OUTPUT"
fi

[ "$X264MAIL" != "" ] && mail_send $X264MAIL "$X264INPUTMASK encoding complete"

log_clean

message_end "success, output video $X264OUTPUT has been encoded"
