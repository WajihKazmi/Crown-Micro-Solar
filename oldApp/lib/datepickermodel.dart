import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;

class YearMonthModel extends picker.DatePickerModel {
  YearMonthModel(
      {DateTime? currentTime,
      DateTime? maxTime,
      DateTime? minTime,
      picker.LocaleType? locale})
      : super(
            currentTime: currentTime,
            maxTime: maxTime,
            minTime: minTime,
            locale: locale);
  @override
  List<int> layoutProportions() {
    return [1, 1, 0];
  }
}

class YearModel extends picker.DatePickerModel {
  YearModel(
      {DateTime? currentTime,
      DateTime? maxTime,
      DateTime? minTime,
      picker.LocaleType? locale})
      : super(
            currentTime: currentTime,
            maxTime: maxTime,
            minTime: minTime,
            locale: locale);
  @override
  List<int> layoutProportions() {
    return [1, 0, 0];
  }
}

class YearMonthDayModel extends picker.DatePickerModel {
  YearMonthDayModel(
      {DateTime? currentTime,
      DateTime? maxTime,
      DateTime? minTime,
      picker.LocaleType? locale})
      : super(
            currentTime: currentTime,
            maxTime: maxTime,
            minTime: minTime,
            locale: locale);
  @override
  List<int> layoutProportions() {
    return [1, 1, 1];
  }
}
