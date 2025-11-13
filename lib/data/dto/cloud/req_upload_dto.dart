import 'package:equatable/equatable.dart';

/// Request DTO for file upload
class ReqUploadDto extends Equatable {
  const ReqUploadDto({
    required this.filePath,
    required this.fileName,
    this.retentionTime = '72h',
  });

  final String filePath;
  final String fileName;
  final String retentionTime;

  @override
  List<Object?> get props => [filePath, fileName, retentionTime];

  ReqUploadDto copyWith({
    String? filePath,
    String? fileName,
    String? retentionTime,
  }) {
    return ReqUploadDto(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      retentionTime: retentionTime ?? this.retentionTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'retentionTime': retentionTime,
    };
  }

  factory ReqUploadDto.fromJson(Map<String, dynamic> json) {
    return ReqUploadDto(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      retentionTime: json['retentionTime'] as String? ?? '72h',
    );
  }
}
