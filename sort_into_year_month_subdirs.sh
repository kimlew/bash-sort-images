#! /usr/bin/env bash
#
# Name: sort_in_year_month_subdirs.sh
#
# Brief: Command-line Bash script that creates year & month subdirectories 
# based on photo-taken date & places in corresponding subdirectory.
# Note: Script processes only a single directory & only on .jpg files. 
#
# Author: Kim Lew

if [ $# -eq 0 ]; then
  echo "Type the directory path that needs year & month sub-directories: "
  read directory_path
else
  if [ ! "$1" ]; then
    echo "Enter the directory path as the 1st parameter." 
    exit 1
  fi
 fi

# Loop that processes entire given directory.
find "$directory_path" -maxdepth 1 -type f -name '*.jpg' |
while read a_file_name; do
  # If a_file_name contains [EXIF:DateTimeOriginal], use it.
  exif_date="$(identify -format '%[EXIF:DateTimeOriginal]' "$a_file_name")"
    # echo $exif_date
  
  # Since NO [EXIF:DateTimeOriginal], use [MODIFIED:Date].
  else if [ "$exif_date" == '' ] > /dev/null; then
    echo "modified date" #$modified_date
  
  # There is NO [EXIF:DateTimeOriginal] or [MODIFIED:Date].
  else
    echo "Error: The file, $a_file_name"
    echo "- is missing the exif or modified date metadata - so skipping this file"
    echo "Continuing with next file ..."
    echo
    continue
  fi

  ### Filesystem/OS Date Change ###
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

  touch -t "$date_for_date_change" "$a_file_name"
 
  # /Users/kimlew/Sites/bash_projects/test_mkdir-p
  # ${string:position:length}
  # 2015:09:02 07:09:03
  year=${exif_date:0:4}
  month=${exif_date:5:2}
  echo $year
  echo $month

  just_path=$(dirname "${a_file_name}")
  path_with_subdir_year_month="${just_path}/${year}/${month}"
  echo "path_with_subdir_year_month:" "$path_with_subdir_year_month"

  echo "a_file_name:" "$a_file_name"
  echo "just_path:" "$just_path"

  mkdir -p ${path_with_subdir_year_month}
 
  just_filename=$(basename "${new_file_name}")
  new_dir_and_filename=$just_path/$year/$month/$just_filename

  echo
  echo "just_filename:" "$just_filename"
  echo "new_dir_and_filename:" "$new_dir_and_filename"

  mv "$a_file_name" "$new_dir_and_filename"

done
echo
echo "Done."

exit 0
