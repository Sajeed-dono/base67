import '../app/campaign_save.dart';

class TimerCompletion {
  const TimerCompletion._();

  static bool canApply({
    required String id,
    required String status,
    required Set<String> completedIds,
    bool rewardApplied = false,
  }) => status == 'active' && !rewardApplied && !completedIds.contains(id);

  /// UTC deadlines are retained across restarts. Clock rollback clamps elapsed
  /// progress to zero; a completed activity can be rewarded only once.
  static bool isDue({
    required DateTime deadlineUtc,
    required DateTime nowUtc,
  }) => !nowUtc.toUtc().isBefore(deadlineUtc.toUtc());

  /// Shared by legacy saves and the unwired progression service. The caller
  /// commits the effect and receipt in the same state transition.
  static bool canComplete({
    required String id,
    required String status,
    required Set<String> completedIds,
    required DateTime? deadlineUtc,
    required DateTime nowUtc,
    bool rewardApplied = false,
  }) =>
      canApply(
        id: id,
        status: status,
        completedIds: completedIds,
        rewardApplied: rewardApplied,
      ) &&
      deadlineUtc != null &&
      isDue(deadlineUtc: deadlineUtc, nowUtc: nowUtc);

  static DateTime effectiveUtc(DateTime nowUtc, DateTime? lastObservedUtc) {
    final now = nowUtc.toUtc();
    return lastObservedUtc != null && now.isBefore(lastObservedUtc.toUtc())
        ? lastObservedUtc.toUtc()
        : now;
  }

  static CampaignSave completeJobOnce({
    required CampaignSave save,
    required String jobId,
    required DateTime nowUtc,
  }) {
    final index = save.timerJobs.indexWhere((job) => job.id == jobId);
    if (index < 0 || save.completedActivityIds.contains(jobId)) return save;
    final job = save.timerJobs[index];
    if (!canComplete(
      id: job.id,
      status: job.status,
      completedIds: save.completedActivityIds,
      deadlineUtc: job.expectedCompletionAtUtc,
      nowUtc: nowUtc,
      rewardApplied: job.rewardApplied,
    )) {
      return save;
    }
    final updatedJobs = [...save.timerJobs];
    updatedJobs[index] = TimerJobSave(
      id: job.id,
      category: job.category,
      startedAtUtc: job.startedAtUtc,
      expectedCompletionAtUtc: job.expectedCompletionAtUtc,
      status: 'completed',
      rewardApplied: true,
      targetId: job.targetId,
      assignedCrewRole: job.assignedCrewRole,
    );
    return save.copyWith(
      completedActivityIds: {...save.completedActivityIds, jobId},
      timerJobs: updatedJobs,
    );
  }

  static CampaignSave completeOnce(CampaignSave save, String activityId) {
    if (save.completedActivityIds.contains(activityId)) return save;
    return save.copyWith(
      completedActivityIds: {...save.completedActivityIds, activityId},
    );
  }
}
