import 'dart:async' show StreamController, Future;
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// A service class to handle audio recording and playback functionality
/// using the `record` and `just_audio` packages.
class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger _logger = Logger();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  DateTime? _recordingStartTime;

  // Stream controllers for UI updates
  final StreamController<Duration> _recordingDurationController =
  StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _playbackStateController =
  StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _playbackPositionController =
  StreamController<Duration>.broadcast();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  Stream<Duration> get recordingDurationStream => _recordingDurationController.stream;
  Stream<PlayerState> get playbackStateStream => _playbackStateController.stream;
  Stream<Duration> get playbackPositionStream => _playbackPositionController.stream;

  Duration? get recordingDuration {
    if (_recordingStartTime != null) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return null;
  }

  /// Initialize the audio service, check and request necessary permissions.
  Future<void> init() async {
    try {
      // Request microphone permission
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      // Request storage permission (only explicitly needed for older Android APIs)
      if (Platform.isAndroid && microphoneStatus.isGranted) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
      }

      // Setup audio player listeners
      _setupAudioPlayerListeners();

      _logger.i("AudioRecordingService initialized successfully");
    } catch (e) {
      _logger.e("Error initializing AudioRecordingService: $e");
      rethrow;
    }
  }

  /// Sets up listeners for the audio player state and position streams.
  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((PlayerState state) {
      _isPlaying = state.playing;
      _playbackStateController.add(state);
    });

    _audioPlayer.positionStream.listen((Duration position) {
      _playbackPositionController.add(position);
    });
  }

  /// Checks if all necessary permissions (microphone and storage) are granted.
  Future<bool> _checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      _logger.e("Microphone permission not granted");
      return false;
    }

    // Storage permission check, primarily for compatibility on older Android
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        _logger.e("Storage permission not granted");
        return false;
      }
    }

    return true;
  }

  /// Gets or creates the directory where recordings will be stored.
  Future<String> _getRecordingsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory("${directory.path}/AudioMeetings/Recordings");

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    return recordingsDir.path;
  }

  /// Start recording with high quality settings.
  Future<bool> startRecording(String meetingId) async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _logger.e("Required permissions not granted");
        return false;
      }

      if (_isRecording) {
        _logger.w("Recording already in progress");
        return false;
      }

      final recordingsPath = await _getRecordingsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _currentRecordingPath = "$recordingsPath/${meetingId}_$timestamp.m4a";

      // High quality recording configuration
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC format for better compatibility
        bitRate: 128000, // 128 kbps for good quality
        sampleRate: 44100, // CD quality sample rate
        numChannels: 1, // Mono for smaller file size
      );

      await _audioRecorder.start(config, path: _currentRecordingPath);

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      // Start duration timer
      _startRecordingTimer();

      _logger.i("Recording started: $_currentRecordingPath");
      return true;
    } catch (e) {
      _logger.e("Error starting recording: $e");
      return false;
    }
  }

  /// Updates the recording duration stream every second while recording is active.
  void _startRecordingTimer() {
    Future.doWhile(() async {
      if (_isRecording && _recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        _recordingDurationController.add(duration);
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }
      return false;
    });
  }

  /// Stop recording and return file path.
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        _logger.w("No recording to stop");
        return null;
      }

      final path = await _audioRecorder.stop();

      _isRecording = false;
      _recordingStartTime = null;

      _logger.i("Recording stopped: $path");
      return path;
    } catch (e) {
      _logger.e("Error stopping recording: $e");
      return null;
    }
  }

  /// Pause recording.
  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.pause();
        _logger.i("Recording paused");
      }
    } catch (e) {
      _logger.e("Error pausing recording: $e");
    }
  }

  /// Resume recording.
  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.resume();
        _logger.i("Recording resumed");
      }
    } catch (e) {
      _logger.e("Error resuming recording: $e");
    }
  }

  /// Play recorded audio from a given file path.
  Future<void> playRecording(String filePath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      _logger.i("Playback started: $filePath");
    } catch (e) {
      _logger.e("Error playing recording: $e");
      rethrow;
    }
  }

  /// Pause playback.
  Future<void> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      _logger.i("Playback paused");
    } catch (e) {
      _logger.e("Error pausing playback: $e");
    }
  }

  /// Resume playback.
  Future<void> resumePlayback() async {
    try {
      await _audioPlayer.play();
      _logger.i("Playback resumed");
    } catch (e) {
      _logger.e("Error resuming playback: $e");
    }
  }

  /// Stop playback.
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _logger.i("Playback stopped");
    } catch (e) {
      _logger.e("Error stopping playback: $e");
    }
  }

  /// Seek to specific position.
  Future<void> seekPlayback(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _logger.e("Error seeking playback: $e");
    }
  }

  /// Get the duration of a recording file.
  Future<Duration?> getRecordingDuration(String filePath) async {
    try {
      final audioSource = AudioSource.file(filePath);
      // setAudioSource loads the file and allows duration to be accessed
      await _audioPlayer.setAudioSource(audioSource, preload: true);
      final duration = _audioPlayer.duration;
      await _audioPlayer.setAudioSource(); // Clear the source
      return duration;
    } catch (e) {
      _logger.e("Error getting recording duration: $e");
      return null;
    }
  }

  /// Cancel recording & delete the file.
  Future<void> cancelRecording() async {
    try {
      // 1. Stop the active recording process
      if (_isRecording) {
        // Stop the recording to ensure the file is closed/finalized
        await _audioRecorder.stop();
      }

      // 2. Safely check for and delete the file
      // FIX: Use a local variable to safely handle the nullable path
      final pathToDelete = _currentRecordingPath;
      if (pathToDelete != null) {
        final file = File(pathToDelete);
        if (await file.exists()) {
          await file.delete();
          _logger.i("Recording canceled & deleted: $pathToDelete");
        }
      }

      // 3. Reset internal state
      _currentRecordingPath = null;
      _isRecording = false;
      _recordingStartTime = null;

    } catch (e) {
      _logger.e("Error canceling recording: $e");
    }
  }

  /// List all recordings sorted by modification date (newest first).
  Future<List<FileSystemEntity>> getAllRecordings() async {
    try {
      final dir = await _getRecordingsDirectory();
      final directory = Directory(dir);

      if (!await directory.exists()) return [];

      final files = await directory.list().toList();

      // Filter audio files
      final audioFiles = files.where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.m4a') || path.endsWith('.aac') || path.endsWith('.mp3');
      }).toList();

      // Sort by modification date (newest first)
      audioFiles.sort((a, b) {
        // Cast to File to access statSync, assuming only files are returned after filtering
        final statA = (a as File).statSync();
        final statB = (b as File).statSync();
        return statB.modified.compareTo(statA.modified);
      });

      return audioFiles;
    } catch (e) {
      _logger.e("Error getting recordings: $e");
      return [];
    }
  }

  /// Delete a recording file from the file system.
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i("Recording deleted: $filePath");
        return true;
      }
      return false;
    } catch (e) {
      _logger.e("Error deleting recording: $e");
      return false;
    }
  }

  /// Cleanup resources: stop recording/playback and close streams.
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      if (_isPlaying) {
        await stopPlayback();
      }

      await _audioRecorder.dispose();
      await _audioPlayer.dispose();
      await _recordingDurationController.close();
      await _playbackStateController.close();
      await _playbackPositionController.close();

      _logger.i("AudioRecordingService disposed");
    } catch (e) {
      _logger.e("Error disposing AudioRecordingService: $e");
    }
  }
}