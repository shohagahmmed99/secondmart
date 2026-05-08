import 'package:flutter/material.dart';
import 'package:second_mart/features/home/story_detail_view.dart';

class StorySection extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final String? currentUserPic;
  final VoidCallback? onAddStory;

  const StorySection({
    super.key,
    required this.stories,
    this.currentUserPic,
    this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: onAddStory,
              child: _buildCreateStoryCard(context),
            );
          }
          final group = stories[index - 1];
          final groupStories = List<Map<String, dynamic>>.from(
            group['stories'],
          );

          return GestureDetector(
            onTap: () {
              // Flatten all stories from all groups for the viewer
              final List<Map<String, dynamic>> allStories = [];
              int startIndex = 0;

              for (int i = 0; i < stories.length; i++) {
                if (i < index - 1) {
                  startIndex += (stories[i]['stories'] as List).length;
                }
                allStories.addAll(
                  List<Map<String, dynamic>>.from(stories[i]['stories']),
                );
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryDetailView(
                    stories: allStories,
                    initialIndex: startIndex,
                  ),
                ),
              );
            },
            child: _buildStoryCard(context, group),
          );
        },
      ),
    );
  }

  Widget _buildCreateStoryCard(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3A)
              : Colors.grey.shade300,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: currentUserPic != null
                        ? DecorationImage(
                            image: NetworkImage(currentUserPic!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[200],
                  ),
                  child: currentUserPic == null
                      ? const Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: Text(
                      "Create Story",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Map<String, dynamic> group) {
    final String userName = group['userName'] ?? 'User';
    final String? userPic = group['userPic'];

    // Use the latest story's image for the card preview
    final List groupStories = group['stories'] as List;
    final String? storyImage = groupStories.isNotEmpty
        ? groupStories.last['storyImage']
        : null;

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: storyImage != null
            ? DecorationImage(
                image: NetworkImage(storyImage),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey[300],
      ),
      child: Stack(
        children: [
          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: userPic != null ? NetworkImage(userPic) : null,
                child: userPic == null ? Text(userName[0]) : null,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              userName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
