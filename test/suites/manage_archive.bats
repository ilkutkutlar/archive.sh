#!/usr/bin/env bats

load test_helper

function setup() {
  define_paths
  source "${PROJECT_ROOT}/lib/manage_archive.sh"
  
  remove_old_test_archive
  remove_old_test_files
  create_test_files
}

# $1: expected contents
function assert_test_archive_contents() {
  local expected_contents="$1"
  [ "$( test_archive_contents )" = "${expected_contents}" ]
}

@test "archiving files" {
  run add_to_archive "${TEST_FILE}" 0 "${TEST_ARCHIVE_TAR}"
  [ "${output}" = "${TEST_FILE} added to archive" ]

  run add_to_archive "${TEST_DIR}" 0 "${TEST_ARCHIVE_TAR}"
  [ "${output}" = "${TEST_DIR} added to archive" ]

  [ -f "${TEST_FILE}" ]
  [ -d "${TEST_DIR}" ]

  local expected_contents="test.txt
test_dir/
test_dir/test1.txt"
  assert_test_archive_contents "${expected_contents}"
}

@test "archiving files in a different directory to archive" {
  different_test_file="${BATS_TMPDIR}/different_dir/test_file.txt"

  rm -rf "${BATS_TMPDIR}/different_dir"
  mkdir "${BATS_TMPDIR}/different_dir"
  touch "${different_test_file}"

  run add_to_archive "${different_test_file}" 0 "${TEST_ARCHIVE_TAR}"
  echo "${output}"
  [ "${output}" = "${different_test_file} added to archive" ]

  [ -f "${different_test_file}" ]

  local expected_contents="test_file.txt"
  assert_test_archive_contents "${expected_contents}"
}

@test "archiving files followed by removing" {
  run add_to_archive "${TEST_FILE}" 1 "${TEST_ARCHIVE_TAR}"
  [ "${output}" = "${TEST_FILE} added to archive" ]

  run add_to_archive "${TEST_DIR}" 1 "${TEST_ARCHIVE_TAR}"
  [ "${output}" = "${TEST_DIR} added to archive" ]
  
  [ ! -f "${TEST_FILE}" ]
  [ ! -d "${TEST_DIR}" ]

  local expected_contents="test.txt
test_dir/
test_dir/test1.txt"
  assert_test_archive_contents "${expected_contents}"
}

@test "error during archiving files" {
  # Remove all permissions to create error
  chmod 000 "${TEST_FILE}"

  run add_to_archive "${TEST_FILE}" 0 "${TEST_ARCHIVE_TAR}"
  [ "${lines[0]}" = "tar: test.txt: Cannot open: Permission denied" ]

  [ -f "${TEST_FILE}" ]
  [ -d "${TEST_DIR}" ]

  [ -z "$( test_archive_contents )" ]
}

@test "unarchiving files from archive" {
  # dummy archive contains: test.txt, test_dir/, test_dir/test1.txt
  cp "${DUMMY_ARCHIVE}" "${TEST_ARCHIVE_TAR}"

  run unarchive "test_dir" 0 "${TEST_ARCHIVE_TAR}"
  [ "${output}" = "Retrieved test_dir from archive" ]

  [ -d "$( dirname "${TEST_ARCHIVE_TAR}" )/test_dir" ]
  [ -f "$( dirname "${TEST_ARCHIVE_TAR}" )/test_dir/test1.txt" ]

  local expected_contents="test.txt
test_dir/
test_dir/test1.txt"
  assert_test_archive_contents "${expected_contents}"
}


@test "unarchiving files followed by removing from archive" {
  # dummy archive contains: test.txt, test_dir/, test_dir/test1.txt
  cp "${DUMMY_ARCHIVE}" "${TEST_ARCHIVE_TAR}"

  run unarchive "test_dir" 1 "${TEST_ARCHIVE_TAR}"
  local expected_output="Retrieved test_dir from archive
Deleted test_dir from archive permanently"

  [ "${output}" = "${expected_output}" ]
  [ -f "${BATS_TMPDIR}/test_dir/test1.txt" ]
  [ -d "${TEST_DIR}" ]

  local expected_contents="test.txt"
  assert_test_archive_contents "${expected_contents}"
}
