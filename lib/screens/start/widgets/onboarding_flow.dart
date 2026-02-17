import 'package:flutter/material.dart';
import '../../../models/onboarding_state.dart';
import 'question_card.dart';

/// 대화형 온보딩 UI
///
/// Phase 1: 인사 → Q1(출퇴근) → Q2(앵커 타임) → Q3(컨디션) → 로딩
/// 각 질문은 이전 답변 후 애니메이션으로 순차 표시.
class OnboardingFlow extends StatefulWidget {
  final OnboardingState state;
  final String defaultAnchorTime;
  final String defaultCommuteType;
  final ValueChanged<String> onCommuteSelected;
  final ValueChanged<String> onAnchorConfirmed;
  final ValueChanged<UserCondition> onConditionSelected;

  const OnboardingFlow({
    super.key,
    required this.state,
    required this.defaultAnchorTime,
    required this.defaultCommuteType,
    required this.onCommuteSelected,
    required this.onAnchorConfirmed,
    required this.onConditionSelected,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(OnboardingFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.phase != oldWidget.state.phase) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인사 메시지 (항상 표시)
          _GreetingBubble(greeting: widget.state.greeting),
          const SizedBox(height: 20),

          // Q1: 출퇴근 타입
          _buildCommuteQuestion(),

          // Q2: 앵커 타임 (Q1 답변 후)
          _buildAnchorTimeQuestion(),

          // Q3: 컨디션 (Q2 답변 후)
          _buildConditionQuestion(),

          // 로딩 상태
          if (widget.state.phase == OnboardingPhase.loading)
            _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildCommuteQuestion() {
    if (widget.state.commuteType == null) {
      return _AnimatedEntry(
        child: QuestionCard(
          question: '오늘은 어디서 일하시나요?',
          options: [
            QuestionOption(
              icon: Icons.business,
              label: '출근',
              value: 'office',
              isDefault: widget.defaultCommuteType == 'office',
            ),
            QuestionOption(
              icon: Icons.home,
              label: '재택',
              value: 'home',
              isDefault: widget.defaultCommuteType == 'home',
            ),
          ],
          onSelected: widget.onCommuteSelected,
        ),
      );
    }

    return _AnimatedEntry(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnsweredChip(
          icon:
              widget.state.commuteType == 'office' ? Icons.business : Icons.home,
          label: widget.state.commuteType == 'office' ? '출근' : '재택',
        ),
      ),
    );
  }

  Widget _buildAnchorTimeQuestion() {
    if (widget.state.commuteType == null) return const SizedBox.shrink();

    if (widget.state.anchorTime == null) {
      return _AnimatedEntry(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _AnchorTimeQuestion(
            defaultTime: widget.defaultAnchorTime,
            commuteType: widget.state.commuteType!,
            onConfirmed: widget.onAnchorConfirmed,
          ),
        ),
      );
    }

    return _AnimatedEntry(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnsweredChip(
          icon: Icons.flag_outlined,
          label:
              '${widget.state.commuteType == "office" ? "출근" : "업무 시작"} ${widget.state.anchorTime}',
        ),
      ),
    );
  }

  Widget _buildConditionQuestion() {
    if (widget.state.anchorTime == null) return const SizedBox.shrink();

    if (widget.state.condition == null) {
      return _AnimatedEntry(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: QuestionCard(
            question: '오늘 컨디션은 어떠세요?',
            options: [
              const QuestionOption(label: '😊 좋음', value: 'good'),
              const QuestionOption(label: '😐 보통', value: 'normal'),
              const QuestionOption(label: '😴 피곤', value: 'tired'),
            ],
            onSelected: (v) {
              final condition =
                  UserCondition.values.firstWhere((c) => c.name == v);
              widget.onConditionSelected(condition);
            },
          ),
        ),
      );
    }

    return _AnimatedEntry(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnsweredChip(
          label: widget.state.condition!.label,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);
    return _AnimatedEntry(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '맞춤 루틴을 준비하고 있어요...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인사 메시지 버블
class _GreetingBubble extends StatelessWidget {
  final String greeting;

  const _GreetingBubble({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            '💬',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greeting,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 앵커 타임 질문 위젯 (맞아요/변경하기 + TimePicker)
class _AnchorTimeQuestion extends StatelessWidget {
  final String defaultTime;
  final String commuteType;
  final ValueChanged<String> onConfirmed;

  const _AnchorTimeQuestion({
    required this.defaultTime,
    required this.commuteType,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = commuteType == 'office' ? '출근 시간' : '업무 시작 시간';

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
              '$label이 $defaultTime 맞나요?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _buildButton(
                  context,
                  label: '맞아요 ✓',
                  isPrimary: true,
                  onTap: () => onConfirmed(defaultTime),
                ),
                _buildButton(
                  context,
                  label: '변경하기',
                  isPrimary: false,
                  onTap: () => _showTimePicker(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isPrimary
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              color: isPrimary
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final parts = defaultTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 9,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onConfirmed(formatted);
    }
  }
}

/// 항목이 나타날 때 페이드+슬라이드 애니메이션 적용
class _AnimatedEntry extends StatefulWidget {
  final Widget child;

  const _AnimatedEntry({required this.child});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
