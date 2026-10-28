///|
test "parse test counters from MoonBit output" {
  assert_eq(
    read_uint_after("Total tests: 12, passed: 10, failed: 2", "Total tests:"),
    Some(12),
  )
  assert_eq(
    read_uint_after("Total tests: 12, passed: 10, failed: 2", "passed:"),
    Some(10),
  )
  assert_eq(read_uint_after("no summary", "passed:"), None)
}

///|
test "test progress rejects impossible counts" {
  assert_eq(test_progress("Total tests: 3, passed: 4, failed: 0"), None)
}

///|
test "output excerpts are bounded" {
  let text = "a".repeat(50)
  let excerpt = output_excerpt(text, 10)
  assert_true(excerpt.contains("..."))
  assert_eq(excerpt.length(), 14)
}

///|
test "temporary workspace paths are removed from feedback" {
  let process = ProcessResult::{
    exit_code: 1,
    timed_out: false,
    stdout: "",
    stderr: "error at /tmp/moongrade-123/submission/lib/main.mbt",
    duration_ms: 1,
  }
  let sanitized = sanitize_process_result(
    process, "/tmp/moongrade-123/submission",
  )
  assert_eq(sanitized.stderr, "error at <submission>/lib/main.mbt")
}
