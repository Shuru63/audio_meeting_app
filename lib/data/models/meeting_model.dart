import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MeetingStatus { waiting, active, ended }

class MeetingModel extends Equatable {
  final String id;
  final String meetingCode;
  final String hostId;
  final String hostName;
  final String title;
  final MeetingStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int participantCount;
  final bool isRecording;
  final String? recordingUrl;
  final List<String> participantIds;

  const MeetingModel({
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
    this.recordingUrl,
    required this.participantIds,
  });

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      meetingCode: data['meetingCode'] ?? '',
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      title: data['title'] ?? '',
      status: _stringToStatus(data['status'] ?? 'waiting'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      participantCount: data['participantCount'] ?? 0,
      isRecording: data['isRecording'] ?? false,
      recordingUrl: data['recordingUrl'],
      participantIds: List<String>.from(data['participantIds'] ?? []),
    );
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? '',
      meetingCode: json['meetingCode'] ?? '',
      hostId: json['hostId'] ?? '',
      hostName: json['hostName'] ?? '',
      title: json['title'] ?? '',
      status: _stringToStatus(json['status'] ?? 'waiting'),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] is Timestamp
              ? (json['startedAt'] as Timestamp).toDate()
              : DateTime.parse(json['startedAt']))
          : null,
      endedAt: json['endedAt'] != null
          ? (json['endedAt'] is Timestamp
              ? (json['endedAt'] as Timestamp).toDate()
              : DateTime.parse(json['endedAt']))
          : null,
      participantCount: json['participantCount'] ?? 0,
      isRecording: json['isRecording'] ?? false,
      recordingUrl: json['recordingUrl'],
      participantIds: List<String>.from(json['participantIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetingCode': meetingCode,
      'hostId': hostId,
      'hostName': hostName,
      'title': title,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'participantCount': participantCount,
      'isRecording': isRecording,
      'recordingUrl': recordingUrl,
      'participantIds': participantIds,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingCode': meetingCode,
      'hostId': hostId,
      'hostName': hostName,
      'title': title,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'participantCount': participantCount,
      'isRecording': isRecording,
      'recordingUrl': recordingUrl,
      'participantIds': participantIds,
    };
  }

  static MeetingStatus _stringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return MeetingStatus.active;
      case 'ended':
        return MeetingStatus.ended;
      default:
        return MeetingStatus.waiting;
    }
  }

  static String _statusToString(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.active:
        return 'active';
      case MeetingStatus.ended:
        return 'ended';
      default:
        return 'waiting';
    }
  }

  MeetingModel copyWith({
    String? id,
    String? meetingCode,
    String? hostId,
    String? hostName,
    String? title,
    MeetingStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? participantCount,
    bool? isRecording,
    String? recordingUrl,
    List<String>? participantIds,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      meetingCode: meetingCode ?? this.meetingCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      participantCount: participantCount ?? this.participantCount,
      isRecording: isRecording ?? this.isRecording,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  bool get isActive => status == MeetingStatus.active;
  bool get isEnded => status == MeetingStatus.ended;
  bool get isWaiting => status == MeetingStatus.waiting;

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
        recordingUrl,
        participantIds,
      ];

  @override
  String toString() {
    return 'MeetingModel(id: $id, code: $meetingCode, status: $status)';
  }
}