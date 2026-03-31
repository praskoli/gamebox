class PlayAccessApprovalRequest {
  const PlayAccessApprovalRequest({
    required this.requestId,
    required this.status,
    required this.gameId,
    required this.levelNumber,
    required this.channel,
    required this.destination,
    required this.destinationMasked,
    required this.otpCode,
    required this.createdAtEpochMs,
    required this.expiresAtEpochMs,
    required this.usedAtEpochMs,
    required this.grantMinutes,
    required this.grantLevels,
    required this.resendAvailableAtEpochMs,
  });

  final String requestId;
  final String status;
  final String gameId;
  final int levelNumber;
  final String channel;
  final String destination;
  final String destinationMasked;
  final String otpCode;
  final int createdAtEpochMs;
  final int expiresAtEpochMs;
  final int usedAtEpochMs;
  final int grantMinutes;
  final int grantLevels;
  final int resendAvailableAtEpochMs;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isConsumed => status == 'consumed';
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAtEpochMs;

  bool get canResendNow =>
      DateTime.now().millisecondsSinceEpoch >= resendAvailableAtEpochMs;

  int get resendRemainingSeconds {
    final remaining =
    ((resendAvailableAtEpochMs - DateTime.now().millisecondsSinceEpoch) /
        1000)
        .ceil();
    return remaining < 0 ? 0 : remaining;
  }

  factory PlayAccessApprovalRequest.initial() {
    return const PlayAccessApprovalRequest(
      requestId: '',
      status: 'none',
      gameId: '',
      levelNumber: 0,
      channel: '',
      destination: '',
      destinationMasked: '',
      otpCode: '',
      createdAtEpochMs: 0,
      expiresAtEpochMs: 0,
      usedAtEpochMs: 0,
      grantMinutes: 0,
      grantLevels: 0,
      resendAvailableAtEpochMs: 0,
    );
  }

  factory PlayAccessApprovalRequest.fromMap(Map<String, dynamic> map) {
    return PlayAccessApprovalRequest(
      requestId: (map['requestId'] ?? '').toString().trim(),
      status: (map['status'] ?? 'none').toString().trim(),
      gameId: (map['gameId'] ?? '').toString().trim(),
      levelNumber: _toInt(map['levelNumber'], 0),
      channel: (map['channel'] ?? '').toString().trim().toLowerCase(),
      destination: (map['destination'] ?? '').toString().trim(),
      destinationMasked: (map['destinationMasked'] ?? '').toString().trim(),
      otpCode: (map['otpCode'] ?? '').toString().trim(),
      createdAtEpochMs: _toInt(map['createdAtEpochMs'], 0),
      expiresAtEpochMs: _toInt(map['expiresAtEpochMs'], 0),
      usedAtEpochMs: _toInt(map['usedAtEpochMs'], 0),
      grantMinutes: _toInt(map['grantMinutes'], 0),
      grantLevels: _toInt(map['grantLevels'], 0),
      resendAvailableAtEpochMs: _toInt(map['resendAvailableAtEpochMs'], 0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'requestId': requestId,
      'status': status,
      'gameId': gameId,
      'levelNumber': levelNumber,
      'channel': channel,
      'destination': destination,
      'destinationMasked': destinationMasked,
      'otpCode': otpCode,
      'createdAtEpochMs': createdAtEpochMs,
      'expiresAtEpochMs': expiresAtEpochMs,
      'usedAtEpochMs': usedAtEpochMs,
      'grantMinutes': grantMinutes,
      'grantLevels': grantLevels,
      'resendAvailableAtEpochMs': resendAvailableAtEpochMs,
    };
  }

  PlayAccessApprovalRequest copyWith({
    String? requestId,
    String? status,
    String? gameId,
    int? levelNumber,
    String? channel,
    String? destination,
    String? destinationMasked,
    String? otpCode,
    int? createdAtEpochMs,
    int? expiresAtEpochMs,
    int? usedAtEpochMs,
    int? grantMinutes,
    int? grantLevels,
    int? resendAvailableAtEpochMs,
  }) {
    return PlayAccessApprovalRequest(
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      gameId: gameId ?? this.gameId,
      levelNumber: levelNumber ?? this.levelNumber,
      channel: channel ?? this.channel,
      destination: destination ?? this.destination,
      destinationMasked: destinationMasked ?? this.destinationMasked,
      otpCode: otpCode ?? this.otpCode,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      expiresAtEpochMs: expiresAtEpochMs ?? this.expiresAtEpochMs,
      usedAtEpochMs: usedAtEpochMs ?? this.usedAtEpochMs,
      grantMinutes: grantMinutes ?? this.grantMinutes,
      grantLevels: grantLevels ?? this.grantLevels,
      resendAvailableAtEpochMs:
      resendAvailableAtEpochMs ?? this.resendAvailableAtEpochMs,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}