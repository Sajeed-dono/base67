import '../app/campaign_save.dart';

class TimerCompletion {
  const TimerCompletion._();

  /// UTC deadlines are retained across restarts. Clock rollback clamps elapsed
  /// progress to zero; a completed activity can be rewarded only once.
  static bool isDue({
    required DateTime deadlineUtc,
    required DateTime nowUtc,
  }) => !nowUtc.toUtc().isBefore(deadlineUtc.toUtc());

  static CampaignSave completeJobOnce({
    required CampaignSave save,
    required String jobId,
    required DateTime nowUtc,
  }) {
    final index = save.timerJobs.indexWhere((job) => job.id == jobId);
    if (index < 0 || save.completedActivityIds.contains(jobId)) return save;
    final job = save.timerJobs[index];
    if (job.status != 'active' ||
        job.rewardApplied ||
        !isDue(deadlineUtc: job.expectedCompletionAtUtc, nowUtc: nowUtc)) {
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
