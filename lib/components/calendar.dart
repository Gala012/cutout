import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class CalendarView extends StatelessWidget {
  final String monthTitle;
  final int daysInMonth;
  final int firstWeekdayOfMonth;
  final List<int> markedDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Function(int day) isToday;
  final int? selectedDay;
  final Function(int day)? onDaySelected;
  const CalendarView({
    super.key,
    required this.monthTitle,
    required this.daysInMonth,
    required this.firstWeekdayOfMonth,
    required this.markedDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isToday,
    this.selectedDay,
    this.onDaySelected,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 8.h),
          _buildWeekdayLabels(),
          SizedBox(height: 8.h),
          _buildGrid(),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onTap: onPreviousMonth,
          ),
          Text(
            monthTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildNavigationButton(icon: Icons.chevron_right, onTap: onNextMonth),
        ],
      ),
    );
  }
  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Icon(icon, color: Colors.white, size: 24.sp),
      ),
    );
  }
  Widget _buildWeekdayLabels() {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildGrid() {
    final totalCells = ((daysInMonth + firstWeekdayOfMonth) / 7).ceil() * 7;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final day = index - firstWeekdayOfMonth + 1;
        if (day <= 0 || day > daysInMonth) {
          return Container();
        }
        final isMarked = markedDates.contains(day);
        final isCurrent = isToday(day);
        final isSelected = selectedDay == day;
        return _buildDayCell(
          day: day,
          isMarked: isMarked,
          isCurrent: isCurrent,
          isSelected: isSelected,
        );
      },
    );
  }
  Widget _buildDayCell({
    required int day,
    required bool isMarked,
    required bool isCurrent,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onDaySelected?.call(day),
      child: Container(
        margin: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF13ec37)
              : isMarked
              ? const Color(0xFF13ec37).withOpacity(0.5)
              : (isCurrent
                    ? const Color(0xFF13ec37).withOpacity(0.3)
                    : Colors.transparent),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Color(0xFF13ec37), width: 2.w)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : isMarked
                  ? Colors.black
                  : (isCurrent ? const Color(0xFF13ec37) : Colors.white),
              fontSize: 14.sp,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : isMarked
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
