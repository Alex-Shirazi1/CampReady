import 'package:flutter/material.dart';

class CampsiteMap extends StatelessWidget {
  const CampsiteMap({
    super.key,
    required this.onRedwood,
    required this.onSunset,
  });

  final VoidCallback onRedwood;
  final VoidCallback onSunset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 342 / 230,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, bounds) {
            Widget pin(String label, double x, double y, VoidCallback onTap) {
              return Positioned(
                left: x * bounds.maxWidth - 24,
                top: y * bounds.maxHeight - 24,
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: label,
                  onPressed: onTap,
                  icon: const SizedBox.shrink(),
                ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/campsite-map.png',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
                pin('Redwood Grove map pin', 137 / 342, 96 / 230, onRedwood),
                pin('Sunset Ridge map pin', 255 / 342, 48 / 230, onSunset),
              ],
            );
          },
        ),
      ),
    );
  }
}
