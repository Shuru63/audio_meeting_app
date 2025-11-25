import 'package:equatable/equatable.dart';

enum MeetingStatusEntity { waiting, active, ended }

class MeetingEntity extends Equatable {
  final String id;
  final String meetingCode;
  final String hostId;
  final String hostName;
  final String title;
  final MeetingStatusEntity status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int participantCount;
  final bool isRecording;

  const MeetingEntity({
    required this.id,
    required this.meetingCode,
    required this.hostId,
    required this.hostName,
    required this.title,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.participantCount,
    required this.isRecording,
  });

  bool get isActive => status == MeetingStatusEntity.active;
  bool get isEnded => status == MeetingStatusEntity.ended;
  bool get isWaiting => status == MeetingStatusEntity.waiting;

  Duration? get duration {
    if (startedAt != null && endedAt != null) {
      return endedAt!.difference(startedAt!);
    } else if (startedAt != null) {
      return DateTime.now().difference(startedAt!);
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        meetingCode,
        hostId,
        hostName,
        title,
        status,
        createdAt,
        startedAt,
        endedAt,
        participantCount,
        isRecording,
      ];

  @override
  String toString() {
    return 'MeetingEntity(id: $id, code: $meetingCode, status: $status)';
  }
}