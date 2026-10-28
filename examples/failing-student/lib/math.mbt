///|
pub fn add(left : Int, right : Int) -> Int {
  left + right
}

///|
pub fn clamp(value : Int, low : Int, high : Int) -> Int {
  if value < low {
    high
  } else if value > high {
    high
  } else {
    value
  }
}
