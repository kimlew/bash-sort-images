#! /usr/bin/env bash

#----------------------------------------------------------------------
# NAME: sort_images.sh
#
# BRIEF: Command-line Bash script with prompts to help sort photo files.
# - creates & sorts image files into year & month subdirectories
# - also creates day subdirectories, if answer at prompt is `Y` for Yes
# - sorts by photo-taken date or if missing, by modify date - since sometimes
# creation date is assigned as file download date, which is incorrect.
#
# AUTHOR: Kim Lew
#----------------------------------------------------------------------

if [ $# -eq 0 ]; then
  echo "Type the directory path that needs Year & Month subdirectories."
  echo "Leave off trailing / at end of path: "
  read -r directory_path
  echo "Do you also want a Day subdirectory? (Y for Yes, N for No):"
  read -r day_subdir_also
else
  if [ ! "$1" ]; then
    echo "Enter the directory path - as the 1st parameter."
    echo "Enter Y for Yes or N for No - for Day subdirectory as 2nd parameter."
    exit 1
  fi
fi

if [[ $# -eq 1 || $# -eq 2 ]]; then
  directory_path="$1"
  safe_day_subdir_also='n'

  if [ $# -eq 2 ]; then
    day_subdir_also="$2"

    case "${day_subdir_also}" in
      [yY] | [yY][eE][sS]) # To create year-month-day subdirectories.
        safe_day_subdir_also='y'
    ;;
      [nN] | [nN][oO] | '') # To create ONLY year-month subdirectories.
        safe_day_subdir_also='n'
    ;;
       *)
    echo "Invalid input. Enter Y or N. There is a problem with the 2nd parameter \
    given or the answer to the 2nd prompt."
    exit 1
    ;;
    esac
  fi
elif [ $# -gt 2 ]; then 
  # Case of 3 or more parameters given.
  echo "Give 1 or 2 command-line arguments. Or give 0 arguments & get prompts."
  exit 1
fi

if [ ! -d "${directory_path}" ]; then
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

file_sort_counter=0

# Loop that processes entire given directory.
while read -r a_file_name; do
  # For each  a_file_name, check for [EXIF:DateTimeOriginal] in photo file's
  # metadata. If exists, use it. If not, use [DATE:modify]. If neither exists,
  # give error.
  # Note: Most files have [EXIF:DateTimeOriginal], but iPhone screenshots do
  # NOT, so use [DATE:modify] for those.
  echo "Looking at file:" "${a_file_name}"
  exif_date="$(identify -format '%[EXIF:DateTimeOriginal]' "$a_file_name" 2> /dev/null)" 
  modify_date="$(identify -format '%[DATE:modify]' "$a_file_name" 2> /dev/null)"
  echo "EXIF date is: " "${exif_date}"
  echo "MODIFY date is: " "{$modify_date}"

  #----------------------------------------------------------------------
  # Change Filesystem/OS Date
  #----------------------------------------------------------------------
  # -z checks if variable is null. -z test is explicitly for if length of string
  # is zero - so  under -z, a string containing only spaces is false - since it
  # has a non-zero length.

  if [[ -z "${exif_date}" ]] && [[ -z "${modify_date}" ]]; then
      # Give error if NO [EXIF:DateTimeOriginal] or [DATE:Modify].
    echo "Error: The file, " "${a_file_name}"
    echo "- is missing exif date or modify date metadata - so skipping this file"
    echo "Continuing with next file ..."
    continue # To stop with current iteration & move on to next item.
  elif [ "${exif_date}" ]; then
    # Change filesystem date to EXIF photo-taken date, EXIF:DateTimeOriginal.
    # Given Format:  2018:04:03 21:31:41
    # Wanted Syntax: [[CC]YY]MMDDhhmm[.SS] Wanted Format: 2015-09-02_07-09_0060.jpg
    # 1. Replace ALL occurrences of : 	With: nothing
    # 2. Replace 1st occurrence of space 	With: nothing
    # 3. Build string by deleting last 2 char at end, concatting . & then
    # concatting those last 2 char, e.g., abc.12 = abc + . + 12

    date_for_date_change="${exif_date//:/}"
    date_for_date_change="${date_for_date_change// /}"
    # Trim last 2 chars to remove SS so in format: [[CC]YY]MMDDhhmm[.SS]
    date_for_date_change="${date_for_date_change%??}.${date_for_date_change: -2}"
  else # if [ "${modify_date}" ]; then
    # Change filesystem date to modify_date, date:modify for date change.
    # Given Format:  2018-10-09T18:42:41+00:00
    # Wanted Syntax: [[CC]YY]MMDDhhmm[.SS] Wanted Format: 202002031806
    # 1. Trim last 9 chars.
    # 2. Remove all -.
    # 3. Remove all T.
    # 4. Remove all :.
    date_for_date_change="${modify_date::-9}"
    date_for_date_change="${date_for_date_change//-/}"
    date_for_date_change="${date_for_date_change//T/}"
    date_for_date_change="${date_for_date_change//:/}"
  fi
  touch -t "${date_for_date_change}" "${a_file_name}"

  #----------------------------------------------------------------------
  # Make Subdirectories
  #----------------------------------------------------------------------
  # $date_for_date_change is: 202002031806
  # ${string:position:length}
  year="${date_for_date_change:0:4}"
  month="${date_for_date_change:4:2}"
  
  just_path=$(dirname "${a_file_name}")
  just_filename=$(basename "${a_file_name}") # For path to move files into subdirectories

  if [ "${safe_day_subdir_also}" == 'y' ]; then # Make year-month-day subdirectories.
    day="${date_for_date_change:6:2}"
    path_with_subdir_year_month_day="${just_path}/${year}/${month}/${day}"
    mkdir -p "${path_with_subdir_year_month_day}"
    new_dir_and_filename="${just_path}/${year}/${month}/${day}/${just_filename}"
  else # [ "${safe_day_subdir_also}" == 'n' ]; then # Make year-month subdirectories.
    path_with_subdir_year_month="${just_path}/${year}/${month}"
    mkdir -p "${path_with_subdir_year_month}"
    new_dir_and_filename="${just_path}/${year}/${month}/${just_filename}"
  fi

  mv "${a_file_name}" "${new_dir_and_filename}"
  file_sort_counter="$((file_sort_counter+1))"
done < <(find "${directory_path%/}" -maxdepth 1 -type f -name '*.jpg' -o -name '*.JPG' \
    -o -name '*.gif' -o -name '*.GIF' -o -name '*.tif' -o -name '*.TIF' \
    -o -name '*.png' -o -name '*.PNG')
   # Note: Redirects find back into while loop with process substitution so
   # ${file_sort_counter} is accessible vs. in a | subshell process.

echo "Done. Number of files sorted is: " "${file_sort_counter}"

if [ "${file_sort_counter}" -eq 0 ]; then
  echo "There are no image files at the top-level of the path you typed."
fi

exit 0
