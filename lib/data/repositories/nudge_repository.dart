import 'package:bump/data/models/nudge_model.dart';

abstract class NudgeRepository {
  Future<List<Nudge>> getNudges({String? prospectId});

  Future<Nudge> createNudge(Nudge nudge);

  Future<void> updateNudgeStatus(String id, String status);
}
