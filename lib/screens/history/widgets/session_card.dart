import 'package:flutter/material.dart';
import '../../../core/utils/datetime_utils.dart';
import '../../../models/enums.dart';
import '../../../models/session.dart';

/// 히스토리 목록의 세션 카드
/// 출퇴근 타입, 시간, 소요 시간 표시
class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  String get _commuteIcon {
    return session.commuteType == CommuteType.home ? '🏠' : '🏢';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateTimeUtils.formatTime(session.startAt);
    final endTime = session.endAt != null
        ? DateTimeUtils.formatTime(session.endAt!)
        : '진행 중';

    final duration = session.endAt != null
        ? DateTimeUtils.formatDuration(
            session.endAt!.difference(session.startAt))
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 출퇴근 타입
              Row(
                children: [
                  Text(_commuteIcon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    session.commuteType.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 시간 정보
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '$startTime → $endTime',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($duration)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // 상세보기 안내
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '상세보기',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
