import 'package:flutter/material.dart';
import 'dart:math';

class ActivitySelectionScreen extends StatelessWidget {
  const ActivitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 360,
              width: 360,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center circle - Outdoor Run
                  _buildActivityCircle(
                    context: context,
                    activity: 'Outdoor\nRun',
                    size: 120,
                    fontSize: 18,
                  ),
                  
                  // Top circle - Indoor Run
                  Positioned(
                    top: 0,
                    child: _buildActivityCircle(
                      context: context,
                      activity: 'Indoor\nRun',
                      size: 100,
                    ),
                  ),
                  
                  // Right circle - Outdoor Bike
                  Positioned(
                    right: 0,
                    top: 130,
                    child: _buildActivityCircle(
                      context: context,
                      activity: 'Outdoor\nBike',
                      size: 100,
                    ),
                  ),
                  
                  // Bottom circle - Indoor Walk
                  Positioned(
                    bottom: 0,
                    child: _buildActivityCircle(
                      context: context,
                      activity: 'Indoor\nWalk',
                      size: 100,
                    ),
                  ),
                  
                  // Left circle - Outdoor Walk
                  Positioned(
                    left: 0,
                    top: 130,
                    child: _buildActivityCircle(
                      context: context,
                      activity: 'Outdoor\nWalk',
                      size: 100,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCircle({
    required BuildContext context,
    required String activity,
    required double size,
    double fontSize = 16,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, activity.replaceAll('\n', ' '));
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF4A67FF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A67FF).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            activity,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 