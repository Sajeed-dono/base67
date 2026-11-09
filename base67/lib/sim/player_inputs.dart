class ScheduledEvent {
  const ScheduledEvent(this.id, this.eventId, this.atHour);
  final String id, eventId;
  final double atHour;
}

class PlayerInputs {
  PlayerInputs({
    Iterable<String> disabledLoads = const [],
    this.heaterSetPoint,
    this.shelter = false,
    this.cleanPanels = false,
    this.repairFacilityId,
    this.resume = false,
    this.crewAvailableForActions = true,
    Iterable<ScheduledEvent> scriptedEvents = const [],
    Iterable<String> enabledRandomEvents = const [],
  }) : disabledLoads = Set.unmodifiable(disabledLoads),
       scriptedEvents = List.unmodifiable(scriptedEvents),
       enabledRandomEvents = Set.unmodifiable(enabledRandomEvents);
  final Set<String> disabledLoads, enabledRandomEvents;
  final List<ScheduledEvent> scriptedEvents;
  final double? heaterSetPoint;
  final bool shelter, cleanPanels, resume, crewAvailableForActions;
  final String? repairFacilityId;
}
