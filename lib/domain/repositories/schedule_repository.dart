import '../models/course.dart';
import '../models/schedule.dart';
import '../models/schedule_import.dart';

abstract interface class ScheduleRepository {
  Future<List<Schedule>> getSchedules();

  Future<Schedule?> getSchedule(String id);

  Future<List<Course>> getCourses(String scheduleId);

  Future<String?> getSelectedScheduleId();

  Future<Schedule?> getSelectedSchedule();

  Future<void> selectSchedule(String? scheduleId);

  Future<Schedule> importSchedule(ScheduleImport data);

  Future<void> updateSchedule(Schedule schedule);

  Future<void> updateCourse(Course course);

  Future<void> deleteSchedule(String scheduleId);
}
