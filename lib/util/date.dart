import 'package:date_format/date_format.dart';

class DateUtil {
  static bool isToday(dateTime) {
    String formattedDateTime = formatDate(dateTime, [yyyy, '-', mm, '-', dd]);
    DateTime now = DateTime.now();
    String formattedNow = formatDate(now, [yyyy, '-', mm, '-', dd]);
    return formattedDateTime == formattedNow;
  }
}
