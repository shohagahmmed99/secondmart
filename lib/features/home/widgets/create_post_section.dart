import 'package:flutter/material.dart';

class CreatePostSection extends StatelessWidget {
  final String? currentUserPic;
  final VoidCallback? onTap;

  const CreatePostSection({super.key, this.currentUserPic, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: currentUserPic != null
                    ? NetworkImage(currentUserPic!)
                    : null,
                child: currentUserPic == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "What's on your mind?",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Icon(Icons.photo_outlined, color: Colors.green, size: 24),
                  Text(
                    "Photo",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
