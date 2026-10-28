///|
test "adds integers" {
  assert_eq(@lib.add(2, 3), 5)
}

///|
test "clamps values" {
  assert_eq(@lib.clamp(9, 0, 5), 5)
  assert_eq(@lib.clamp(-2, 0, 5), 0)
}
