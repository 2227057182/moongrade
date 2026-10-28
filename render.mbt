///|
fn json_escape(text : StringView) -> String {
  let builder = StringBuilder()
  for ch in text {
    match ch {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => builder.write_char(ch)
    }
  }
  builder.to_string()
}

///|
fn status_text(report : GradeReport) -> String {
  if report.passed {
    "PASS"
  } else {
    "NEEDS WORK"
  }
}

///|
pub fn render_markdown(report : GradeReport) -> String {
  let builder = StringBuilder()
  builder.write_string("# MoonGrade report\n\n")
  builder.write_string("- Assignment: **\{report.assignment_name}**\n")
  builder.write_string("- Submission: `\{report.student_path}`\n")
  builder.write_string("- Score: **\{report.score} / \{report.max_score}**\n")
  builder.write_string("- Result: **\{status_text(report)}**\n\n")
  builder.write_string("| Check | Result | Points | Time |\n")
  builder.write_string("| --- | --- | ---: | ---: |\n")
  for check in report.checks {
    let result = if check.passed { "PASS" } else { "FAIL" }
    builder.write_string(
      "| \{check.title} | \{result} | \{check.earned_points}/\{check.possible_points} | \{check.duration_ms} ms |\n",
    )
  }
  builder.write_string("\n## Feedback\n\n")
  for check in report.checks {
    if !check.feedback.is_empty() {
      builder.write_string("### \{check.title}\n\n")
      for feedback in check.feedback {
        builder.write_string("- \{feedback}\n")
      }
      builder.write_char('\n')
    }
  }
  builder.write_string("## Command output\n\n")
  for check in report.checks {
    builder.write_string("### \{check.title}\n\n")
    if check.output_excerpt.is_empty() {
      builder.write_string("No output.\n\n")
    } else {
      builder.write_string("```text\n\{check.output_excerpt}\n```\n\n")
    }
  }
  builder.to_string()
}

///|
pub fn render_json(report : GradeReport) -> String {
  let builder = StringBuilder()
  builder.write_string("{\n")
  builder.write_string(
    "  \"assignment\": \"\{json_escape(report.assignment_name)}\",\n",
  )
  builder.write_string(
    "  \"student_path\": \"\{json_escape(report.student_path)}\",\n",
  )
  builder.write_string("  \"score\": \{report.score},\n")
  builder.write_string("  \"max_score\": \{report.max_score},\n")
  builder.write_string("  \"passed\": \{report.passed},\n")
  builder.write_string("  \"checks\": [")
  for index, check in report.checks {
    if index > 0 {
      builder.write_char(',')
    }
    builder.write_string("\n    {")
    builder.write_string("\"id\": \"\{json_escape(check.id)}\", ")
    builder.write_string("\"title\": \"\{json_escape(check.title)}\", ")
    builder.write_string("\"passed\": \{check.passed}, ")
    builder.write_string("\"earned_points\": \{check.earned_points}, ")
    builder.write_string("\"possible_points\": \{check.possible_points}, ")
    builder.write_string("\"exit_code\": \{check.exit_code}, ")
    builder.write_string("\"timed_out\": \{check.timed_out}, ")
    builder.write_string("\"duration_ms\": \{check.duration_ms}, ")
    builder.write_string("\"feedback\": [")
    for feedback_index, feedback in check.feedback {
      if feedback_index > 0 {
        builder.write_char(',')
      }
      builder.write_string("\"\{json_escape(feedback)}\"")
    }
    builder.write_string("]}")
  }
  if !report.checks.is_empty() {
    builder.write_string("\n  ")
  }
  builder.write_string("]\n}\n")
  builder.to_string()
}

///|
pub fn render_html(report : GradeReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "<!doctype html><html lang=\"zh-CN\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>MoonGrade report</title>",
  )
  builder.write_string(
    "<style>:root{font-family:'Segoe UI','Microsoft YaHei',sans-serif;color:#172033;background:#f3f6fa}body{max-width:920px;margin:0 auto;padding:40px 24px}h1{font-size:32px;margin:0 0 8px}.score{font-size:20px;font-weight:700}.badge{display:inline-block;padding:5px 10px;border-radius:999px;background:#e5f4e8;color:#176b2c}.badge.fail{background:#fff0e8;color:#a33a0a}.card{background:#fff;border:1px solid #dce3eb;border-radius:12px;padding:20px;margin:16px 0}.check-head{display:flex;justify-content:space-between;gap:16px}.pass{color:#176b2c}.fail{color:#a33a0a}table{width:100%;border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid #dce3eb;text-align:left}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f5f7fa;padding:14px;border-radius:8px}</style></head><body>",
  )
  builder.write_string("<h1>MoonGrade report</h1>")
  builder.write_string("<p>\{json_escape(report.assignment_name)}</p>")
  builder.write_string(
    "<div class=\"score\">\{report.score} / \{report.max_score} points ",
  )
  if report.passed {
    builder.write_string("<span class=\"badge\">PASS</span></div>")
  } else {
    builder.write_string("<span class=\"badge fail\">NEEDS WORK</span></div>")
  }
  builder.write_string(
    "<table><thead><tr><th>Check</th><th>Result</th><th>Points</th><th>Time</th></tr></thead><tbody>",
  )
  for check in report.checks {
    let result = if check.passed { "PASS" } else { "FAIL" }
    let result_class = if check.passed { "pass" } else { "fail" }
    builder.write_string(
      "<tr><td>\{json_escape(check.title)}</td><td class=\"\{result_class}\">\{result}</td><td>\{check.earned_points}/\{check.possible_points}</td><td>\{check.duration_ms} ms</td></tr>",
    )
  }
  builder.write_string("</tbody></table>")
  for check in report.checks {
    builder.write_string(
      "<section class=\"card\"><div class=\"check-head\"><strong>\{json_escape(check.title)}</strong><span>\{check.earned_points}/\{check.possible_points}</span></div>",
    )
    if !check.feedback.is_empty() {
      builder.write_string("<ul>")
      for feedback in check.feedback {
        builder.write_string("<li>\{json_escape(feedback)}</li>")
      }
      builder.write_string("</ul>")
    }
    if !check.output_excerpt.is_empty() {
      builder.write_string("<pre>\{json_escape(check.output_excerpt)}</pre>")
    }
    builder.write_string("</section>")
  }
  builder.write_string("</body></html>")
  builder.to_string()
}
