class SharedFile {
  const SharedFile({
    required this.id,
    required this.teamId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final String id;
  final String teamId;
  final String fileName;
  final String filePath;
  final String fileSize;
  final String fileType;
  final DateTime uploadedAt;
  final String uploadedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'file_type': fileType,
        'uploaded_at': uploadedAt.millisecondsSinceEpoch,
        'uploaded_by': uploadedBy,
      };

  factory SharedFile.fromMap(Map<String, dynamic> m) => SharedFile(
        id: m['id'] as String,
        teamId: m['team_id'] as String,
        fileName: m['file_name'] as String,
        filePath: m['file_path'] as String,
        fileSize: m['file_size'] as String,
        fileType: m['file_type'] as String,
        uploadedAt: DateTime.fromMillisecondsSinceEpoch(m['uploaded_at'] as int),
        uploadedBy: m['uploaded_by'] as String,
      );
}
