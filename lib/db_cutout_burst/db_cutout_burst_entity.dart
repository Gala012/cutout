class CutoutMode {
  static const String trim = 'trim';
  static const String shape = 'shape';
  static const String edgeText = 'edge_text';
  static const String portrait = 'portrait';
}
class CutoutHistory {
  final int? id;
  final String resultPath;
  final String thumbnailPath;
  final String cutoutMode;
  final String createdAt;
  const CutoutHistory({
    this.id,
    required this.resultPath,
    required this.thumbnailPath,
    required this.cutoutMode,
    required this.createdAt,
  });
  factory CutoutHistory.fromMap(Map<String, dynamic> map) {
    return CutoutHistory(
      id: map['id'] as int?,
      resultPath: map['result_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String,
      cutoutMode: map['cutout_mode'] as String,
      createdAt: map['created_at'] as String,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'result_path': resultPath,
      'thumbnail_path': thumbnailPath,
      'cutout_mode': cutoutMode,
      'created_at': createdAt,
    };
  }
}
