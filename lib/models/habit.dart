import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  HiveList<CompletedDay>? completedDays;

  @HiveField(2)
  int id = DateTime.now().millisecondsSinceEpoch;
}

@HiveType(typeId: 1)
class CompletedDay extends HiveObject {
  @HiveField(0)
  late DateTime date;

  CompletedDay({required this.date});
}