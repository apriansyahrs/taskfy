import 'package:flutter/material.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:taskfy/config/style_guide.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? StyleGuide.paddingSmall : StyleGuide.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDarkMode 
                                ? ThemeConfig.textSecondaryDark 
                                : ThemeConfig.textSecondaryLight,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDarkMode 
                          ? ThemeConfig.textPrimaryDark 
                          : ThemeConfig.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 24 : 28,
                    ),
              ),
              if (subtitle != null) ...[                
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode 
                            ? ThemeConfig.textSecondaryDark 
                            : ThemeConfig.textSecondaryLight,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

