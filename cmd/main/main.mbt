///|
suberror CliError {
  CliError(String)
}

///|
struct CliOptions {
  assignment_path : String
  student_path : String
  markdown_path : String?
  json_path : String?
  html_path : String?
  fail_on_fail : Bool
}

///|
fn help_text() -> String {
  let text =
    #|MoonGrade - MoonBit assignment grading and feedback
    #|
    #|USAGE
    #|  moon run cmd/main -- grade --assignment <assignment.json> --student <path> [OPTIONS]
    #|  moon run cmd/main -- batch --assignment <assignment.json> --students <dir> --reports <dir>
    #|
    #|OPTIONS
    #|  --assignment <path>   Assignment manifest (default: assignment.json)
    #|  --student <path>      Trusted local MoonBit project to grade (default: .)
    #|  --markdown <path>     Write a Markdown report
    #|  --json <path>         Write a machine-readable JSON report
    #|  --html <path>         Write a self-contained HTML report
    #|  --fail-on-fail        Exit with status 1 when the submission does not pass
    #|  --help                Show this help
  text
}

///|
fn require_value(
  args : ArrayView[String],
  index : Int32,
  flag : String,
) -> String raise CliError {
  if index + 1 >= args.length() {
    raise CliError("Missing value after \{flag}")
  }
  args[index + 1]
}

///|
fn parse_options(args : ArrayView[String]) -> CliOptions? raise CliError {
  let grade_index = match args.search("grade") {
    Some(index) => index
    None => {
      if args.contains("--help") || args.contains("-h") {
        println(help_text())
        return None
      }
      raise CliError(
        "Expected the `grade` command. Run with `--help` for usage.",
      )
    }
  }
  let mut assignment_path = "assignment.json"
  let mut student_path = "."
  let mut markdown_path : String? = None
  let mut json_path : String? = None
  let mut html_path : String? = None
  let mut fail_on_fail = false
  let mut index = grade_index + 1
  while index < args.length() {
    let arg = args[index]
    match arg {
      "--assignment" | "-a" => {
        assignment_path = require_value(args, index, arg)
        index += 2
      }
      "--student" | "-s" => {
        student_path = require_value(args, index, arg)
        index += 2
      }
      "--markdown" | "-m" => {
        markdown_path = Some(require_value(args, index, arg))
        index += 2
      }
      "--json" | "-j" => {
        json_path = Some(require_value(args, index, arg))
        index += 2
      }
      "--html" => {
        html_path = Some(require_value(args, index, arg))
        index += 2
      }
      "--fail-on-fail" => {
        fail_on_fail = true
        index += 1
      }
      "--help" => {
        println(help_text())
        return None
      }
      _ => raise CliError("Unknown option `\{arg}`")
    }
  }
  Some(CliOptions::{
    assignment_path,
    student_path,
    markdown_path,
    json_path,
    html_path,
    fail_on_fail,
  })
}

///|
fn join_path(base : StringView, child : StringView) -> String {
  if base.has_suffix("/") || base.has_suffix("\\") {
    "\{base}\{child}"
  } else {
    "\{base}/\{child}"
  }
}

///|
fn safe_file_stem(name : StringView) -> String {
  let builder = StringBuilder()
  for ch in name {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' {
      builder.write_char(ch)
    } else {
      builder.write_char('_')
    }
  }
  if builder.is_empty() {
    "student"
  } else {
    builder.to_string()
  }
}

///|
fn grade_submission(
  assignment : @moongrade.Assignment,
  student_path : String,
) -> @moongrade.GradeReport raise {
  let workspace = @runtime.prepare_workspace(student_path)
  let results = []
  for check in assignment.checks {
    let program = check.command[0]
    let command_args = []
    for index in 1..<check.command.length() {
      command_args.push(check.command[index])
    }
    let process = @runtime.run_process(
      program,
      command_args,
      workspace,
      check.timeout_seconds,
    )
    results.push(
      @moongrade.score_check(
        check,
        @moongrade.sanitize_process_result(process, workspace),
      ),
    )
  }
  @runtime.cleanup_workspace(workspace)
  @moongrade.build_report(assignment, student_path, results)
}

///|
fn print_summary(report : @moongrade.GradeReport) -> Unit {
  let result = if report.passed { "PASS" } else { "NEEDS WORK" }
  println(
    "MoonGrade  \{report.score}/\{report.max_score}  \{result}  \{report.assignment_name}",
  )
  for check in report.checks {
    let check_status = if check.passed { "PASS" } else { "FAIL" }
    println(
      "  \{check_status}  \{check.earned_points}/\{check.possible_points}  \{check.title}",
    )
  }
}

