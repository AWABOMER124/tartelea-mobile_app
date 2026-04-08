class SubscriptionModel {
  final String id;
  final String userId;
  final String planName;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      planName: json['plan_name'] as String? ?? 'free',
      status: json['status'] as String? ?? 'inactive',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_name': planName,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}
