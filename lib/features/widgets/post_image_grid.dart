import 'package:flutter/material.dart';
import 'package:second_mart/features/widgets/image_viewer.dart';

class PostImageGrid extends StatelessWidget {
  final List<String> imageUrls;

  const PostImageGrid({super.key, required this.imageUrls});

  void _openImageViewer(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(images: imageUrls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(context, 0),
        child: Hero(
          tag: imageUrls[0],
          child: Image.network(
            imageUrls[0],
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
        ),
      );
    }

    if (imageUrls.length == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(child: _buildImage(context, 0)),
            const SizedBox(width: 2),
            Expanded(child: _buildImage(context, 1)),
          ],
        ),
      );
    }

    if (imageUrls.length == 3) {
      return SizedBox(
        height: 300,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildImage(context, 0)),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildImage(context, 1)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildImage(context, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (imageUrls.length == 4) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(context, 0)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(context, 1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(context, 2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(context, 3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 5 or more images
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImage(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildImage(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImage(context, 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildImage(context, 3)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(context, 4),
                      if (imageUrls.length > 5)
                        GestureDetector(
                          onTap: () => _openImageViewer(context, 4),
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                "+${imageUrls.length - 5}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, index),
      child: Hero(
        tag: imageUrls[index],
        child: Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
