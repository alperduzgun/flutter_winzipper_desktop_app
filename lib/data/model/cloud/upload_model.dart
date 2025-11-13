import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_model.freezed.dart';
part 'upload_model.g.dart';

/// Model for upload response
@freezed
class UploadModel with _$UploadModel {
  const factory UploadModel({
    required String url,
    required String fileName,
    required DateTime expiresAt,
    @Default(0) int fileSizeBytes,
  }) = _UploadModel;

  factory UploadModel.fromJson(Map<String, dynamic> json) =>
      _$UploadModelFromJson(json);

  /// Create from URL string (Litterbox returns plain URL)
  factory UploadModel.fromUrl(String url, String fileName,
      [int fileSizeBytes = 0]) {
    return UploadModel(
      url: url,
      fileName: fileName,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
      fileSizeBytes: fileSizeBytes,
    );
  }
}
