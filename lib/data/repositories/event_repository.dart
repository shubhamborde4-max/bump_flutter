import 'package:bump/data/models/event_model.dart';

abstract class EventRepository {
  Future<List<Event>> getEvents();

  Future<Event?> getEvent(String id);

  Future<Event> createEvent(Event event);

  Future<void> updateEvent(Event event);

  Future<void> deleteEvent(String id);

  Future<void> setActiveEvent(String id);
}
