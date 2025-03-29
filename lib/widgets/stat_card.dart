import 'package:flutter/material.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';

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
    required this.color, // This color parameter is used for the icon background
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < StyleGuide.breakpointMobile;
    
    return Card(
      elevation: 0,
      color: ThemeConfig.card, // Explicitly set card background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
        side: BorderSide(color: ThemeConfig.border.withOpacity(0.5)), // Optional border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
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
                      style: StyleGuide.subtitleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? StyleGuide.paddingTiny : StyleGuide.paddingSmall),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: color, // Using the passed color parameter for the icon
                      size: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? StyleGuide.spacingSmall : StyleGuide.spacingMedium),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.textPrimary, // Using textPrimary for the value
                ),
              ),
              if (subtitle != null) ...[                
                SizedBox(height: isSmallScreen ? StyleGuide.spacingTiny : StyleGuide.spacingSmall),
                Text(
                  subtitle!,
                  style: StyleGuide.smallLabelStyle,
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

