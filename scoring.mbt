///|
fn read_uint_after(text : StringView, marker : StringView) -> Int32? {
  let start = match text.find(marker) {
    Some(index) => index
    None => return None
  }
  let mut index = start + marker.length()
  while index < text.length() {
    let ch = text.get_char(index).unwrap()
    if ch >= '0' && ch <= '9' {
      break
    }
    index += 1
  }
  let mut value = 0
  let mut found = false
  while index < text.length() {
    let ch = text.get_char(index).unwrap()
    if ch >= '0' && ch <= '9' {
      value = value * 10 + (ch.to_int() - '0'.to_int())
      found = true
      index += 1
    } else {
      break
    }
  }
  if found {
    Some(value)
  } else {
    None
  }
}

///|
fn combined_output(process : ProcessResult) -> String {
  if process.stderr.is_empty() {
    process.stdout
  } else if process.stdout.is_empty() {
    process.stderr
  } else {
    "\{process.stdout}\n\{process.stderr}"
  }
}

///|
pub fn sanitize_process_result(
  process : ProcessResult,
  workspace : StringView,
) -> ProcessResult {
  ProcessResult::{
    exit_code: process.exit_code,
    timed_out: process.timed_out,
    stdout: process.stdout.replace_all(old=workspace, new="<submission>"),
    stderr: process.stderr.replace_all(old=workspace, new="<submission>"),
    duration_ms: process.duration_ms,
  }
}

///|
fn output_excerpt(text : StringView, limit : Int32) -> String {
  let clean = text.trim()
  if clean.length() <= limit {
    clean.to_owned()
  } else {
    "\{clean[:limit].to_owned()}\n..."
  }
}

///|
fn diagnostic_hints(
  check : CheckSpec,
  process : ProcessResult,
  output : StringView,
) -> Array[String] {
  let hints = []
  if process.timed_out {
    hints.push(
      "检查超时：减少循环次数或死循环，并确认测试能够在时限内完成。",
    )
  } else if process.exit_code != 0 {
    if output.contains("[4014]") || output.contains("[4015]") {
      hints.push(
        "类型不匹配：对照函数签名检查表达式、返回值和参数类型。",
      )
    }
    if output.contains("[3002]") || output.contains("[3003]") {
      hints.push(
        "语法错误：检查括号、关键字、逗号和缺失的表达式。",
      )
    }
    if output.contains("[4021]") {
      hints.push(
        "未定义标识符：检查拼写、导入语句和名称可见性。",
      )
    }
    if output.contains("Total tests:") && output.contains("failed:") {
      hints.push(
        "测试未全部通过：从第一个失败用例开始修复，不要只看最终汇总。",
      )
    }
    if hints.is_empty() && !check.hint.is_empty() {
      hints.push(check.hint)
    }
    if hints.is_empty() {
      hints.push(
        "检查未通过：请查看下方输出摘要并重新运行。",
      )
    }
  }
  hints
}

///|
fn test_progress(output : StringView) -> (Int32, Int32)? {
  let total = read_uint_after(output, "Total tests:")
  let passed = read_uint_after(output, "passed:")
  match (total, passed) {
    (Some(total), Some(passed)) if total > 0 && passed <= total =>
      Some((passed, total))
    _ => None
  }
}

///|
pub fn score_check(check : CheckSpec, process : ProcessResult) -> CheckResult {
  let output = combined_output(process)
  let (earned_points, passed) = if process.timed_out {
    (0, false)
  } else if same_kind(check.kind, Test) {
    match test_progress(output) {
      Some((passed_tests, total_tests)) =>
        (
          check.points * passed_tests / total_tests,
          process.exit_code == 0 && passed_tests == total_tests,
        )
      None =>
        if process.exit_code == 0 {
          (check.points, true)
        } else {
          (0, false)
        }
    }
  } else if process.exit_code == 0 {
    (check.points, true)
  } else {
    (0, false)
  }
  CheckResult::{
    id: check.id,
    title: check.title,
    passed,
    earned_points,
    possible_points: check.points,
    exit_code: process.exit_code,
    timed_out: process.timed_out,
    duration_ms: process.duration_ms,
    feedback: diagnostic_hints(check, process, output),
    output_excerpt: output_excerpt(output, 1200),
  }
}

///|
pub fn build_report(
  assignment : Assignment,
  student_path : StringView,
  results : Array[CheckResult],
) -> GradeReport {
  let mut score = 0
  let mut required_failed = false
  let result_map : Map[String, CheckResult] = Map([])
  for result in results {
    score += result.earned_points
    result_map.set(result.id, result)
  }
  for check in assignment.checks {
    if check.required {
      match result_map.get(check.id) {
        Some(result) if !result.passed => required_failed = true
        None => required_failed = true
        _ => ()
      }
    }
  }
  GradeReport::{
    assignment_name: assignment.name,
    student_path: student_path.to_owned(),
    score,
    max_score: assignment.max_score,
    passed: !required_failed && score >= assignment.pass_score,
    checks: results,
  }
}
