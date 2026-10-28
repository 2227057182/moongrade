///|
let sample_assignment =
  #|{
  #|  "name": "MoonBit Fundamentals",
  #|  "description": "A short graded exercise.",
  #|  "pass_score": 70,
  #|  "checks": [
  #|    {"id": "compile", "kind": "check", "points": 30, "timeout_seconds": 60},
  #|    {"id": "tests", "kind": "test", "points": 70, "timeout_seconds": 90}
  #|  ]
  #|}

///|
test "assignment manifest exposes checks and total score" {
  let assignment = @moongrade.assignment_from_json(sample_assignment)
  assert_eq(assignment.name, "MoonBit Fundamentals")
  assert_eq(assignment.checks.length(), 2)
  assert_eq(assignment.max_score, 100)
  assert_eq(assignment.pass_score, 70)
  assert_eq(assignment.checks[0].command[0], "moon")
  assert_true(assignment.checks[0].kind is @moongrade.Compile)
}

///|
test "successful compile check receives full points" {
  let check = @moongrade.CheckSpec::{
    id: "compile",
    title: "Project compiles",
    kind: @moongrade.Compile,
    command: ["moon", "check"],
    points: 30,
    timeout_seconds: 60,
    required: true,
    hint: "Fix compilation first.",
  }
  let process = @moongrade.ProcessResult::{
    exit_code: 0,
    timed_out: false,
    stdout: "Check passed",
    stderr: "",
    duration_ms: 42,
  }
  let result = @moongrade.score_check(check, process)
  assert_true(result.passed)
  assert_eq(result.earned_points, 30)
}

///|
test "test check receives proportional points and feedback" {
  let check = @moongrade.CheckSpec::{
    id: "tests",
    title: "Public tests",
    kind: @moongrade.Test,
    command: ["moon", "test"],
    points: 70,
    timeout_seconds: 90,
    required: true,
    hint: "",
  }
  let process = @moongrade.ProcessResult::{
    exit_code: 1,
    timed_out: false,
    stdout: "Total tests: 4, passed: 3, failed: 1",
    stderr: "",
    duration_ms: 100,
  }
  let result = @moongrade.score_check(check, process)
  assert_false(result.passed)
  assert_eq(result.earned_points, 52)
  assert_true(result.feedback[0].contains("测试"))
}

///|
test "compiler diagnostics become actionable hints" {
  let check = @moongrade.CheckSpec::{
    id: "compile",
    title: "Compile",
    kind: @moongrade.Compile,
    command: ["moon", "check"],
    points: 20,
    timeout_seconds: 30,
    required: true,
    hint: "",
  }
  let process = @moongrade.ProcessResult::{
    exit_code: 2,
    timed_out: false,
    stdout: "",
    stderr: "[4014] Type mismatch",
    duration_ms: 10,
  }
  let result = @moongrade.score_check(check, process)
  assert_true(result.feedback[0].contains("类型不匹配"))
}

///|
test "custom commands are loaded from the manifest" {
  let source =
    #|{
    #|  "name": "Command exercise",
    #|  "pass_score": 10,
    #|  "checks": [
    #|    {
    #|      "id": "version",
    #|      "kind": "command",
    #|      "command": ["moon", "version"],
    #|      "points": 10,
    #|      "required": false
    #|    }
    #|  ]
    #|}
  let assignment = @moongrade.assignment_from_json(source)
  assert_eq(assignment.checks[0].command, ["moon", "version"])
  assert_false(assignment.checks[0].required)
}

///|
test "timeouts lose all points and provide a targeted hint" {
  let check = @moongrade.CheckSpec::{
    id: "tests",
    title: "Tests",
    kind: @moongrade.Test,
    command: ["moon", "test"],
    points: 50,
    timeout_seconds: 5,
    required: true,
    hint: "",
  }
  let process = @moongrade.ProcessResult::{
    exit_code: -1,
    timed_out: true,
    stdout: "",
    stderr: "",
    duration_ms: 5000,
  }
  let result = @moongrade.score_check(check, process)
  assert_eq(result.earned_points, 0)
  assert_true(result.feedback[0].contains("超时"))
}

///|
test "reports include all checks and valid JSON" {
  let assignment = @moongrade.assignment_from_json(sample_assignment)
  let report = @moongrade.GradeReport::{
    assignment_name: assignment.name,
    student_path: "submission",
    score: 82,
    max_score: assignment.max_score,
    passed: true,
    checks: [
      @moongrade.CheckResult::{
        id: "compile",
        title: "Compile",
        passed: true,
        earned_points: 30,
        possible_points: 30,
        exit_code: 0,
        timed_out: false,
        duration_ms: 20,
        feedback: [],
        output_excerpt: "ok",
      },
      @moongrade.CheckResult::{
        id: "tests",
        title: "Tests",
        passed: true,
        earned_points: 52,
        possible_points: 70,
        exit_code: 0,
        timed_out: false,
        duration_ms: 30,
        feedback: ["One optional test was skipped."],
        output_excerpt: "4 tests",
      },
    ],
  }
  let markdown = @moongrade.render_markdown(report)
  assert_true(markdown.contains("82 / 100"))
  assert_true(markdown.contains("One optional test was skipped."))
  let json = @moongrade.render_json(report)
  assert_true(@json.valid(json))
  let html = @moongrade.render_html(report)
  assert_true(html.contains("MoonGrade report"))
}
