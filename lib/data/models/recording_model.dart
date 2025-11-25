import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RecordingModel extends Equatable {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final String localPath;
  final int duration; // in seconds
  final int fileSize; // in bytes
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? uploadUrl;
  final bool isUploaded;

  const RecordingModel({
    required this.id,
    required this.meetingId,
    required this.meetingTitle,
    required this.localPath,
    required this.duration,
    required this.fileSize,
    required this.createdAt,
    required this.expiresAt,
    this.uploadUrl,
    this.isUploaded = false,
  });

  factory RecordingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordingModel(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      meetingTitle: data['meetingTitle'] ?? '',
      localPath: data['localPath'] ?? '',
      duration: data['duration'] ?? 0,
      fileSize: data['fileSize'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      uploadUrl: data['uploadUrl'],
      isUploaded: data['isUploaded'] ?? false,
    );
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] ?? '',
      meetingId: json['meetingId'] ?? '',
      meetingTitle: json['meetingTitle'] ?? '',
      localPath: json['localPath'] ?? '',
      duration: json['duration'] ?? 0,
      fileSize: json['fileSize'] ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] is Timestamp
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.parse(json['expiresAt']),
      uploadUrl: json['uploadUrl'],
      isUploaded: json['isUploaded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'localPath': localPath,
      'duration': duration,
      'fileSize': fileSize,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'uploadUrl': uploadUrl,
      'isUploaded': isUploaded,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'localPath': localPath,
      'duration': duration,
      'fileSize': fileSize,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'uploadUrl': uploadUrl,
      'isUploaded': isUploaded,
    };
  }

  RecordingModel copyWith({
    String? id,
    String? meetingId,
    String? meetingTitle,
    String? localPath,
    int? duration,
    int? fileSize,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? uploadUrl,
    bool? isUploaded,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysUntilExpiry {
    final difference = expiresAt.difference(DateTime.now());
    return difference.inDays;
  }

  @override
  List<Object?> get props => [
        id,
        meetingId,
        meetingTitle,
        localPath,
        duration,
        fileSize,
        createdAt,
        expiresAt,
        uploadUrl,
        isUploaded,
      ];

  @override
  String toString() {
    return 'RecordingModel(id: $id, meetingId: $meetingId, duration: $formattedDuration)';
  }
}