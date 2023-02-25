class Sets {
  final int? id;
  final int? workout;
  final int? targetNumTime;
  final int? weight;
  final String created_at;
  final String updated_at;

  Sets({ this.id, this.workout, this.targetNumTime, this.weight, required this.created_at, required this.updated_at});

  factory Sets.fromMap(Map<String, dynamic> json) => Sets(
    id: json['id'],
    workout: json['workout'],
    targetNumTime: json['targetNumTime'],
    weight: json['weight'],
    created_at: json['created_at'],
    updated_at: json['updated_at'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout': workout,
      'targetNumTime': targetNumTime,
      'weight': weight,
      'created_at': created_at,
      'updated_at': updated_at
    };
  }

}