class ApiKeyModel {
  final String key;
  final String provider; // 'gemini', 'openai', etc.
  final bool isActive;
  final DateTime? cooldownUntil;
  final int usageCount;

  ApiKeyModel({
    required this.key,
    required this.provider,
    this.isActive = true,
    this.cooldownUntil,
    this.usageCount = 0,
  });

  // Effective status: manual active flag AND (no cooldown or cooldown passed)
  bool get isEffectivelyActive {
    if (!isActive) return false;
    if (cooldownUntil != null) {
      return DateTime.now().isAfter(cooldownUntil!);
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'provider': provider,
      'isActive': isActive,
      'cooldownUntil': cooldownUntil?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      key: json['key'] as String,
      provider: json['provider'] as String,
      isActive: json['isActive'] as bool? ?? true,
      cooldownUntil: json['cooldownUntil'] != null
          ? DateTime.tryParse(json['cooldownUntil'])
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  ApiKeyModel copyWith({
    String? key,
    String? provider,
    bool? isActive,
    DateTime? cooldownUntil,
    int? usageCount,
  }) {
    return ApiKeyModel(
      key: key ?? this.key,
      provider: provider ?? this.provider,
      isActive: isActive ?? this.isActive,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
