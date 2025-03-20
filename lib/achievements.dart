import 'package:flutter/material.dart';
import 'package:running/widget/custom_app_bar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api/record.dart';
import 'const/ui.dart';
import 'const/theme.dart';
import 'const/achievement_config.dart';
import 'util/formatter.dart';
import 'util/log.dart';

class Achievements extends StatefulWidget {
  const Achievements({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AchievementsState();
  }
}

class _AchievementsState extends State<Achievements> with SingleTickerProviderStateMixin {
  Map? _recordsSummary;
  int _selectedBadgeIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchData();
    
    // 设置流光动画效果
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 2.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ))..addListener(() {
      setState(() {});
    });
    
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchData() async {
    EasyLoading.show(status: '加载中...');
    try {
      var result = await RecordAPI.sum();
      setState(() {
        _recordsSummary = result;
      });
    } catch (e) {
      log(e);
    } finally {
      EasyLoading.dismiss();
    }
  }

  // 获取总里程数
  double _getTotalMileage() {
    if (_recordsSummary == null || _recordsSummary!.isEmpty) {
      return 0.0;
    }
    
    double totalDistance = 0.0;
    _recordsSummary!.forEach((sportType, summary) {
      totalDistance += summary['distance'] ?? 0.0;
    });
    
    return totalDistance / 1000; // 转换为公里
  }

  // 判断徽章是否已获得
  bool _isBadgeAchieved(double targetMileage) {
    return _getTotalMileage() >= targetMileage;
  }

  // 选择徽章
  void _selectBadge(int index) {
    setState(() {
      _selectedBadgeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMileage = _getTotalMileage();
    final selectedBadge = AchievementConfig.badges[_selectedBadgeIndex];
    final isAchieved = _isBadgeAchieved(selectedBadge['targetMileage']);
    
    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: const CustomAppBar(title: '运动成就'),
      body: Column(
        children: [
          // 顶部大徽标区域
          Container(
            height: MediaQuery.of(context).size.height * 0.33,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 大徽标带流光效果
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.2),
                        Colors.transparent
                      ],
                      stops: [0.0, _animation.value - 1.2, _animation.value - 0.8, _animation.value - 0.4, _animation.value],
                      tileMode: TileMode.clamp,
                    ).createShader(bounds);
                  },
                  blendMode: isAchieved ? BlendMode.srcATop : BlendMode.dst,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 徽标图片
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          boxShadow: isAchieved ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ] : [],
                        ),
                        child: Image.network(
                          selectedBadge['imageUrl'],
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          color: isAchieved ? null : Colors.grey,
                          colorBlendMode: isAchieved ? BlendMode.dst : BlendMode.saturation,
                        ),
                      ),
                      // 未获得时显示锁定图标
                      if (!isAchieved)
                        const Icon(
                          Icons.lock,
                          color: Colors.white54,
                          size: 40,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 徽标标题
                Text(
                  selectedBadge['title'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.valueTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                // 徽标副标题
                Text(
                  selectedBadge['subtitle'],
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeColors.regularTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                // 当前进度
                Text(
                  '当前进度: ${Formatter.formatDistance(totalMileage * 1000)} km',
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeColors.regularTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 分隔线
          Divider(height: 1, color: ThemeColors.dividerColor),
          
          // 底部徽标网格列表
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: AchievementConfig.badges.length,
              itemBuilder: (context, index) {
                final badge = AchievementConfig.badges[index];
                final isAchieved = _isBadgeAchieved(badge['targetMileage']);
                
                return GestureDetector(
                  onTap: () => _selectBadge(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedBadgeIndex == index
                          ? ThemeColors.selectedColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              badge['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              color: isAchieved ? null : Colors.grey,
                              colorBlendMode: isAchieved ? BlendMode.dst : BlendMode.saturation,
                            ),
                            if (!isAchieved)
                              const Icon(
                                Icons.lock,
                                color: Colors.white54,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge['title'],
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.valueTextColor,
                            fontWeight: _selectedBadgeIndex == index ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}