class EvaluationReport {
  final int hospitalId;
  final int rating;
  final String dateTime;
  final String comment;

  EvaluationReport({
    required this.hospitalId,
    required this.rating,
    required this.dateTime,
    required this.comment,
  });

  factory EvaluationReport.fromDB(Map<String, dynamic> db) {
    return EvaluationReport(
      hospitalId: db['hospitalId'],
      rating: db['rating'],
      dateTime: db['dateTime'],
      comment: db['comment'],
    );
  }

  Map<String, dynamic> toDB() {
    return {
      'hospitalId': hospitalId,
      'rating': rating,
      'dateTime': dateTime,
      'comment': comment,
    };
  }
}