enum ProblemCategory {
  noSignal,
  weakSignal,
  callDropping,
  mobileInternetUnavailable,
  slowInternet,
  fourGUnavailable,
  networkCongestion,
  other;

  String get label {
    switch (this) {
      case ProblemCategory.noSignal:
        return 'No signal';
      case ProblemCategory.weakSignal:
        return 'Weak signal';
      case ProblemCategory.callDropping:
        return 'Call dropping';
      case ProblemCategory.mobileInternetUnavailable:
        return 'Mobile internet unavailable';
      case ProblemCategory.slowInternet:
        return 'Slow internet';
      case ProblemCategory.fourGUnavailable:
        return '4G unavailable';
      case ProblemCategory.networkCongestion:
        return 'Network congestion';
      case ProblemCategory.other:
        return 'Other';
    }
  }
}

enum ReportStatus {
  pending,
  underReview,
  inProgress,
  resolved,
  closed;

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  static ReportStatus fromKey(String key) {
    return ReportStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => ReportStatus.pending,
    );
  }
}
