import 'package:freezed_annotation/freezed_annotation.dart';

part 'req_upload_dto.freezed.dart';
part 'req_upload_dto.g.dart';

/// Request DTO for file upload
@freezed
class ReqUploadDto with _$ReqUploadDto {
  const factory ReqUploadDto({
    required String filePath,
    required String fileName,
    @Default('72h') String retentionTime,
  }) = _ReqUploadDto;

  factory ReqUploadDto.fromJson(Map<String, dynamic> json) =>
      _$ReqUploadDtoFromJson(json);
}
