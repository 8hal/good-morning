import 'package:flutter/material.dart';

/// 질문 카드의 개별 옵션
class QuestionOption {
  final IconData? icon;
  final String label;
  final String value;
  final bool isDefault;

  const QuestionOption({
    this.icon,
    required this.label,
    required this.value,
    this.isDefault = false,
  });
}

/// 재사용 가능한 질문 카드 위젯
///
/// 질문 텍스트 + 선택 버튼 옵션들로 구성.
/// 기본값이 있는 옵션은 테두리로 강조 표시.
class QuestionCard extends StatelessWidget {
  final String question;
  final List<QuestionOption> options;
  final ValueChanged<String> onSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  options.map((opt) => _buildOptionButton(context, opt)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, QuestionOption option) {
    final theme = Theme.of(context);
    final isDefault = option.isDefault;

    return Material(
      color: isDefault
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onSelected(option.value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isDefault
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 20,
                  color: isDefault
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                option.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isDefault ? FontWeight.w600 : FontWeight.w500,
                  color: isDefault
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 답변 완료된 질문을 작은 칩으로 표시
class AnsweredChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const AnsweredChip({
    super.key,
    this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
