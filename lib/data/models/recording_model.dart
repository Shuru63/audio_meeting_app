import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class RecordingModel {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final String userId;
  final String localPath;
  final int duration; // in seconds
  final int fileSize; // in bytes
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUploaded;
  final String? uploadUrl;
  final DateTime? uploadedAt;
  final String status; // 'recording', 'completed', 'uploaded', 'local'

  RecordingModel({
    required this.id,
    required this.meetingId,
    required this.meetingTitle,
    required this.userId,
    required this.localPath,
    required this.duration,
    required this.fileSize,
    required this.createdAt,
    required this.expiresAt,
    required this.isUploaded,
    this.uploadUrl,
    this.uploadedAt,
    required this.status,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'meetingId': meetingId,
      'meetingTitle': meetingTitle,
      'userId': userId,
      'localPath': localPath,
      'duration': duration,
      'fileSize': fileSize,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isUploaded': isUploaded,
      'uploadUrl': uploadUrl,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
      'status': status,
    };
  }

  // Create from Firestore document
  factory RecordingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordingModel(
      id: data['id'] ?? doc.id,
      meetingId: data['meetingId'] ?? '',
      meetingTitle: data['meetingTitle'] ?? 'Unknown Meeting',
      userId: data['userId'] ?? '',
      localPath: data['localPath'] ?? '',
      duration: data['duration'] ?? 0,
      fileSize: data['fileSize'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isUploaded: data['isUploaded'] ?? false,
      uploadUrl: data['uploadUrl'],
      uploadedAt: data['uploadedAt'] != null 
          ? (data['uploadedAt'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'completed',
    );
  }

  // Format duration for display
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Format file size for display
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Check if recording is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Check if recording is available locally
  bool get isAvailableLocally {
    // For local recordings, check if file exists
    final file = File(localPath);
    return file.existsSync();
  }

  RecordingModel copyWith({
    String? id,
    String? meetingId,
    String? meetingTitle,
    String? userId,
    String? localPath,
    int? duration,
    int? fileSize,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUploaded,
    String? uploadUrl,
    DateTime? uploadedAt,
    String? status,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      userId: userId ?? this.userId,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUploaded: isUploaded ?? this.isUploaded,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
    );
  }
}