import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as path_pkg;
import '../../core/types/data_exception.dart';
import '../../core/types/typedefs.dart';
import '../dto/cloud/req_upload_dto.dart';
import '../model/cloud/upload_model.dart';
import '../repo/cloud_repo.dart';

/// Service interface for cloud operations
abstract class ICloudService {
  /// Upload file to cloud and return model
  AsyncRes<UploadModel> uploadFile(
    ReqUploadDto dto, {
    Function(double progress)? onProgress,
  });
}

/// Implementation of cloud service with business logic
class CloudService implements ICloudService {
  const CloudService(this._cloudRepo);

  final ICloudRepo _cloudRepo;

  @override
  AsyncRes<UploadModel> uploadFile(
    ReqUploadDto dto, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // Upload file and get URL
      final url = await _cloudRepo.uploadFile(dto, onProgress: onProgress);

      // Get file size
      final file = File(dto.filePath);
      final fileSize = await file.exists() ? await file.length() : 0;

      // Create model
      final model = UploadModel.fromUrl(url, dto.fileName, fileSize);

      return right(model);
    } catch (e, stackTrace) {
      return left(Err(e, stackTrace));
    }
  }

  /// Helper method to create DTO from file path
  static ReqUploadDto createUploadDto(String filePath) {
    final fileName = path_pkg.basename(filePath);
    return ReqUploadDto(
      filePath: filePath,
      fileName: fileName,
    );
  }
}
