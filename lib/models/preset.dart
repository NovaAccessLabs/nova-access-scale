import 'package:flutter/foundation.dart';

/// A saved target weight the user can reuse.
///
/// Per PRD, a preset contains only a [name] and a [targetWeightGrams] — no
/// recipes, steps, or other metadata. Target weights are always whole grams of
/// at least 1.
@immutable
class Preset {
  const Preset({required this.name, required this.targetWeightGrams})
    : assert(targetWeightGrams >= 1, 'Target weight must be at least 1 gram');

  final String name;
  final int targetWeightGrams;

  Preset copyWith({String? name, int? targetWeightGrams}) {
    return Preset(
      name: name ?? this.name,
      targetWeightGrams: targetWeightGrams ?? this.targetWeightGrams,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'targetWeightGrams': targetWeightGrams,
  };

  /// Builds a [Preset] from stored JSON. Returns null if the data is malformed,
  /// so a single corrupt entry cannot crash loading the whole list.
  static Preset? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final target = json['targetWeightGrams'];
    if (name is! String || name.trim().isEmpty) return null;
    if (target is! int || target < 1) return null;
    return Preset(name: name, targetWeightGrams: target);
  }

  @override
  bool operator ==(Object other) =>
      other is Preset &&
      other.name == name &&
      other.targetWeightGrams == targetWeightGrams;

  @override
  int get hashCode => Object.hash(name, targetWeightGrams);

  @override
  String toString() => 'Preset($name, ${targetWeightGrams}g)';
}
