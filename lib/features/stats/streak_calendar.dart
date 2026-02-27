import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stroop_game/core/theme/app_colors.dart';

/// A monthly calendar that highlights days on which the user played.
/// [playedDates] — list of ISO date strings (YYYY-MM-DD)
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({
    super.key,
    required this.playedDates,
    required this.isDark,
  });

  final List<String> playedDates;
  final bool isDark;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _focus; // current month shown

  @override
  void initState() {
    super.initState();
    _focus = DateTime(DateTime.now().year, DateTime.now().month);
  }

  bool _played(DateTime d) {
    final s =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return widget.playedDates.contains(s);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _shift(int months) {
    setState(() {
      _focus = DateTime(_focus.year, _focus.month + months);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0D1117);
    final dimColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);

    // Build the days grid
    final firstDay = DateTime(_focus.year, _focus.month, 1);
    final startOffset = (firstDay.weekday % 7); // 0=Sun
    final daysInMonth = DateTime(_focus.year, _focus.month + 1, 0).day;
    final cells = startOffset + daysInMonth;

    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '${months[_focus.month]} ${_focus.year}',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              _NavBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => _shift(-1),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 6),
              _NavBtn(
                icon: Icons.chevron_right_rounded,
                onTap: () => _shift(1),
                isDark: widget.isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
              return SizedBox(
                width: 34,
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dimColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Date grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
            ),
            itemCount: cells,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox();
              final day = i - startOffset + 1;
              final date = DateTime(_focus.year, _focus.month, day);
              final played = _played(date);
              final isToday = _isToday(date);

              Color? bgColor;
              Color numColor = textColor;

              if (isToday) {
                bgColor = AppColors.coin;
                numColor = Colors.black;
              } else if (played) {
                bgColor = AppColors.primary;
                numColor = Colors.white;
              }

              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor ?? Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: played || isToday
                        ? [
                            BoxShadow(
                              color:
                                  (isToday ? AppColors.coin : AppColors.primary)
                                      .withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: played || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: bgColor == null ? dimColor : numColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(
                color: AppColors.primary,
                label: 'Played',
                isDark: widget.isDark,
              ),
              const SizedBox(width: 16),
              _Legend(
                color: AppColors.coin,
                label: 'Today',
                isDark: widget.isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.isDark,
  });
  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
