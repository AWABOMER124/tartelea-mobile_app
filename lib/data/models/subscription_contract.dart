class SubscriptionAccess {
  final bool canAccessLibrary;
  final bool canAccessFullLibrary;
  final bool canJoinRoom;
  final bool canJoinPremiumRoom;
  final bool canCreateRoom;
  final bool canAskQuestion;
  final bool canGetDiscount;

  const SubscriptionAccess({
    required this.canAccessLibrary,
    required this.canAccessFullLibrary,
    required this.canJoinRoom,
    required this.canJoinPremiumRoom,
    required this.canCreateRoom,
    required this.canAskQuestion,
    required this.canGetDiscount,
  });

  factory SubscriptionAccess.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return SubscriptionAccess(
      canAccessLibrary: map['canAccessLibrary'] == true,
      canAccessFullLibrary: map['canAccessFullLibrary'] == true,
      canJoinRoom: map['canJoinRoom'] == true,
      canJoinPremiumRoom: map['canJoinPremiumRoom'] == true,
      canCreateRoom: map['canCreateRoom'] == true,
      canAskQuestion: map['canAskQuestion'] == true,
      canGetDiscount: map['canGetDiscount'] == true,
    );
  }
}

class SubscriptionDiscounts {
  final int coursesPercent;

  const SubscriptionDiscounts({required this.coursesPercent});

  factory SubscriptionDiscounts.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final value = map['courses_percent'];
    if (value is num) {
      return SubscriptionDiscounts(coursesPercent: value.toInt());
    }
    return const SubscriptionDiscounts(coursesPercent: 0);
  }
}

class SubscriptionRoleOverrides {
  final bool trainer;
  final bool admin;

  const SubscriptionRoleOverrides({
    required this.trainer,
    required this.admin,
  });

  factory SubscriptionRoleOverrides.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return SubscriptionRoleOverrides(
      trainer: map['trainer'] == true,
      admin: map['admin'] == true,
    );
  }
}

class SubscriptionPayment {
  final List<String> supportedProviders;
  final String? source;

  const SubscriptionPayment({
    required this.supportedProviders,
    required this.source,
  });

  factory SubscriptionPayment.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final providers = map['supported_providers'];
    return SubscriptionPayment(
      supportedProviders: providers is List
          ? providers.map((item) => item.toString()).toList()
          : const <String>[],
      source: map['source']?.toString(),
    );
  }
}

class SubscriptionContract {
  final String plan;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<String> entitlements;
  final List<String> scopedCourseIds;
  final SubscriptionAccess access;
  final SubscriptionDiscounts discounts;
  final SubscriptionRoleOverrides roleOverrides;
  final SubscriptionPayment payment;

  const SubscriptionContract({
    required this.plan,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.entitlements,
    required this.scopedCourseIds,
    required this.access,
    required this.discounts,
    required this.roleOverrides,
    required this.payment,
  });

  bool get isActive => status == 'active';

  bool get isFreePlan => plan == 'free';

  factory SubscriptionContract.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    final entitlements = json['entitlements'];
    final scopedCourseIds = json['scoped_course_ids'];

    return SubscriptionContract(
      plan: json['plan']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'active',
      startsAt: parseDate(json['starts_at']),
      endsAt: parseDate(json['ends_at']),
      entitlements: entitlements is List
          ? entitlements.map((item) => item.toString()).toList()
          : const <String>[],
      scopedCourseIds: scopedCourseIds is List
          ? scopedCourseIds.map((item) => item.toString()).toList()
          : const <String>[],
      access: SubscriptionAccess.fromJson(json['access'] as Map<String, dynamic>?),
      discounts: SubscriptionDiscounts.fromJson(json['discounts'] as Map<String, dynamic>?),
      roleOverrides:
          SubscriptionRoleOverrides.fromJson(json['role_overrides'] as Map<String, dynamic>?),
      payment: SubscriptionPayment.fromJson(json['payment'] as Map<String, dynamic>?),
    );
  }
}

