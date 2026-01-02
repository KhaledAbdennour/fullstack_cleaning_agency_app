import 'package:flutter/material.dart';


class CleaningHistoryItem {
  final int? id;
  final int cleanerId;
  final String title;
  final DateTime date;
  final String description;
  final CleaningHistoryType type;
  final int? jobId; 

  CleaningHistoryItem({
    this.id,
    required this.cleanerId,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
    this.jobId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cleaner_id': cleanerId,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'type': type.name,
      'job_id': jobId,
    };
  }

  factory CleaningHistoryItem.fromMap(Map<String, dynamic> map) {
    return CleaningHistoryItem(
      id: map['id'] as int?,
      cleanerId: map['cleaner_id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String,
      type: CleaningHistoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CleaningHistoryType.apartment,
      ),
      jobId: map['job_id'] as int?,
    );
  }
}

enum CleaningHistoryType {
  office,
  apartment,
  villa,
  house,
  commercial,
}

extension CleaningHistoryTypeExtension on CleaningHistoryType {
  String get displayName {
    switch (this) {
      case CleaningHistoryType.office:
        return 'Office Building';
      case CleaningHistoryType.apartment:
        return 'Apartment';
      case CleaningHistoryType.villa:
        return 'Villa';
      case CleaningHistoryType.house:
        return 'House';
      case CleaningHistoryType.commercial:
        return 'Commercial';
    }
  }

  IconData get icon {
    switch (this) {
      case CleaningHistoryType.office:
        return Icons.business;
      case CleaningHistoryType.apartment:
        return Icons.apartment;
      case CleaningHistoryType.villa:
        return Icons.home;
      case CleaningHistoryType.house:
        return Icons.home;
      case CleaningHistoryType.commercial:
        return Icons.store;
    }
  }

  Color get iconColor {
    switch (this) {
      case CleaningHistoryType.office:
        return Colors.blue;
      case CleaningHistoryType.apartment:
        return Colors.green;
      case CleaningHistoryType.villa:
        return Colors.purple;
      case CleaningHistoryType.house:
        return Colors.orange;
      case CleaningHistoryType.commercial:
        return Colors.teal;
    }
  }

  Color get iconBackgroundColor {
    switch (this) {
      case CleaningHistoryType.office:
        return Colors.blue.shade50;
      case CleaningHistoryType.apartment:
        return Colors.green.shade50;
      case CleaningHistoryType.villa:
        return Colors.purple.shade50;
      case CleaningHistoryType.house:
        return Colors.orange.shade50;
      case CleaningHistoryType.commercial:
        return Colors.teal.shade50;
    }
  }
}

