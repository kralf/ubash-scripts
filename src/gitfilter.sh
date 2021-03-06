#!/bin/bash
############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
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

# Use git filter-branch to filter a git branch, shifting its root directory
# and prefixing its commit messages
# See usage for a description of the arguments

. ubash

GIT_FILTER_BRANCH=`git rev-parse --abbrev-ref HEAD 2> /dev/null`

script_init \
  "Filter a git branch, rewriting its root and commit messages" \
  "BRANCH" GIT_FILTER_BRANCH "$GIT_FILTER_BRANCH" \
  "name of the branch to be filtered"

script_setopt "--rename|-r" "BRANCH" GIT_FILTER_RENAME "" \
  "rename the branch before filtering"

script_checkopts $*

if [ -n "$GIT_FILTER_RENAME" ]; then
  message_start "renaming branch $GIT_FILTER_BRANCH to $GIT_FILTER_RENAME"
  git branch -m $GIT_FILTER_BRANCH $GIT_FILTER_RENAME
  GIT_FILTER_BRANCH=$GIT_FILTER_RENAME
  message_end
fi

message_start "filtering branch $GIT_FILTER_BRANCH"

GIT_FILTER_DIR=$GIT_FILTER_BRANCH \
git filter-branch --prune-empty --tree-filter '
FILES=`git ls-tree -r --name-only $GIT_COMMIT`
mkdir -p $GIT_FILTER_DIR
IFS="
"
for FILE in $FILES; do 
  mkdir -p $GIT_FILTER_DIR/`dirname "$FILE"`
  mv "$FILE" "$GIT_FILTER_DIR/$FILE"
done
IFS=" "
' -- --branches=$GIT_FILTER_BRANCH

GIT_FILTER_PREFIX="$GIT_FILTER_BRANCH: " \
git filter-branch -f --msg-filter '
  sed "s/^\(.\+\)$/$GIT_FILTER_PREFIX\\1/"
' -- --branches=$GIT_FILTER_BRANCH

log_clean

message_end "success, branch filtered"
