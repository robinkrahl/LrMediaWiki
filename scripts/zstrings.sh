#!/bin/bash
#
# Copyright (C) 2017 Eckhard Henkel <eckhard.henkel@wikipedia.de>
#
# This script searches ZStrings [1] in Lua source files and uses the search
# results to generate an English localization dictionary file.
#
# The generated file can be used as a template for further translations, e. g.
# for a French localization dictionary file "TranslatedStrings_fr.txt".
#
# The file could be used as "TranslatedStrings_en.txt", but this is not
# recommended, because it generates redundancy and might confuse developers.
#
# The English terms should still be maintained in the Lua files.
#
# At release process, this script can be called by the script "release.sh".
#
# Requirements:
# An Unix system or an Unix-like environmemnt with default Unix commands:
# – bash
# – grep or egrep
# – sort
#
# [1] ZStrings are Adobe's solution for localization. For details see
# chapter 7, "Using ZStrings for Localization" at page 148 of
# "Lightroom SDK 6 Programmers Guide":
# http://wwwimages.adobe.com/content/dam/Adobe/en/devnet/photoshoplightroom/pdfs/lr6/lightroom-sdk-guide.pdf#page=148
#

GREP_COMMAND="egrep" # "grep" works too.

GREP_OPTION_1="--only-matching"
# Prints only the matching part of the lines, not the whole line.
# For both, productive and debugging purposes, this option is needed.
# Don't comment it out.

GREP_OPTION_2="--no-filename"
# Don't print filenames.
# This option can be commented out for debugging.
# For productive purposes, this option is needed.

# GREP_OPTION_3="--line-number"
# Each output line is preceded by its line number.
# This option can be used for debugging.
# For productive purposes, this option needs to be commented out.

GREP_OPTIONS="$GREP_OPTION_1 $GREP_OPTION_2 $GREP_OPTION_3"

GREP_SEARCH_PATTERN='"\$\$\$.*"'
# Search for ZStrings, starting with a double quote, followed by three $,
# any character up to the end, marked by a double quote.
# This works even with escaped double quotes \".
# The pattern is delimited by single quotes to avoid shell substitutions.

# According to [1], section "Localization dictionary file format", there is a
# mandatory requirement:
# "The ZStrings in this file must all be enclosed with double quotes."
# To simplify handling of ZStrings, they should be delimited with double quotes
# not only at localization dictionary files, but in Lua files too.

LUA_FILES="mediawiki.lrdevplugin/*.lua" # All Lua files
TMP_FILE="TranslatedStringsUnsorted.txt" # temporarily file, unsorted
OUTPUT_FILE="templates/TranslatedStringsTemplate.txt" # result file, sorted

# Invoke grep command:
$GREP_COMMAND $GREP_OPTIONS -e $GREP_SEARCH_PATTERN $LUA_FILES > $TMP_FILE
echo "Exit code grep: $?" # Exit code should be 0 (= error free)

# Localization dictionary files should be sorted alphabetically:
SORT_OPTION="--unique" # output only the first of an equal run
# For debugging purposes, comment this option out.
sort $SORT_OPTION $TMP_FILE > $OUTPUT_FILE

rm $TMP_FILE
