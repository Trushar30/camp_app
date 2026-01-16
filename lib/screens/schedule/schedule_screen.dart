/// Schedule Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/schedule_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = DateTime.now().weekday - 1;
  final ScheduleService _scheduleService = ScheduleService();
  
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  // Mapping index to day mapping (Mon=1, ... Sat=6)
  // DateTime.weekday returns 1 for Mon, 7 for Sun.
  // Our _days list is 0-indexed: 0=Mon, ... 5=Sat.
  // So dayOfWeek = index + 1
  
  @override
  void initState() {
    super.initState();
    // Adjust selected day if it's Sunday (6 in 0-indexed array if we had Sun, but we don't)
    // DateTime.weekday: Mon=1, Sun=7
    // _selectedDay init: weekday - 1. So Mon=0, Sun=6.
    // Limit to 0-5 (Mon-Sat)
    if (_selectedDay > 5) {
      _selectedDay = 0; // Default to Monday if Sunday
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // User Model has classId. Fallback to empty if not set.
    final classId = authProvider.user?.classId ?? 'FY-B'; // Default generic class for test if null

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.black),
            onPressed: () {
              setState(() {}); 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_days.length, (index) {
                final isSelected = _selectedDay == index;
                final now = DateTime.now();
                // 1=Mon, 7=Sun
                final currentWeekday = now.weekday; 
                // Our index 0=Mon. Weekday 1=Mon.
                // targetWeekday = index + 1
                final targetWeekday = index + 1;
                final diff = targetWeekday - currentWeekday;
                final date = now.add(Duration(days: diff));
                final isToday = diff == 0;
                
                return _DayButton(
                  day: _days[index],
                  date: date.day,
                  isSelected: isSelected,
                  isToday: isToday,
                  onTap: () => setState(() => _selectedDay = index),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Schedule List
          Expanded(
            child: FutureBuilder<List<ScheduleModel>>(
              future: _scheduleService.getSchedule(
                classId: classId,
                dayIndex: _selectedDay, // 0 = Mon, matches Web logic
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                var schedule = snapshot.data ?? [];
                
                // Build display list with all 6 time slots
                // Show actual classes or "Break" for empty slots
                final List<dynamic> displayList = [];
                
                // Time slots: 0-3 are morning, 4-5 are afternoon
                // Lunch break is between slot 3 and 4 (01:10 - 02:20)
                
                // Sort schedule by slot index
                schedule.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
                
                // Create a map of slot index to schedule items
                final Map<int, List<ScheduleModel>> slotMap = {};
                for (var item in schedule) {
                  if (!slotMap.containsKey(item.slotIndex)) {
                    slotMap[item.slotIndex] = [];
                  }
                  slotMap[item.slotIndex]!.add(item);
                }
                
                // Process morning slots (0, 1, 2, 3)
                for (int i = 0; i <= 3; i++) {
                  if (slotMap.containsKey(i) && slotMap[i]!.isNotEmpty) {
                    // Add all classes for this slot (could be multiple batches)
                    for (var item in slotMap[i]!) {
                      displayList.add(item);
                    }
                  } else {
                    // Empty slot - add a break placeholder
                    displayList.add(_EmptySlotBreak(slotIndex: i));
                  }
                }
                
                // Add Lunch Break (between morning and afternoon)
                displayList.add(_BreakItem());
                
                // Process afternoon slots (4, 5)
                for (int i = 4; i <= 5; i++) {
                  if (slotMap.containsKey(i) && slotMap[i]!.isNotEmpty) {
                    for (var item in slotMap[i]!) {
                      displayList.add(item);
                    }
                  } else {
                    // Empty slot - add a break placeholder
                    displayList.add(_EmptySlotBreak(slotIndex: i));
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];
                    
                    if (item is _BreakItem) {
                       return _buildBreakCard()
                        .animate(delay: Duration(milliseconds: 100 * index))
                        .fadeIn()
                        .slideX(begin: 0.1, end: 0);
                    }
                    
                    if (item is _EmptySlotBreak) {
                       return _buildEmptySlotBreakCard(item.slotIndex)
                        .animate(delay: Duration(milliseconds: 100 * index))
                        .fadeIn()
                        .slideX(begin: 0.1, end: 0);
                    }
                    
                    return _buildScheduleCard(item as ScheduleModel, index)
                        .animate(delay: Duration(milliseconds: 100 * index))
                        .fadeIn()
                        .slideX(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '01:10',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '02:20',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.coffee,
                      size: 20,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lunch Break',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Relax & Recharge',
                         style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel item, int index) {
    // Determine color based on type (Lab vs Lecture)
    final Color color = item.isLab ? const Color(0xFFF59E0B) : AppTheme.primaryBlue;
    final timeStr = item.timeRange;
    final startTime = timeStr.isNotEmpty ? timeStr.split(' - ')[0] : '';
    final endTime = timeStr.isNotEmpty ? timeStr.split(' - ')[1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  endTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isLab ? 'Lab' : 'Lecture',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      if (item.batchNumber != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Batch ${item.batchNumber}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.course,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Iconsax.user,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.professor,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.room,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotBreakCard(int slotIndex) {
    // Time slots for display
    const slots = [
      ['09:10', '10:10'],
      ['10:10', '11:10'],
      ['11:10', '12:10'],
      ['12:10', '01:10'],
      ['02:20', '03:20'],
      ['03:20', '04:20'],
    ];
    
    final startTime = slotIndex < slots.length ? slots[slotIndex][0] : '';
    final endTime = slotIndex < slots.length ? slots[slotIndex][1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  endTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.timer_pause,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Break',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakItem {}

class _EmptySlotBreak {
  final int slotIndex;
  _EmptySlotBreak({required this.slotIndex});
}

class _DayButton extends StatefulWidget {
  final String day;
  final int date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_DayButton> createState() => _DayButtonState();
}

class _DayButtonState extends State<_DayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(_DayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryBlue
                : widget.isToday
                    ? AppTheme.primaryBlue.withOpacity(0.1)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: widget.isToday && !widget.isSelected
                ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 1.5)
                : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                widget.day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? Colors.white
                      : widget.isToday
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.date}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected
                      ? Colors.white
                      : widget.isToday
                          ? AppTheme.primaryBlue
                          : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

