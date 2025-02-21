import 'package:flutter/material.dart';
import 'package:taskfy/config/style_guide.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;

  const CustomErrorWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: StyleGuide.spacingLarge),
          Text(
            'An error occurred',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: StyleGuide.spacingSmall),
          Text(
            message,
            style: StyleGuide.errorTextStyle(context),
          ),
          SizedBox(height: StyleGuide.spacingLarge),
          ElevatedButton(
            style: StyleGuide.buttonStyle(context),
            onPressed: () {
              // Implement retry logic here
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

