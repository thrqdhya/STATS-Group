class QRToken {
  final int? tokenId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int sessionId;

  QRToken({
    this.tokenId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'token_id': tokenId,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'session_id': sessionId,
    };
  }

  factory QRToken.fromMap(Map<String, dynamic> map) {
    return QRToken(
      tokenId: map['token_id'],
      token: map['token'],
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      sessionId: map['session_id'],
    );
  }

  bool isValid() {
    return DateTime.now().isBefore(expiresAt);
  }
}