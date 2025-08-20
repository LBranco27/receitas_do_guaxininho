import 'dart:io';
import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final bool favorite;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imagePath,
    this.favorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imagePath == null
                    ? const ColoredBox(color: Color(0x11000000))
                    : Image.file(File(imagePath!), fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
              child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
