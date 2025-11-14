/// Date extension
///
/// Replaces getMonthName method
extension DateExtension on int {
  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[this - 1];
  }
}
