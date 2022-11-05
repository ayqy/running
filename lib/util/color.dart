import 'dart:math';
import 'dart:ui';

class ColorUtil {
  static Color mapSpeedToColor(double speed) {
    const MIN_OPACITY = 0.3;
    const MAX_OPACITY = 0.9;
    const Color HEAVY_GREEN = Color.fromRGBO(0, 185, 107, MAX_OPACITY);
    const Color GREEN = Color.fromRGBO(0, 185, 107, MIN_OPACITY);
    const Color YELLOW = Color.fromRGBO(255, 236, 61, MIN_OPACITY);
    const Color HEAVY_YELLOW = Color.fromRGBO(255, 236, 61, MAX_OPACITY);
    const Color RED = Color.fromRGBO(255, 77, 79, MIN_OPACITY);
    const Color HEAVY_RED = Color.fromRGBO(255, 77, 79, MAX_OPACITY);
    // 9分钟1公里是快走的速度，作为慢速档位
    const double SLOW_SPEED = 1000 / (9 * 60);
    // 5分半1公里是快跑的速度，作为快速档位
    const double FAST_SPEED = 1000 / (5.5 * 60);

    Color color;
    if (speed < SLOW_SPEED) {
      color = getGradientColor(HEAVY_GREEN, GREEN, [0, SLOW_SPEED], speed);
    }
    else if (speed > FAST_SPEED) {
      color = getGradientColor(RED, HEAVY_RED, [FAST_SPEED, 10], min(speed, 10));
    }
    else {
      color = getGradientColor(YELLOW, HEAVY_YELLOW, [SLOW_SPEED, FAST_SPEED], speed);
    }

    return color;
  }

  static Color getGradientColor(Color startColor, Color endColor, List<double> valueRegion, double value) {
    // 两端色值一样，不用求渐变
    if (startColor == endColor) {
      return startColor;
    }

    double factor = (value - valueRegion[0]) / (valueRegion[1] - valueRegion[0]);
    int r = (startColor.red + (endColor.red - startColor.red) * factor).truncate();
    int g = (startColor.green + (endColor.green - startColor.green) * factor).truncate();
    int b = (startColor.blue + (endColor.blue - startColor.blue) * factor).truncate();
    double opacity = startColor.opacity + (endColor.opacity - startColor.opacity) * factor;
    return Color.fromRGBO(r, g, b, opacity);
  }

  static Color getSegmentColor(double startSpeed, double endSpeed) {
    double averageSpped = (startSpeed + endSpeed) / 2;
    Color color = mapSpeedToColor(averageSpped);
    return color;
  }

  static Color withOpacity(Color color, double opacity) {
    return Color.fromRGBO(color.red, color.green, color.blue, opacity);
  }
}
