class Converter {
  /// m/s 转 s/km（默认）
  static int mps2spkm(mps) {
    double mpm = mps * 60;
    double min = 1000 / mpm;
    int m = min.truncate();
    int s = (min * 60 % 60).round();
    return m * 60 + s;
  }
}
