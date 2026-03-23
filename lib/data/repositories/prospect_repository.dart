import 'package:bump/data/models/prospect_model.dart';

abstract class ProspectRepository {
  Future<List<Prospect>> getProspects({String? eventId, String? status});

  Future<Prospect?> getProspect(String id);

  Future<Prospect> createProspect(Prospect prospect);

  Future<void> updateProspect(Prospect prospect);

  Future<void> updateProspectStatus(String id, String status);

  Future<void> deleteProspect(String id);

  Future<int> getProspectCount({String? eventId});
}
