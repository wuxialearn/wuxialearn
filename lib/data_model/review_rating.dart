final class ReviewRating{
  final int id;
  final String name;
  final Duration start;
  final Duration end;
  ReviewRating({required this.id, required this.name, required this.start, required this.end});
}

List<ReviewRating> createReviewRating(List<Map<String, dynamic>> data){
  List<ReviewRating> ratings = [];
  for (final item in data){
    ratings.add(
      ReviewRating(
          id: item["rating_id"],
          name: item["rating_name"],
          start: Duration(seconds: item["rating_duration_start"]),
          end: Duration(seconds: item["rating_duration_end"]),
      )
    );
  }
  return ratings;
}