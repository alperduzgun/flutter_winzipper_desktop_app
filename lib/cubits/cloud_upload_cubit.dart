import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path_pkg;
import '../data/dto/cloud/req_upload_dto.dart';
import '../data/service/cloud_service.dart';
import 'cloud_upload_state.dart';

/// Cubit for managing cloud upload state
class CloudUploadCubit extends Cubit<CloudUploadState> {
  CloudUploadCubit(this._cloudService) : super(const CloudUploadInitial());

  final ICloudService _cloudService;

  /// Upload a file to cloud storage
  Future<void> uploadFile(String filePath) async {
    try {
      final fileName = path_pkg.basename(filePath);

      // Emit progress state
      emit(CloudUploadInProgress(
        fileName: fileName,
        progress: 0.0,
      ));

      // Create DTO
      final dto = ReqUploadDto(
        filePath: filePath,
        fileName: fileName,
      );

      // Call service
      final result = await _cloudService.uploadFile(
        dto,
        onProgress: (progress) {
          if (!isClosed) {
            emit(CloudUploadInProgress(
              fileName: fileName,
              progress: progress,
            ));
          }
        },
      );

      // Handle result
      result.fold(
        (error) {
          if (!isClosed) {
            emit(CloudUploadFailure(error: error.toString()));
          }
        },
        (uploadModel) {
          if (!isClosed) {
            emit(CloudUploadSuccess(uploadModel: uploadModel));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(CloudUploadFailure(error: e.toString()));
      }
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const CloudUploadInitial());
  }
}
