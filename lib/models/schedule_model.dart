/// Schedule Model matching class_timetables
library;

class ScheduleModel {
  final String classId;
  final int dayIndex;
  final int slotIndex;
  final String course;
  final String professor;
  final String room;
  final bool isLab;
  final int? batchNumber;
  final String? labId;

  ScheduleModel({
    required this.classId,
    required this.dayIndex,
    required this.slotIndex,
    required this.course,
    required this.professor,
    required this.room,
    this.isLab = false,
    this.batchNumber,
    this.labId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      classId: json['class_id']?.toString() ?? '',
      dayIndex: json['day_index'] ?? 0,
      slotIndex: json['slot_index'] ?? 0,
      course: json['course'] ?? '',
      professor: json['professor'] ?? '',
      room: json['room'] ?? '',
      isLab: json['is_lab'] ?? false,
      batchNumber: json['batch_number'],
      labId: json['lab_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'day_index': dayIndex,
      'slot_index': slotIndex,
      'course': course,
      'professor': professor,
      'room': room,
      'is_lab': isLab,
      'batch_number': batchNumber,
      'lab_id': labId,
    };
  }

  // Helper to get time range string based on slot index
  // Matches web: ['09:10-10:10','10:10-11:10','11:10-12:10','12:10-01:10','02:20-03:20','03:20-04:20']
  String get timeRange {
    const slots = [
      '09:10 - 10:10',
      '10:10 - 11:10',
      '11:10 - 12:10',
      '12:10 - 01:10',
      '02:20 - 03:20',
      '03:20 - 04:20',
    ];
    if (slotIndex >= 0 && slotIndex < slots.length) {
      return slots[slotIndex];
    }
    return '';
  }
}
