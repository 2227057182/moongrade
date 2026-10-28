///|
extern "js" fn run_process_ffi(
  program : String,
  args : FixedArray[String],
  cwd : String,
  timeout_ms : Int32,
) -> String =
  #| (program, args, cwd, timeout_ms) => {
  #|   const getModule = (name) =>
  #|     typeof process.getBuiltinModule === "function"
  #|       ? process.getBuiltinModule(name)
  #|       : require(name);
  #|   const { spawnSync } = getModule("node:child_process");
  #|   const started = Date.now();
  #|   const result = spawnSync(program, args, {
  #|     cwd,
  #|     encoding: "utf8",
  #|     timeout: timeout_ms,
  #|     maxBuffer: 4 * 1024 * 1024,
  #|     windowsHide: true,
  #|   });
  #|   const timedOut = Boolean(result.error && result.error.code === "ETIMEDOUT");
  #|   return JSON.stringify({
  #|     exit_code: result.status === null ? -1 : result.status,
  #|     timed_out: timedOut,
  #|     stdout: result.stdout || "",
  #|     stderr: result.stderr || (result.error ? result.error.message : ""),
  #|     duration_ms: Date.now() - started,
  #|   });
  #| }

///|
extern "js" fn prepare_workspace_ffi(source : String) -> String =
  #| (source) => {
  #|   const getModule = (name) =>
  #|     typeof process.getBuiltinModule === "function"
  #|       ? process.getBuiltinModule(name)
  #|       : require(name);
  #|   const fs = getModule("node:fs");
  #|   const os = getModule("node:os");
  #|   const path = getModule("node:path");
  #|   const root = fs.mkdtempSync(path.join(os.tmpdir(), "moongrade-"));
  #|   const target = path.join(root, "submission");
  #|   const ignored = new Set(["_build", ".git", ".mooncakes", "node_modules"]);
  #|   fs.cpSync(source, target, {
  #|     recursive: true,
  #|     filter: (entry) => !ignored.has(path.basename(entry)),
  #|   });
  #|   return target;
  #| }

///|
extern "js" fn cleanup_workspace_ffi(path : String) -> Unit =
  #| (path) => {
  #|   const getModule = (name) =>
  #|     typeof process.getBuiltinModule === "function"
  #|       ? process.getBuiltinModule(name)
  #|       : require(name);
  #|   getModule("node:fs").rmSync(path, {
  #|     recursive: true,
  #|     force: true,
  #|   });
  #| }

///|
fn json_string(
  fields : Map[String, Json],
  key : String,
) -> String raise @moongrade.AssessmentError {
  match fields.get(key) {
    Some(String(value)) => value
    _ =>
      raise @moongrade.AssessmentError(
        "Runner response is missing string `\{key}`",
      )
  }
}

///|
fn json_int(
  fields : Map[String, Json],
  key : String,
) -> Int32 raise @moongrade.AssessmentError {
  match fields.get(key) {
    Some(Number(value, ..)) => value.to_int()
    _ =>
      raise @moongrade.AssessmentError(
        "Runner response is missing number `\{key}`",
      )
  }
}

///|
fn json_bool(
  fields : Map[String, Json],
  key : String,
) -> Bool raise @moongrade.AssessmentError {
  match fields.get(key) {
    Some(True) => true
    Some(False) => false
    _ =>
      raise @moongrade.AssessmentError(
        "Runner response is missing boolean `\{key}`",
      )
  }
}

///|
pub fn run_process(
  program : String,
  args : Array[String],
  cwd : String,
  timeout_seconds : Int32,
) -> @moongrade.ProcessResult raise @moongrade.AssessmentError {
  let raw = run_process_ffi(
    program,
    FixedArray::from_array(args[:]),
    cwd,
    timeout_seconds * 1000,
  )
  let document = @json.parse(raw) catch {
    error =>
      raise @moongrade.AssessmentError(
        "Could not parse runner response: \{error.to_string()}",
      )
  }
  guard document is Object(fields) else {
    raise @moongrade.AssessmentError("Runner returned an invalid response")
  }
  @moongrade.ProcessResult::{
    exit_code: json_int(fields, "exit_code"),
    timed_out: json_bool(fields, "timed_out"),
    stdout: json_string(fields, "stdout"),
    stderr: json_string(fields, "stderr"),
    duration_ms: json_int(fields, "duration_ms"),
  }
}

///|
pub fn prepare_workspace(source : String) -> String {
  prepare_workspace_ffi(source)
}

///|
pub fn cleanup_workspace(path : String) -> Unit {
  cleanup_workspace_ffi(path)
}
