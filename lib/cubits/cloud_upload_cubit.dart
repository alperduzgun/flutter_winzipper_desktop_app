import 'package:flutter_bloc/flutter_bloc.dart';
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
      final fileName = filePath.split('/').last;
      emit(CloudUploadInProgress(fileName, progress: 0.0));

      final result = await _uploadService.uploadFile(
        filePath,
        onProgress: (progress) {
          emit(CloudUploadInProgress(fileName, progress: progress));
        },
      );

      if (result.success) {
        emit(CloudUploadSuccess(result.url!, fileName));
      } else {
        emit(CloudUploadFailure(result.error ?? 'Unknown error'));
      }
    } catch (e) {
      emit(CloudUploadFailure('Upload failed: ${e.toString()}'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(CloudUploadInitial());
  }
}
