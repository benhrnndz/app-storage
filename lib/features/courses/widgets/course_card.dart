// lib/features/courses/widgets/course_card.dart
import 'package:flutter/material.dart';
import '../../../models/course.dart';

/// A card widget displaying high-level course information.
class CourseCard extends StatelessWidget {
  final Course course;
  final int deliverableCount;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.deliverableCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseColor = Color(course.colorValue);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures child widgets don't bleed outside rounded corners
      child: InkWell(
        onTap: onTap, // Ripple animation on tap
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: courseColor,
                width: 6, // Vertical color stripe on the left edge
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Course Code and Semester badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: courseColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.code,
                      style: TextStyle(
                        color: courseColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    course.semester,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Course Title
              Text(
                course.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Bottom row: Professor & Deliverables count
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.instructor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Deliverable count badge
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$deliverableCount items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

