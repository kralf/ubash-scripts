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

. ubash

script_init_array "Export SMS from iPhone SQLite database" \
  "ADDRESS" SMS_EXPORT_ADDRESSES "" "addresses selected for export"

script_setopt "--database" "FILE" SMS_EXPORT_DB "sms.db" \
  "iPhone SMS database filename"
script_setopt "--table" "TABLE" SMS_EXPORT_TABLE "message" \
  "iPhone SMS table name"
script_setopt "--date" "DATE" SMS_EXPORT_DATE "`date +%Y-%m-%d`" \
  "date of the export"

script_setopt "--address-book" "FILE" SMS_EXPORT_AB "address.book" \
  "address book filename"

script_setopt "--list|-l" "" SMS_EXPORT_LIST "false" \
  "list database content"

script_checkopts $*

message_start "exporting messages from $SMS_EXPORT_DB"

if [ -z "$SMS_EXPORT_ADDRESSES" ]; then
  SMS_EXPORT_QUERY="SELECT DISTINCT address FROM $SMS_EXPORT_TABLE"
  SMS_EXPORT_ADDRESSES=(`sqlite3 $SMS_EXPORT_DB "$SMS_EXPORT_QUERY"`)
fi

for (( A=0; A < ${#SMS_EXPORT_ADDRESSES[*]}; A++ )); do
  if [ -r "$SMS_EXPORT_AB" ]; then
    SMS_EXPORT_NAME="`grep ${SMS_EXPORT_ADDRESSES[$A]} $SMS_EXPORT_AB | \
      sed s/'\([^=]\+\)=.*'/'\1'/`"
  fi
  [ -z "$SMS_EXPORT_NAME" ] && \
    SMS_EXPORT_NAME="`echo ${SMS_EXPORT_ADDRESSES[$A]} | utf8tolatin1`"
  SMS_EXPORT_NAMES[${#SMS_EXPORT_NAMES[*]}]="$SMS_EXPORT_NAME"
done

if true SMS_EXPORT_LIST; then
  message_start "listing database content"

  for (( A=0; A < ${#SMS_EXPORT_ADDRESSES[*]}; A++ )); do
    SMS_EXPORT_QUERY="SELECT COUNT(text) FROM $SMS_EXPORT_TABLE WHERE"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY address = '${SMS_EXPORT_ADDRESSES[$A]}'"
    SMS_EXPORT_COUNTS[$A]=`sqlite3 $SMS_EXPORT_DB "$SMS_EXPORT_QUERY"`
  done

  for (( A=0; A < ${#SMS_EXPORT_ADDRESSES[*]}; A++ )); do
    message "${SMS_EXPORT_COUNTS[$A]} messages from ${SMS_EXPORT_NAMES[$A]}"
  done

  message_end "done, database content listed"
else
  for (( A=0; A < ${#SMS_EXPORT_ADDRESSES[*]}; A++ )); do
    message_start "exporting messages from ${SMS_EXPORT_NAMES[$A]}"
  
    SMS_EXPORT_FILE="${SMS_EXPORT_NAMES[$A]} $SMS_EXPORT_DATE.txt"

    SMS_EXPORT_QUERY="SELECT strftime('%Y-%m-%d at %H:%M:%S', date,"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY 'unixepoch', 'localtime')"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY FROM $SMS_EXPORT_TABLE WHERE"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY address = '${SMS_EXPORT_ADDRESSES[$A]}'"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY ORDER BY date"
    execute_stdout SMS_EXPORT_TIMES \
      "sqlite3 $SMS_EXPORT_DB \"$SMS_EXPORT_QUERY\" | utf8tolatin1"

    SMS_EXPORT_QUERY="SELECT flags FROM $SMS_EXPORT_TABLE WHERE"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY address = '${SMS_EXPORT_ADDRESSES[$A]}'"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY ORDER BY date"
    execute_stdout SMS_EXPORT_FLAGS \
      "sqlite3 $SMS_EXPORT_DB \"$SMS_EXPORT_QUERY\" | utf8tolatin1"

    SMS_EXPORT_QUERY="SELECT text FROM $SMS_EXPORT_TABLE WHERE"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY address = '${SMS_EXPORT_ADDRESSES[$A]}'"
    SMS_EXPORT_QUERY="$SMS_EXPORT_QUERY ORDER BY date"
    execute_stdout SMS_EXPORT_TEXTS \
      "sqlite3 -csv $SMS_EXPORT_DB \"$SMS_EXPORT_QUERY\" | utf8tolatin1"

    echo "SMS conversations with ${SMS_EXPORT_NAMES[$A]}" > \
      "$SMS_EXPORT_FILE"
    echo "-----" >> "$SMS_EXPORT_FILE"

    T=0
    for (( M=0; M < ${#SMS_EXPORT_TIMES[*]}; M++ )); do
      [ "$M" -gt 0 ] && echo >> "$SMS_EXPORT_FILE"
      for (( ; T < ${#SMS_EXPORT_TEXTS[*]}; T++ )); do
        echo "${SMS_EXPORT_TEXTS[$T]}" >> "$SMS_EXPORT_FILE"
        [[ "${SMS_EXPORT_TEXTS[$T]}" =~ \"$ ]] && math_inc T && break
      done
      [ "${SMS_EXPORT_FLAGS[$M]}" == 3 ] && \
        echo -n "Sent to " >> "$SMS_EXPORT_FILE"
      [ "${SMS_EXPORT_FLAGS[$M]}" == 2 ] && \
        echo -n "Received from " >> "$SMS_EXPORT_FILE"
      echo "${SMS_EXPORT_ADDRESSES[$A]} on ${SMS_EXPORT_TIMES[$M]}" >> \
        "$SMS_EXPORT_FILE"
    done

    echo "-----" >> "$SMS_EXPORT_FILE"
    echo "Total of ${#SMS_EXPORT_TIMES[*]} message(s)." >> "$SMS_EXPORT_FILE"
  
    message_end "done, messages exported to $SMS_EXPORT_FILE"
  done
fi

log_clean

message_end "success, messages exported"
