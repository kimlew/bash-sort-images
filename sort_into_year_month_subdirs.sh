#! /usr/bin/env bash

#----------------------------------------------------------------------
# NAME: sort_in_year_month_subdirs.sh
#
# BRIEF: Command-line Bash script that creates year & month subdirectories 
# based on photo-taken date & places in corresponding subdirectory.
# Note: Script processes only a single directory & only on .jpg files. 
#
# AUTHOR: Kim Lew
#----------------------------------------------------------------------

if [ $# -eq 0 ]; then
  echo "Type the absolute directory path that needs year & month sub-directories."
  echo "Leave off trailing / at end of path: "
  read directory_path
else
  if [ ! "$1" ]; then
    echo "Enter the directory path as the 1st parameter." 
    exit 1
  fi
 fi

if [ ! -d "$directory_path" ] 
then
    echo "This directory does NOT exist." 
    exit 1
fi

if ! which identify > /dev/null; then
  echo "Error: You are missing the identify program that is part of the"
  echo "ImageMagick software suite. Install ImageMagick with your package manager."
  echo "Or see: https://imagemagick.org/index.php/"
  echo "Then re-run this script."
  exit 1
fi
echo "Sorting & filename changes in progress..."
echo "..."

# Loop that processes entire given directory.
find "$directory_path" -maxdepth 1 -type f -name '*.jpg' |
while read a_file_name; do
  # Check if a_file_name has [EXIF:DateTimeOriginal] or  [DATE:modify] in
  # photo file's metadata. Most will have [EXIF:DateTimeOriginal], but iPhone 
  # screenshots do not, so use [DATE:modify] for those.
  
  exif_date="$(identify -format '%[EXIF:DateTimeOriginal]' "$a_file_name")"
  echo "EXIF date is: "$exif_date
  if [ ! $exif_date ]; then
    modify_date="$(identify -format '%[DATE:modify]' "$a_file_name")"
    echo "Modify date is: " $modify_date
  fi
  
  # Give error if NO [EXIF:DateTimeOriginal] or [DATE:Modify].
  if [ ! $exif_date ] && [ ! $modify_date ]; then
    echo "Error: The file, $a_file_name"
    echo "- is missing metadata for exif date or modify date - so skipping this file"
    echo "Continuing with next file ..."
    echo
    continue
  fi

  #----------------------------------------------------------------------
  # Filesystem/OS Date Change
  #----------------------------------------------------------------------
  if [ $exif_date ]; then
    # Wanted Format: 2015-09-02_07-09_0060.jpg
    # Given Format:  2018:04:03 21:31:41
    # Change filesystem date to EXIF photo-taken date, EXIF:DateTimeOriginal.
    # 1. Replace ALL occurrences of : 	With: nothing
    # 2. Replace 1st occurrence of space 	With: nothing
    # 3. Build string by deleting last 2 char at end. Then concat . & then concat 
    # last 2 char, e.g., abc12 -> abc + . + 12 => abc.12
    date_for_date_change="${exif_date//:/}"
    date_for_date_change="${date_for_date_change// /}"
    # Use format: ${parameter%word} for the portion with the string to keep.
    # % - means to delete only the following stated chars & keep the rest, i.e., 
    # %${date_for_date_change: -2} - which is the 12 part of abc12 & keep abc
    date_for_date_change="${date_for_date_change%??}.${date_for_date_change: -2}"
    echo "Changed EXIF date: " $date_for_date_change
  else # if [ $modify_date ]; then
    # Change filesystem date to modify_date, date:modify.
    # Wanted Format: [[CC]YY]MMDDhhmm[.SS]
    # Given Format:  2018-10-09T18:42:41+00:00
    # 1. Trim last 6 chars.
    # 2. Remove all -.
    # 3. Remove all T.
    # 4. Remove all :.

  # Modify date for date change:  
    date_for_date_change=${modify_date::-6}
    date_for_date_change="${date_for_date_change//-/}"
    date_for_date_change="${date_for_date_change//T/}"
    date_for_date_change="${date_for_date_change//:/}"
    echo "Changed modify_date is: " $date_for_date_change
  fi
  touch -t "$date_for_date_change" "$a_file_name"
 
  #----------------------------------------------------------------------
  # Make Subdirectories
  #----------------------------------------------------------------------
  # /Users/kimlew/Sites/bash_projects/test_mkdir-p
  # ${string:position:length}
  # 2015:09:02 07:09:03
  year=${exif_date:0:4}
  month=${exif_date:5:2}
  echo $year
  echo $month

  just_path=$(dirname "${a_file_name}")
  path_with_subdir_year_month="${just_path}/${year}/${month}"
  echo "a_file_name:" "$a_file_name"
  echo "just_path:" "$just_path"
  echo "path_with_subdir_year_month:" "$path_with_subdir_year_month"
  echo

  mkdir -p ${path_with_subdir_year_month}

  #----------------------------------------------------------------------
  # Move Files into Subdirectories 
  #----------------------------------------------------------------------
  just_filename=$(basename "${new_file_name}")
  new_dir_and_filename=$just_path/$year/$month/$just_filename
  echo "just_filename:" "$just_filename"
  echo "new_dir_and_filename:" "$new_dir_and_filename"

  mv "$a_file_name" "$new_dir_and_filename"
done
echo
echo "Done."

exit 0
