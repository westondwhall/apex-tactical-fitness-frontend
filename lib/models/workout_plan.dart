class WorkoutPlan {
  final String status;
  final String workoutPlanText;

  WorkoutPlan({
    required this.status,
    required this.workoutPlanText,
  });

  factory WorkoutPlan.fromJson(Map json) {
    return WorkoutPlan(
      status: json['status'] ?? 'success',
      workoutPlanText: json['workout_plan'] ?? '',
    );
  }
}