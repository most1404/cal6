import 'package:equatable/equatable.dart';

class SubTaskModel extends Equatable {
  final String id;
  final String? reminderId;
  final String title;
  final bool isCompleted;
  final int orderIndex;

  const SubTaskModel({
    required this.id,
    this.reminderId,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  SubTaskModel copyWith({
    String? id,
    String? reminderId,
    String? title,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return SubTaskModel(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'order_index': orderIndex,
    };
  }

  factory SubTaskModel.fromMap(Map<String, dynamic> map) {
    return SubTaskModel(
      id: map['id'] as String,
      reminderId: (map['reminder_id'] ?? map['reminderId']) as String?,
      title: map['title'] as String,
      isCompleted: ((map['is_completed'] ?? map['isCompleted'] ?? 0) as int) == 1,
      orderIndex: (map['order_index'] ?? map['orderIndex'] ?? 0) as int,
    );
  }

  @override
  List<Object?> get props => [id, reminderId, title, isCompleted, orderIndex];
}
