import 'package:flutter_test/flutter_test.dart';
import 'package:good_morning/models/enums.dart';

void main() {
  group('CommuteType', () {
    test('fromJson - 정상 파싱', () {
      expect(CommuteType.fromJson('home'), CommuteType.home);
      expect(CommuteType.fromJson('office'), CommuteType.office);
    });

    test('fromJson - 알 수 없는 값은 office 기본값', () {
      expect(CommuteType.fromJson('unknown'), CommuteType.office);
      expect(CommuteType.fromJson(''), CommuteType.office);
    });

    test('toJson - 직렬화', () {
      expect(CommuteType.home.toJson(), 'home');
      expect(CommuteType.office.toJson(), 'office');
    });

    test('label - 한국어 레이블', () {
      expect(CommuteType.home.label, '재택');
      expect(CommuteType.office.label, '출근');
    });
  });

  group('TimeFeel', () {
    test('fromJson - 정상 파싱', () {
      expect(TimeFeel.fromJson('short'), TimeFeel.short_);
      expect(TimeFeel.fromJson('ok'), TimeFeel.ok);
      expect(TimeFeel.fromJson('long'), TimeFeel.long_);
    });

    test('fromJson - 알 수 없는 값은 에러', () {
      expect(
        () => TimeFeel.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson - 직렬화', () {
      expect(TimeFeel.short_.toJson(), 'short');
      expect(TimeFeel.ok.toJson(), 'ok');
      expect(TimeFeel.long_.toJson(), 'long');
    });

    test('label - 한국어 레이블', () {
      expect(TimeFeel.short_.label, '짧았다');
      expect(TimeFeel.ok.label, '적당');
      expect(TimeFeel.long_.label, '길었다');
    });
  });

  group('EndedBy', () {
    test('fromJson - 정상 파싱', () {
      expect(EndedBy.fromJson('auto'), EndedBy.auto_);
      expect(EndedBy.fromJson('manual'), EndedBy.manual);
    });

    test('fromJson - 알 수 없는 값은 에러', () {
      expect(
        () => EndedBy.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson - 직렬화', () {
      expect(EndedBy.auto_.toJson(), 'auto');
      expect(EndedBy.manual.toJson(), 'manual');
    });
  });

  group('AnchorSource', () {
    test('fromJson - 정상 파싱', () {
      expect(AnchorSource.fromJson('manual'), AnchorSource.manual);
      expect(AnchorSource.fromJson('calendar_selected'),
          AnchorSource.calendarSelected);
    });

    test('fromJson - 알 수 없는 값은 에러', () {
      expect(
        () => AnchorSource.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson - 직렬화', () {
      expect(AnchorSource.manual.toJson(), 'manual');
      expect(AnchorSource.calendarSelected.toJson(), 'calendar_selected');
    });
  });
}
