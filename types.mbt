///|
pub(all) enum CheckKind {
  Compile
  Test
  Custom
}

///|
pub(all) struct CheckSpec {
  id : String
  title : String
  kind : CheckKind
  command : Array[String]
  points : Int32
  timeout_seconds : Int32
  required : Bool
  hint : String
}

///|
pub(all) struct Assignment {
  name : String
  description : String
  pass_score : Int32
  max_score : Int32
  checks : Array[CheckSpec]
}

///|
pub(all) struct ProcessResult {
  exit_code : Int32
  timed_out : Bool
  stdout : String
  stderr : String
  duration_ms : Int32
}

///|
pub(all) struct CheckResult {
  id : String
  title : String
  passed : Bool
  earned_points : Int32
  possible_points : Int32
  exit_code : Int32
  timed_out : Bool
  duration_ms : Int32
  feedback : Array[String]
  output_excerpt : String
}

///|
pub(all) struct GradeReport {
  assignment_name : String
  student_path : String
  score : Int32
  max_score : Int32
  passed : Bool
  checks : Array[CheckResult]
}

///|
pub(all) suberror AssessmentError {
  AssessmentError(String)
}

///|
pub fn check_kind_name(kind : CheckKind) -> String {
  match kind {
    Compile => "compile"
    Test => "test"
    Custom => "command"
  }
}
