import 'package:equatable/equatable.dart';
import '../data/model/cloud/upload_model.dart';

/// Base class for CloudUpload states
abstract class CloudUploadState extends Equatable {
  const CloudUploadState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CloudUploadInitial extends CloudUploadState {
  const CloudUploadInitial();
}

/// Loading/uploading state
class CloudUploadInProgress extends CloudUploadState {
  const CloudUploadInProgress({
    required this.fileName,
    required this.progress,
  });

  final String fileName;
  final double progress;

  @override
  List<Object?> get props => [fileName, progress];
}

/// Success state
class CloudUploadSuccess extends CloudUploadState {
  const CloudUploadSuccess({
    required this.uploadModel,
  });

  final UploadModel uploadModel;

  @override
  List<Object?> get props => [uploadModel];
}

/// Failure state
class CloudUploadFailure extends CloudUploadState {
  const CloudUploadFailure({
    required this.error,
  });

  final String error;

  @override
  List<Object?> get props => [error];
}