///|
fn run_single(args : ArrayView[String]) -> Int32 raise {
  let options = match parse_options(args) {
    Some(options) => options
    None => return 0
  }
  guard @fs.path_exists(options.assignment_path) else {
    raise CliError("Assignment file not found: \{options.assignment_path}")
  }
  guard @fs.path_exists(options.student_path) else {
    raise CliError("Student directory not found: \{options.student_path}")
  }
  let assignment_source = @fs.read_file_to_string(
    options.assignment_path,
    encoding="utf8",
  )
  let assignment = @moongrade.assignment_from_json(assignment_source)
  let report = grade_submission(assignment, options.student_path)
  print_summary(report)
  match options.markdown_path {
    Some(path) =>
      @fs.write_string_to_file(
        path,
        @moongrade.render_markdown(report),
        encoding="utf8",
      )
    None => ()
  }
  match options.json_path {
    Some(path) =>
      @fs.write_string_to_file(
        path,
        @moongrade.render_json(report),
        encoding="utf8",
      )
    None => ()
  }
  match options.html_path {
    Some(path) =>
      @fs.write_string_to_file(
        path,
        @moongrade.render_html(report),
        encoding="utf8",
      )
    None => ()
  }
  if options.fail_on_fail && !report.passed {
    1
  } else {
    0
  }
}

///|
fn run_batch(args : ArrayView[String]) -> Int32 raise {
  let batch_index = match args.search("batch") {
    Some(index) => index
    None => return 0
  }
  let mut assignment_path = "assignment.json"
  let mut students_path = "submissions"
  let mut reports_path = "reports"
  let mut fail_on_fail = false
  let mut index = batch_index + 1
  while index < args.length() {
    let arg = args[index]
    match arg {
      "--assignment" | "-a" => {
        assignment_path = require_value(args, index, arg)
        index += 2
      }
      "--students" => {
        students_path = require_value(args, index, arg)
        index += 2
      }
      "--reports" => {
        reports_path = require_value(args, index, arg)
        index += 2
      }
      "--fail-on-fail" => {
        fail_on_fail = true
        index += 1
      }
      "--help" => {
        println(help_text())
        return 0
      }
      _ => raise CliError("Unknown batch option `\{arg}`")
    }
  }
  guard @fs.path_exists(assignment_path) else {
    raise CliError("Assignment file not found: \{assignment_path}")
  }
  guard @fs.path_exists(students_path) else {
    raise CliError("Students directory not found: \{students_path}")
  }
  if !@fs.path_exists(reports_path) {
    @fs.create_dir(reports_path)
  }
  let assignment_source = @fs.read_file_to_string(
    assignment_path,
    encoding="utf8",
  )
  let assignment = @moongrade.assignment_from_json(assignment_source)
  let entries = @fs.read_dir(students_path)
  let summary = StringBuilder()
  summary.write_string("# MoonGrade class summary\n\n")
  summary.write_string("| Student | Score | Result |\n")
  summary.write_string("| --- | ---: | --- |\n")
  let mut graded = 0
  let mut passed = 0
  let mut any_failed = false
  for entry in entries {
    let student_path = join_path(students_path, entry)
    let has_module = @fs.path_exists(join_path(student_path, "moon.mod")) ||
      @fs.path_exists(join_path(student_path, "moon.mod.json"))
    if !has_module {
      continue
    }
    let report = grade_submission(assignment, student_path)
    let stem = safe_file_stem(entry)
    @fs.write_string_to_file(
      join_path(reports_path, "\{stem}.json"),
      @moongrade.render_json(report),
      encoding="utf8",
    )
    @fs.write_string_to_file(
      join_path(reports_path, "\{stem}.html"),
      @moongrade.render_html(report),
      encoding="utf8",
    )
    let result = if report.passed { "PASS" } else { "NEEDS WORK" }
    summary.write_string(
      "| \{entry} | \{report.score}/\{report.max_score} | \{result} |\n",
    )
    println("\{entry}: \{report.score}/\{report.max_score}  \{result}")
    graded += 1
    if report.passed {
      passed += 1
    } else {
      any_failed = true
    }
  }
  summary.write_string(
    "\nStudents graded: \{graded}. Passed: \{passed}. Needs work: \{graded - passed}.\n",
  )
  @fs.write_string_to_file(
    join_path(reports_path, "summary.md"),
    summary.to_string(),
    encoding="utf8",
  )
  println(
    "MoonGrade batch  \{graded} graded, \{passed} passed, \{graded - passed} need work",
  )
  if fail_on_fail && any_failed {
    1
  } else {
    0
  }
}

///|
fn run(args : ArrayView[String]) -> Int32 raise {
  if args.contains("batch") {
    run_batch(args)
  } else {
    run_single(args)
  }
}

///|
fn main {
  let code = run(@env.args()) catch {
    error => {
      eprintln("MoonGrade error: \{error}")
      2
    }
  }
  if code != 0 {
    @sys.exit(code)
  }
}
