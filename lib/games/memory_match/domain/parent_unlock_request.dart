class ParentUnlockRequest {
  const ParentUnlockRequest({
    required this.status,
    required this.requestedAtEpochMs,
    required this.resolvedAtEpochMs,
    required this.requestedWorldId,
    required this.requestedLevelNumber,
  });

  final String status;
  final int requestedAtEpochMs;
  final int resolvedAtEpochMs;
  final String requestedWorldId;
  final int requestedLevelNumber;

  bool get isPending => status == 'pending';

  factory ParentUnlockRequest.initial() {
    return const ParentUnlockRequest(
      status: 'none',
      requestedAtEpochMs: 0,
      resolvedAtEpochMs: 0,
      requestedWorldId: '',
      requestedLevelNumber: 0,
    );
  }

  factory ParentUnlockRequest.fromMap(Map<String, dynamic> map) {
    return ParentUnlockRequest(
      status: (map['status'] ?? 'none').toString(),
      requestedAtEpochMs: _toInt(map['requestedAtEpochMs'], 0),
      resolvedAtEpochMs: _toInt(map['resolvedAtEpochMs'], 0),
      requestedWorldId: (map['requestedWorldId'] ?? '').toString(),
      requestedLevelNumber: _toInt(map['requestedLevelNumber'], 0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
      'requestedAtEpochMs': requestedAtEpochMs,
      'resolvedAtEpochMs': resolvedAtEpochMs,
      'requestedWorldId': requestedWorldId,
      'requestedLevelNumber': requestedLevelNumber,
    };
  }

  ParentUnlockRequest copyWith({
    String? status,
    int? requestedAtEpochMs,
    int? resolvedAtEpochMs,
    String? requestedWorldId,
    int? requestedLevelNumber,
  }) {
    return ParentUnlockRequest(
      status: status ?? this.status,
      requestedAtEpochMs: requestedAtEpochMs ?? this.requestedAtEpochMs,
      resolvedAtEpochMs: resolvedAtEpochMs ?? this.resolvedAtEpochMs,
      requestedWorldId: requestedWorldId ?? this.requestedWorldId,
      requestedLevelNumber: requestedLevelNumber ?? this.requestedLevelNumber,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}