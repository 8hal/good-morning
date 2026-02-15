/// 출퇴근 형태
enum CommuteType {
  home,
  office;

  String get label {
    switch (this) {
      case CommuteType.home:
        return '재택';
      case CommuteType.office:
        return '출근';
    }
  }

  String toJson() => name;

  static CommuteType fromJson(String value) =>
      CommuteType.values.firstWhere((e) => e.name == value);
}

/// 블록 종료 후 시간 체감
enum TimeFeel {
  short_,
  ok,
  long_;

  String get label {
    switch (this) {
      case TimeFeel.short_:
        return '짧았다';
      case TimeFeel.ok:
        return '적당';
      case TimeFeel.long_:
        return '길었다';
    }
  }

  String toJson() {
    switch (this) {
      case TimeFeel.short_:
        return 'short';
      case TimeFeel.ok:
        return 'ok';
      case TimeFeel.long_:
        return 'long';
    }
  }

  static TimeFeel fromJson(String value) {
    switch (value) {
      case 'short':
        return TimeFeel.short_;
      case 'ok':
        return TimeFeel.ok;
      case 'long':
        return TimeFeel.long_;
      default:
        throw ArgumentError('Unknown TimeFeel: $value');
    }
  }
}

/// 블록 종료 방식
enum EndedBy {
  auto_,
  manual;

  String toJson() {
    switch (this) {
      case EndedBy.auto_:
        return 'auto';
      case EndedBy.manual:
        return 'manual';
    }
  }

  static EndedBy fromJson(String value) {
    switch (value) {
      case 'auto':
        return EndedBy.auto_;
      case 'manual':
        return EndedBy.manual;
      default:
        throw ArgumentError('Unknown EndedBy: $value');
    }
  }
}

/// Anchor 설정 출처
enum AnchorSource {
  manual,
  calendarSelected;

  String toJson() {
    switch (this) {
      case AnchorSource.manual:
        return 'manual';
      case AnchorSource.calendarSelected:
        return 'calendar_selected';
    }
  }

  static AnchorSource fromJson(String value) {
    switch (value) {
      case 'manual':
        return AnchorSource.manual;
      case 'calendar_selected':
        return AnchorSource.calendarSelected;
      default:
        throw ArgumentError('Unknown AnchorSource: $value');
    }
  }
}
