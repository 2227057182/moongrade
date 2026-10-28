///|
fn required_string(
  fields : Map[String, Json],
  key : String,
) -> String raise AssessmentError {
  match fields.get(key) {
    Some(String(value)) if !value.is_empty() => value
    Some(String(_)) => raise AssessmentError("Field `\{key}` must not be empty")
    Some(_) => raise AssessmentError("Field `\{key}` must be a string")
    None => raise AssessmentError("Missing required field `\{key}`")
  }
}

///|
fn optional_string(
  fields : Map[String, Json],
  key : String,
  default_value : String,
) -> String raise AssessmentError {
  match fields.get(key) {
    Some(String(value)) => value
    Some(_) => raise AssessmentError("Field `\{key}` must be a string")
    None => default_value
  }
}

///|
fn required_positive_int(
  fields : Map[String, Json],
  key : String,
) -> Int32 raise AssessmentError {
  match fields.get(key) {
    Some(Number(value, ..)) => {
      if value < 1.0 || value > 1_000_000.0 {
        raise AssessmentError("Field `\{key}` must be a positive integer")
      }
      value.to_int()
    }
    Some(_) => raise AssessmentError("Field `\{key}` must be a number")
    None => raise AssessmentError("Missing required field `\{key}`")
  }
}

///|
fn optional_bool(
  fields : Map[String, Json],
  key : String,
  default_value : Bool,
) -> Bool raise AssessmentError {
  match fields.get(key) {
    Some(True) => true
    Some(False) => false
    Some(_) => raise AssessmentError("Field `\{key}` must be a boolean")
    None => default_value
  }
}

///|
fn string_array(
  value : Json,
  field_name : String,
) -> Array[String] raise AssessmentError {
  match value {
    Array(items) => {
      let result = []
      for item in items {
        match item {
          String(text) if !text.is_empty() => result.push(text)
          String(_) =>
            raise AssessmentError(
              "`\{field_name}` commands must not contain empty strings",
            )
          _ =>
            raise AssessmentError("`\{field_name}` must contain only strings")
        }
      }
      result
    }
    _ => raise AssessmentError("`\{field_name}` must be an array")
  }
}

///|
fn parse_check_kind(value : String) -> CheckKind raise AssessmentError {
  match value {
    "check" | "moon_check" => Compile
    "test" | "moon_test" => Test
    "command" | "custom" => Custom
    _ => raise AssessmentError("Unsupported check kind `\{value}`")
  }
}

///|
fn same_kind(left : CheckKind, right : CheckKind) -> Bool {
  match (left, right) {
    (Compile, Compile) | (Test, Test) | (Custom, Custom) => true
    _ => false
  }
}

///|
fn default_command(kind : CheckKind) -> Array[String] {
  match kind {
    Compile => ["moon", "check"]
    Test => ["moon", "test"]
    Custom => []
  }
}

///|
fn parse_check(value : Json, index : Int32) -> CheckSpec raise AssessmentError {
  guard value is Object(fields) else {
    raise AssessmentError("Check #\{index + 1} must be an object")
  }
  let id = required_string(fields, "id")
  let title = optional_string(fields, "title", id)
  let kind = parse_check_kind(optional_string(fields, "kind", "check"))
  let points = required_positive_int(fields, "points")
  let timeout_seconds = match fields.get("timeout_seconds") {
    Some(_) => required_positive_int(fields, "timeout_seconds")
    None => 120
  }
  guard timeout_seconds <= 3600 else {
    raise AssessmentError("Check `\{id}` timeout must not exceed 3600 seconds")
  }
  let command = match fields.get("command") {
    Some(value) => string_array(value, "check `\{id}` command")
    None => default_command(kind)
  }
  if same_kind(kind, Custom) && command.is_empty() {
    raise AssessmentError("Custom check `\{id}` requires a non-empty command")
  }
  CheckSpec::{
    id,
    title,
    kind,
    command,
    points,
    timeout_seconds,
    required: optional_bool(fields, "required", true),
    hint: optional_string(fields, "hint", ""),
  }
}

///|
pub fn assignment_from_json(
  source : StringView,
) -> Assignment raise AssessmentError {
  let document = @json.parse(source) catch {
    error =>
      raise AssessmentError("Invalid assignment JSON: \{error.to_string()}")
  }
  guard document is Object(fields) else {
    raise AssessmentError("Assignment JSON must be an object")
  }
  let name = required_string(fields, "name")
  let description = optional_string(fields, "description", "")
  let pass_score = required_positive_int(fields, "pass_score")
  let raw_checks = match fields.get("checks") {
    Some(Array(items)) if !items.is_empty() => items
    Some(Array(_)) =>
      raise AssessmentError("Assignment must contain at least one check")
    Some(_) => raise AssessmentError("`checks` must be an array")
    None => raise AssessmentError("Missing required field `checks`")
  }
  let checks = []
  let ids : Map[String, Bool] = Map([])
  let mut max_score = 0
  for index, raw_check in raw_checks {
    let check = parse_check(raw_check, index)
    if ids.contains(check.id) {
      raise AssessmentError("Duplicate check id `\{check.id}`")
    }
    ids.set(check.id, true)
    max_score += check.points
    checks.push(check)
  }
  guard pass_score <= max_score else {
    raise AssessmentError(
      "`pass_score` (\{pass_score}) exceeds total available points (\{max_score})",
    )
  }
  Assignment::{ name, description, pass_score, max_score, checks, }
}
