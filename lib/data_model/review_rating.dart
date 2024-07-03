final class ReviewRating {
  final int id;
  final String name;
  final Duration start;
  final Duration end;
  ReviewRating(
      {required this.id,
      required this.name,
      required this.start,
      required this.end});
  String startIntervalValue() {
    if (start.compareTo(const Duration(hours: 1)) < 0) {
      return start.inMinutes.toString();
    } else if (start.compareTo(const Duration(days: 1)) < 0) {
      return start.inHours.toString();
    } else {
      return start.inDays.toString();
    }
  }

  String startInterval() {
    if (start.compareTo(const Duration(hours: 1)) < 0) {
      return "min";
    } else if (start.compareTo(const Duration(days: 1)) < 0) {
      return "hrs";
    } else {
      return "days";
    }
  }

  String endIntervalValue() {
    if (end.compareTo(const Duration(hours: 1)) < 0) {
      return end.inMinutes.toString();
    } else if (end.compareTo(const Duration(days: 1)) < 0) {
      return end.inHours.toString();
    } else {
      return end.inDays.toString();
    }
  }

  String endInterval() {
    if (end.compareTo(const Duration(hours: 1)) < 0) {
      return "min";
    } else if (end.compareTo(const Duration(days: 1)) < 0) {
      return "hrs";
    } else {
      return "days";
    }
  }

  String interval() {
    String startInterval = this.startInterval();
    String startValue = startIntervalValue();
    String endInterval = this.endInterval();
    String endValue = endIntervalValue();
    late String interval;
    if (start == end) {
      interval = "$startValue $startInterval";
    } else if (startInterval == endInterval) {
      interval = "$startValue - $endValue $startInterval";
    } else {
      interval = "$startValue $startInterval - $endValue $endInterval";
    }
    return interval;
  }
}

List<ReviewRating> createReviewRating(List<Map<String, dynamic>> data) {
  List<ReviewRating> ratings = [];
  for (final item in data) {
    ratings.add(ReviewRating(
      id: item["rating_id"],
      name: item["rating_name"],
      start: Duration(seconds: item["rating_duration_start"]),
      end: Duration(seconds: item["rating_duration_end"]),
    ));
  }
  return ratings;
}
