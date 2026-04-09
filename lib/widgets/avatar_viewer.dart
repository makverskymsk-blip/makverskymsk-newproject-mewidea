import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

/// Opens a fullscreen avatar preview with Hero animation and pinch-to-zoom.
///
/// [avatarUrl] – the network URL of the avatar image.
/// [heroTag] – unique tag for Hero animation (e.g. 'avatar_$userId').
/// [userName] – displayed below the image.
void openAvatarViewer(
  BuildContext context, {
  required String avatarUrl,
  required String heroTag,
  String? userName,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AvatarViewerPage(
          avatarUrl: avatarUrl,
          heroTag: heroTag,
          userName: userName,
          animation: animation,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child; // Hero handles the transition
      },
    ),
  );
}

class _AvatarViewerPage extends StatefulWidget {
  final String avatarUrl;
  final String heroTag;
  final String? userName;
  final Animation<double> animation;

  const _AvatarViewerPage({
    required this.avatarUrl,
    required this.heroTag,
    this.userName,
    required this.animation,
  });

  @override
  State<_AvatarViewerPage> createState() => _AvatarViewerPageState();
}

class _AvatarViewerPageState extends State<_AvatarViewerPage> {
  double _dragOffset = 0;
  double _dragScale = 1.0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      // Scale down as user drags away
      _dragScale = (1 - (_dragOffset.abs() / 600)).clamp(0.7, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100 || details.velocity.pixelsPerSecond.dy.abs() > 500) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _dragScale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final opacity = widget.animation.value *
            (1 - (_dragOffset.abs() / 400)).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred backdrop
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20 * opacity,
                  sigmaY: 20 * opacity,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6 * opacity),
                ),
              ),
            ),

            // Image + dismiss gesture
            SafeArea(
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: Duration.zero,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Centered image
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        child: Transform.translate(
                          offset: Offset(0, _dragOffset),
                          child: Transform.scale(
                            scale: _dragScale,
                            child: Hero(
                              tag: widget.heroTag,
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                                    maxHeight: MediaQuery.of(context).size.width * 0.85,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(
                                      widget.avatarUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: MediaQuery.of(context).size.width * 0.85,
                                          height: MediaQuery.of(context).size.width * 0.85,
                                          color: t.cardBg,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (c1, e1, st1) => Container(
                                        width: MediaQuery.of(context).size.width * 0.85,
                                        height: MediaQuery.of(context).size.width * 0.85,
                                        color: t.cardBg,
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: t.textHint,
                                          size: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // User name
                  if (widget.userName != null)
                    AnimatedOpacity(
                      opacity: opacity,
                      duration: Duration.zero,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Text(
                          widget.userName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
