import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import '../services/cloud_upload_service.dart';

/// States for cloud upload operation
abstract class CloudUploadState {}

class CloudUploadInitial extends CloudUploadState {}

class CloudUploadInProgress extends CloudUploadState {
  final double progress;
  final String fileName;

  CloudUploadInProgress(this.fileName, {this.progress = 0.0});
}

class CloudUploadSuccess extends CloudUploadState {
  final String url;
  final String fileName;

  CloudUploadSuccess(this.url, this.fileName);
}

class CloudUploadFailure extends CloudUploadState {
  final String error;

  CloudUploadFailure(this.error);
}

/// Cubit for managing cloud upload state
class CloudUploadCubit extends Cubit<CloudUploadState> {
  final CloudUploadService _uploadService;

  CloudUploadCubit(this._uploadService) : super(CloudUploadInitial());

  /// Upload file to cloud and update state
  Future<void> uploadFile(String filePath) async {
    try {
      // Use path.basename for cross-platform compatibility
      final fileName = path.basename(filePath);

      if (!isClosed) {
        emit(CloudUploadInProgress(fileName, progress: 0.0));
      }

      final result = await _uploadService.uploadFile(
        filePath,
        onProgress: (progress) {
          // Check if cubit is still active before emitting
          if (!isClosed) {
            emit(CloudUploadInProgress(fileName, progress: progress));
          }
        },
      );

      // Final state emission with closed check
      if (!isClosed) {
        if (result.success) {
          emit(CloudUploadSuccess(result.url!, fileName));
        } else {
          emit(CloudUploadFailure(result.error ?? 'Unknown error'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(CloudUploadFailure('Upload failed: ${e.toString()}'));
      }
    }
  }

  /// Reset to initial state
  void reset() {
    if (!isClosed) {
      emit(CloudUploadInitial());
    }
  }
}
