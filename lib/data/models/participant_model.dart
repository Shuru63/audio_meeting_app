import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ParticipantStatus { active, left, removed }

class ParticipantModel extends Equatable {
  final String id;
  final String meetingId;
  final String userId;
  final String userName;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isHost;
  final ParticipantStatus status;

  const ParticipantModel({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    this.leftAt,
    required this.isMuted,
    required this.isHost,
    required this.status,
  });

  factory ParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParticipantModel(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      leftAt: data['leftAt'] != null
          ? (data['leftAt'] as Timestamp).toDate()
          : null,
      isMuted: data['isMuted'] ?? false,
      isHost: data['isHost'] ?? false,
      status: _stringToStatus(data['status'] ?? 'active'),
    );
  }

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? '',
      meetingId: json['meetingId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      joinedAt: json['joinedAt'] is Timestamp
          ? (json['joinedAt'] as Timestamp).toDate()
          : DateTime.parse(json['joinedAt']),
      leftAt: json['leftAt'] != null
          ? (json['leftAt'] is Timestamp
              ? (json['leftAt'] as Timestamp).toDate()
              : DateTime.parse(json['leftAt']))
          : null,
      isMuted: json['isMuted'] ?? false,
      isHost: json['isHost'] ?? false,
      status: _stringToStatus(json['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetingId': meetingId,
      'userId': userId,
      'userName': userName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'isMuted': isMuted,
      'isHost': isHost,
      'status': _statusToString(status),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'userId': userId,
      'userName': userName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'isMuted': isMuted,
      'isHost': isHost,
      'status': _statusToString(status),
    };
  }

  static ParticipantStatus _stringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'left':
        return ParticipantStatus.left;
      case 'removed':
        return ParticipantStatus.removed;
      default:
        return ParticipantStatus.active;
    }
  }

  static String _statusToString(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.left:
        return 'left';
      case ParticipantStatus.removed:
        return 'removed';
      default:
        return 'active';
    }
  }

  ParticipantModel copyWith({
    String? id,
    String? meetingId,
    String? userId,
    String? userName,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isMuted,
    bool? isHost,
    ParticipantStatus? status,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isMuted: isMuted ?? this.isMuted,
      isHost: isHost ?? this.isHost,
      status: status ?? this.status,
    );
  }

  bool get isActive => status == ParticipantStatus.active;
  bool get hasLeft => status == ParticipantStatus.left;
  bool get wasRemoved => status == ParticipantStatus.removed;

  Duration? get duration {
    if (leftAt != null) {
      return leftAt!.difference(joinedAt);
    }
    return DateTime.now().difference(joinedAt);
  }

  @override
  List<Object?> get props => [
        id,
        meetingId,
        userId,
        userName,
        joinedAt,
        leftAt,
        isMuted,
        isHost,
        status,
      ];

  @override
  String toString() {
    return 'ParticipantModel(id: $id, userName: $userName, status: $status)';
  }
}