# Bash script to sort image files

- to help organize photo files
- creates & sorts image files into year & month subdirectories
- also creates day subdirectories, if answer at prompt is Y for Yes
- sorts by photo-taken date or if missing, modified date - since creation date is sometimes assigned file download date, which is incorrect

Name: `sort_images.sh`

Gives user prompts, e.g.,
- directory path: `/Users/kimlew/Sites/bash_projects/bash-sort-images`
- whether you want day subdirectory also: `n`

Or lets user enter 2 command-line arguments, e.g.,

`./sort_images.sh '/Users/kimlew/Sites/bash_projects/bash-sort-images' 'Y'`

**Note**: If ANY command-line arguments have spaces, you MUST put in single-quotes!
