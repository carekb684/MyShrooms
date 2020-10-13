class DateHelper {

  static String getRemindDate(int count) {
    String remindDate = DateTime.now().add(Duration(days: count)).toIso8601String().split("T").first;
    return remindDate;
  }

  static int getDaysCountFromStringDate(String remindDate) {
    DateTime date = DateTime.parse(remindDate);
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);
    Duration diff = date.difference(now);
    if (diff.isNegative) return 0;
    return diff.inDays;
  }
}