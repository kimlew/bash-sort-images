### Bash script to sort image files

- to help organize photo files
- creates & sorts `.jpg` files into year & month subdirectories
- also creates day subdirectories, if answer at prompt is Y for Yes
- sorts by photo-taken date or if missing, modified date - since creation date 
is sometimes assigned file download date, which is incorrect

Name: `sort_images.sh`

Takes in 2 arguments at command line, e.g.,
- directory path: `/Users/kimlew/Sites/bash_projects/test_rename_files`
- whether you want day subdirectory also: `Y`

**Note**: If ANY command-line arguments have spaces, you MUST put in single-quotes!
