import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ItemIconWidget extends StatelessWidget {
  final String itemId;
  final String category;
  final String? emojiHint;
  final double size;
  final double iconSize;
  final Color? backgroundColor;

  const ItemIconWidget({
    super.key,
    required this.itemId,
    required this.category,
    this.emojiHint,
    this.size = 42,
    this.iconSize = 20,
    this.backgroundColor,
  });

  dynamic _getVectorIconData() {
    final lowerId = itemId.toLowerCase();
    final lowerCat = category.toLowerCase();

    // 1. Grains, Atta & Rice
    if (lowerId.contains('atta') || lowerId.contains('grain') || lowerId.contains('wheat')) {
      return FontAwesomeIcons.wheatAwn;
    }
    if (lowerId.contains('rice') || lowerId.contains('poha') || lowerId.contains('maida') || lowerId.contains('sooji')) {
      return FontAwesomeIcons.bowlRice;
    }
    if (lowerId.contains('bread') || lowerId.contains('toast') || lowerId.contains('bun')) {
      return FontAwesomeIcons.breadSlice;
    }

    // 2. Dals & Pulses
    if (lowerCat.contains('dal') || lowerCat.contains('pulse') || lowerId.contains('dal') || lowerId.contains('chana') || lowerId.contains('rajma')) {
      return FontAwesomeIcons.seedling;
    }

    // 3. Spices & Seasoning
    if (lowerCat.contains('spice') || lowerCat.contains('masala') || lowerId.contains('namak') || lowerId.contains('salt')) {
      return FontAwesomeIcons.pepperHot;
    }
    if (lowerId.contains('sugar') || lowerId.contains('jaggery') || lowerId.contains('gur') || lowerId.contains('cheeni')) {
      return FontAwesomeIcons.cubes;
    }
    if (lowerId.contains('chai') || lowerId.contains('tea') || lowerId.contains('coffee')) {
      return FontAwesomeIcons.mugHot;
    }

    // 4. Dairy & Bakery
    if (lowerId.contains('milk') || lowerId.contains('dahi') || lowerId.contains('paneer') || lowerId.contains('butter') || lowerId.contains('ghee')) {
      return FontAwesomeIcons.bottleWater;
    }
    if (lowerCat.contains('dairy')) {
      return FontAwesomeIcons.cow;
    }

    // 5. Oils & Ghee
    if (lowerCat.contains('oil') || lowerId.contains('oil') || lowerId.contains('tel')) {
      return FontAwesomeIcons.droplet;
    }

    // 6. Pooja & Festivals
    if (lowerCat.contains('pooja') || lowerId.contains('diya') || lowerId.contains('incense') || lowerId.contains('agarbatti') || lowerId.contains('kapoor') || lowerId.contains('roli')) {
      return FontAwesomeIcons.fire;
    }
    if (lowerCat.contains('sweet') || lowerId.contains('ladoo') || lowerId.contains('mithai') || lowerId.contains('halwa')) {
      return FontAwesomeIcons.cookie;
    }

    // 7. Cleaning & Hygiene
    if (lowerCat.contains('clean') || lowerId.contains('surf') || lowerId.contains('soap') || lowerId.contains('vim') || lowerId.contains('dettol')) {
      return FontAwesomeIcons.pumpSoap;
    }

    // 8. Medicine & First Aid
    if (lowerCat.contains('medicine') || lowerCat.contains('first aid') || lowerId.contains('dolo') || lowerId.contains('paracetamol') || lowerId.contains('band')) {
      return FontAwesomeIcons.kitMedical;
    }

    // Default Fallbacks by category
    if (lowerCat.contains('vegetable') || lowerCat.contains('fruit')) {
      return FontAwesomeIcons.carrot;
    }

    return FontAwesomeIcons.box;
  }

  Color _getBadgeColor(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;

    final lowerCat = category.toLowerCase();
    final lowerId = itemId.toLowerCase();

    if (lowerId.contains('atta') || lowerId.contains('grain')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (lowerCat.contains('dal') || lowerCat.contains('pulse')) {
      return const Color(0xFFEAB308); // Yellow
    }
    if (lowerCat.contains('spice') || lowerCat.contains('masala')) {
      return const Color(0xFFEF4444); // Red
    }
    if (lowerCat.contains('dairy') || lowerId.contains('milk')) {
      return const Color(0xFF0EA5E9); // Sky Blue
    }
    if (lowerCat.contains('oil')) {
      return const Color(0xFF84CC16); // Lime
    }
    if (lowerCat.contains('pooja') || lowerCat.contains('sweet')) {
      return const Color(0xFFEC4899); // Pink
    }
    if (lowerCat.contains('clean')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (lowerCat.contains('medicine')) {
      return const Color(0xFF10B981); // Emerald
    }

    return const Color(0xFF6366F1); // Indigo
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(context);
    final iconData = _getVectorIconData();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: FaIcon(
        iconData,
        size: iconSize,
        color: badgeColor,
      ),
    );
  }
}
