import 'package:equatable/equatable.dart';

/// Model for upload response
class UploadModel extends Equatable {
  const UploadModel({
    required this.url,
    required this.fileName,
    required this.expiresAt,
    this.fileSizeBytes = 0,
  });

  final String url;
  final String fileName;
  final DateTime expiresAt;
  final int fileSizeBytes;

  @override
  List<Object?> get props => [url, fileName, expiresAt, fileSizeBytes];

  UploadModel copyWith({
    String? url,
    String? fileName,
    DateTime? expiresAt,
    int? fileSizeBytes,
  }) {
    return UploadModel(
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      expiresAt: expiresAt ?? this.expiresAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'expiresAt': expiresAt.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory UploadModel.fromJson(Map<String, dynamic> json) {
    return UploadModel(
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }

  /// Create from URL string (Litterbox returns plain URL)
  factory UploadModel.fromUrl(
    String url,
    String fileName, [
    int fileSizeBytes = 0,
  ]) {
    return UploadModel(
      url: url,
      fileName: fileName,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
      fileSizeBytes: fileSizeBytes,
    );
  }
}
