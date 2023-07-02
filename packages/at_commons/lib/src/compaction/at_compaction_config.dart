@Deprecated('Moved the class to at_persistence_spec package')
class AtCompactionConfig {
  // -1 indicates storing for ever
  int sizeInKB = -1;
  // -1 indicates storing for ever
  int timeInDays = -1;
  // Percentage of logs to compact when the condition is met
  int? compactionPercentage;
  // Frequency interval in which the logs are compacted
  int? compactionFrequencyMins;

  AtCompactionConfig(this.sizeInKB, this.timeInDays, this.compactionPercentage,
      this.compactionFrequencyMins);

  bool timeBasedCompaction() {
    return timeInDays != -1;
  }

  bool sizeBasedCompaction() {
    return sizeInKB != -1;
  }
}
