# Add file to given archive.
#
# $1: file path to archive
# $2: remove file after adding to archive, 1 or 0
# $3: optional: add file to custom archive, defaults to ./$ARCHIVE_TAR
add_to_archive() {
  file_path="$1"
  file_name="$( basename "$1" )"
  file_dir="$( dirname "$1" )"

  remove_files="$2"
  archive=${3-"./${ARCHIVE_TAR}"}
  
  if [ ! -e "${file_path}" ]; then
    echo "No such file: ${file_path}"
    return 1
  fi

  if [ "${remove_files}" -eq 1 ]; then
    tar -C "${file_dir}" -r "${file_name}" -f "${archive}" --remove-files
  else
    tar -C "${file_dir}" -r "${file_name}" -f "${archive}"
  fi

  # set -e is set, script exits if 
  # tar failed, no need to check for 
  # failing exit codes.
  if [ "$?" -eq 0 ]; then
    echo "${file_path} added to archive"
  else
    echo "Adding to archive failed"
  fi
}

# Unarchives file from given archive file. 
# File is extracted into the same directory 
# as the archive file.
#
# $1: file to unarchive
# $2: remove from archive after unarchiving, 1 or 0
# $3: optional: unarchive file from this archive,
#     defaults to ./$ARCHIVE_TAR
unarchive() {
  file_path="$1"
  remove_files="$2"
  archive=${3-"./${ARCHIVE_TAR}"}
  archive_dir="$( dirname "${archive}" )"

  tar -C "${archive_dir}" -x -f "${archive}" "${file_path}"

  if [ "$?" -eq 0 ] && [ -e "${archive_dir}/${file_path}" ]; then
    echo "Retrieved ${file_path} from archive" 
  else
    echo "Retrieving from archive failed"
    exit 1
  fi

  if [ "${remove_files}" -eq 1 ]; then
    destroy_archived_file "${file_path}" "${archive}"
  fi
}


# ===================
#  Private functions
# ===================


# $1: file to delete from archive
# $2: optional: delete file from this archive, 
#     defaults to ./$ARCHIVE_TAR
destroy_archived_file() {
  file_name="$1"
  archive=${2-"./${ARCHIVE_TAR}"}
  archive_dir="$( dirname "${archive}" )"
  
  tar -C "${archive_dir}" -f "${archive}" --delete "${file_name}"

  if [ "$?" -eq 0 ]; then
    echo "Deleted ${file_name} from archive permanently"
  else
    echo "Deleting from archive failed"
  fi
}
