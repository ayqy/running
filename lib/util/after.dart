void Function()? after(int times, Function fn) {
  if (times < 0) {
    times = 0;
  }
  return () {
    if (times <= 1) {
      fn();
    }
    else {
      times--;
    }
  };
}