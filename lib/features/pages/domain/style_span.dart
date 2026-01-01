import 'package:equatable/equatable.dart';

enum StyleType { bold, italic, underline, color }

class StyleSpan extends Equatable {
  final int start;
  final int end;
  final StyleType type;
  final String? value; // For handling colors (e.g., "red", "#FF0000")

  const StyleSpan({
    required this.start,
    required this.end,
    required this.type,
    this.value,
  });

  Map<String, dynamic> toMap() {
    return {'start': start, 'end': end, 'type': type.name, 'value': value};
  }

  factory StyleSpan.fromMap(Map<String, dynamic> map) {
    return StyleSpan(
      start: map['start'] as int,
      end: map['end'] as int,
      type: StyleType.values.firstWhere((e) => e.name == map['type']),
      value: map['value'] as String?,
    );
  }

  @override
  List<Object?> get props => [start, end, type, value];
}
