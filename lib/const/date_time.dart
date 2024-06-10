import 'package:intl/intl.dart';

class DateTImeFormatter{

  static String convertJapanToMyanmarTime(String japanTime) {
      DateTime japanDateTime = DateTime.parse(japanTime);

      DateTime myanmarDateTime =
          japanDateTime.add(const Duration(hours: -2, minutes: -30));

      String myanmarTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(myanmarDateTime);

      return myanmarTime;
    }
}