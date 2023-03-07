class Sets {
  final int? id;
  final int? workout;
  final int targetNumTime;
  final int? weight;
  final String date;
  final String createdAt;
  final String updatedAt;

  Sets({ this.id, this.workout, required this.targetNumTime, this.weight, required this.date, required this.createdAt, required this.updatedAt});

  factory Sets.fromMap(Map<String, dynamic> json) => Sets(
    id: json['id'],
    workout: json['workout'],
    targetNumTime: json['target_num_time'],
    weight: json['weight'],
    date: json['date'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout': workout,
      'target_num_time': targetNumTime,
      'weight': weight,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }

}