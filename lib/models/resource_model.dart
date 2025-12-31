/// Resource Model
class ResourceModel {
  final int id;
  final String title;
  final String description;
  final String subject;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final String uploaderName;
  final String uploaderRole;
  final String? department;
  final int? semester;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploaderRole,
    this.department,
    this.semester,
    required this.isApproved,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      uploadedBy: json['uploaded_by'] ?? '',
      uploaderName: json['uploader_name'] ?? 'Unknown',
      uploaderRole: json['uploader_role'] ?? 'student',
      department: json['department'],
      semester: json['semester'],
      isApproved: json['is_approved'] ?? false,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'uploader_name': uploaderName,
      'uploader_role': uploaderRole,
      'department': department,
      'semester': semester,
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
