#! /usr/bin/env bash

#----------------------------------------------------------------------
# NAME: sort_images.sh
#
# BRIEF: Command-line Bash script with prompts to help sort photo files.
# - creates & sorts `.jpg` files into year & month subdirectories
# - also creates day subdirectories, if answer at prompt is `Y` for Yes
# - sorts by photo-taken date or if missing, by modify date - since sometimes
# creation date is assigned as file download date, which is incorrect.
#
# AUTHOR: Kim Lew
#----------------------------------------------------------------------

if [ $# -eq 0 ]; then
  echo "Type the absolute directory path that needs year & month subdirectories."
  echo "Leave off trailing / at end of path: "
  read -r directory_path
  echo "Do you also want a day subdirectory? (Y for Yes, N for No):"
  read -r day_subdir_also
else
  if [ ! "$1" ]; then
    echo "Enter the directory path - as the 1st parameter."
    echo "Enter Y for Yes or N for No - for day subdirectory as 2nd parameter."
    exit 1
  fi
fi

if [[ $# -eq 1 || $# -eq 2 ]]; then
  directory_path="$1"
  day_subdir_also="$2"
fi

if [ ! -d "$directory_path" ]; then
    echo "This directory does NOT exist."
    exit 1
fi

if ! magick identify --version > /dev/null; then
  echo "Error: You are missing the identify program that is part of the"
  echo "ImageMagick software suite. Install ImageMagick with your package manager."
  echo "Or see: https://imagemagick.org/index.php/"
  echo "Then re-run this script."
  exit 1
fi
echo "Sorting & filename changes in progress..."
echo "..."

file_sort_counter=0

# Loop that processes entire given directory.
while read -r a_file_name; do
  # For each  a_file_name, check for [EXIF:DateTimeOriginal] in photo file's
  # metadata. If exists, use it. If not, use [DATE:modify]. If neither exists,
  # give error.
  # Note: Most files have [EXIF:DateTimeOriginal], but iPhone screenshots do
  # NOT, so use [DATE:modify] for those.
  exif_date="$(identify -format '%[EXIF:DateTimeOriginal]' "$a_file_name")"
  modify_date="$(identify -format '%[DATE:modify]' "$a_file_name")"
  echo "EXIF date is: " "$exif_date"
  echo "MODIFY date is: " "$modify_date"

  #----------------------------------------------------------------------
  # Change Filesystem/OS Date
  #----------------------------------------------------------------------
  # -z checks if variable is null. -z test is explicitly for if length of string
  # is zero - so  under -z, a string containing only spaces is false - since it
  # has a non-zero length.

  if [[ -z "$exif_date" ]] && [[ -z "$modify_date" ]]; then
      # Give error if NO [EXIF:DateTimeOriginal] or [DATE:Modify].
    echo "Error: The file, $a_file_name"
    echo "- is missing exif date or modify date metadata - so skipping this file"
    echo "Continuing with next file ..."

  elif [ "$exif_date" ]; then
    # Change filesystem date to EXIF photo-taken date, EXIF:DateTimeOriginal.
    # Given Format:  2018:04:03 21:31:41
    # Wanted Syntax: [[CC]YY]MMDDhhmm[.SS] Wanted Format: 2015-09-02_07-09_0060.jpg
    # 1. Replace ALL occurrences of : 	With: nothing
    # 2. Replace 1st occurrence of space 	With: nothing
    # 3. Build string by deleting last 2 char at end, concatting . & then
    # concatting those last 2 char, e.g., abc.12 = abc + . + 12

    date_for_date_change="${exif_date//:/}"
    date_for_date_change="${date_for_date_change// /}"

    # Use format: ${parameter%word} for the portion with the string to keep.
    # % - means to delete only the following stated chars & keep the rest,
    # i.e., %${date_for_date_change: -2} delete 12 part of abc12 & keep abc

    # Trim last 2 chars to remove SS so in format: [[CC]YY]MMDDhhmm[.SS]
    date_for_date_change="${date_for_date_change%??}.${date_for_date_change: -2}"
    echo "Changed EXIF date: " "$date_for_date_change"

  else # if [ "$modify_date" ]; then
    # Change filesystem date to modify_date, date:modify for date change.
    # Given Format:  2018-10-09T18:42:41+00:00
    # Wanted Syntax: [[CC]YY]MMDDhhmm[.SS] Wanted Format: 202002031806
    # 1. Trim last 9 chars.
    # 2. Remove all -.
    # 3. Remove all T.
    # 4. Remove all :.
    date_for_date_change=${modify_date::-9}
    date_for_date_change="${date_for_date_change//-/}"
    date_for_date_change="${date_for_date_change//T/}"
    date_for_date_change="${date_for_date_change//:/}"
    echo "Changed modify_date is: " "$date_for_date_change" # 201801092251
  fi
  touch -t "$date_for_date_change" "$a_file_name"

  #----------------------------------------------------------------------
  # Make Subdirectories
  #----------------------------------------------------------------------
  # $date_for_date_change is: 202002031806
  # ${string:position:length}
  year="${date_for_date_change:0:4}"
  month="${date_for_date_change:4:2}"
  echo "Year is: " "$year"
  echo "Month is: " "$month"

  just_path=$(dirname "${a_file_name}")
  echo "a_file_name:" "$a_file_name"
  echo "just_path:" "$just_path"

  # For path to move files into subdirectories
  just_filename=$(basename "${a_file_name}")
  echo "just_filename:" "$just_filename"

  if [ "$day_subdir_also" ]; then # Check in case empty command line argument.
    case $day_subdir_also in
       [yY] | [yY][eE][sS])
    day="${date_for_date_change:6:2}"
    echo "Day is: " "$day"

    path_with_subdir_year_month_day="${just_path}/${year}/${month}/${day}"
    echo "Path with year_month_day:" "$path_with_subdir_year_month_day"
    mkdir -p "${path_with_subdir_year_month_day}"

    new_dir_and_filename="${just_path}/${year}/${month}/${day}/${just_filename}"
    # new_dir_and_filename="$just_path/$year/$month/$day/$just_filename"
    ;;
       [nN] | [nN][oO]) # Just year & month subdirectories.
    path_with_subdir_year_month="${just_path}/${year}/${month}"
    echo "Path with year_month:" "$path_with_subdir_year_month"
    mkdir -p "${path_with_subdir_year_month}"

    new_dir_and_filename="${just_path}/${year}/${month}/${just_filename}"
    # new_dir_and_filename="$just_path/$year/$month/$just_filename"
    ;;
       *)
    echo "Invalid input..."
    exit 1
    ;;
    esac 
  fi

  echo "new_dir_and_filename:" "$new_dir_and_filename"
  mv "$a_file_name" "$new_dir_and_filename"
  file_sort_counter="$((file_sort_counter+1))"
  # count=`expr $count + 1`
done < <(find "$directory_path" -maxdepth 1 -type f -name '*.jpg') # process substitution
# <( creates a temporary file/named pipes

echo "Done. Number of files sorted is: " "$file_sort_counter"
exit 0
