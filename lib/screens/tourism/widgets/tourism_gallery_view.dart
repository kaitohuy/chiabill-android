import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/tourism_controller.dart';
import '../../../data/models/place_model.dart';
import '../place_detail_screen.dart';

class TourismGalleryView extends StatefulWidget {
  const TourismGalleryView({super.key});

  @override
  State<TourismGalleryView> createState() => _TourismGalleryViewState();
}

class _TourismGalleryViewState extends State<TourismGalleryView> {
  final TourismController controller = Get.find<TourismController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (controller.galleryPlaces.isEmpty) {
      controller.fetchGalleryPlaces(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.fetchGalleryPlaces(isRefresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.galleryPlaces.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.galleryPlaces.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.landscape_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "Không tìm thấy địa điểm nào",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchGalleryPlaces(isRefresh: true),
        child: GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 76,
            16,
            80,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: controller.galleryPlaces.length + (controller.isGalleryLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.galleryPlaces.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final place = controller.galleryPlaces[index];
            return _buildPlaceCard(place);
          },
        ),
      );
    });
  }

  Widget _buildPlaceCard(PlaceModel place) {
    final hasImage = place.images.isNotEmpty;
    final imageUrl = hasImage ? place.images.first.imageUrl : '';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => PlaceDetailScreen(place: place)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Area
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasImage && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/no_image.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/no_image.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Category Icon Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(place.category).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(place.category),
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info Area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.city,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Biển': return Icons.beach_access;
      case 'Núi': return Icons.terrain;
      case 'Bể bơi': return Icons.pool;
      case 'TTTM': return Icons.local_mall;
      case 'Di tích': return Icons.account_balance;
      case 'Cafe': return Icons.local_cafe;
      case 'Nhà hàng': return Icons.restaurant;
      case 'Cắm trại': return Icons.park;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Biển': return Colors.blue;
      case 'Núi': return Colors.green;
      case 'Bể bơi': return Colors.cyan;
      case 'TTTM': return Colors.purple;
      case 'Di tích': return Colors.brown;
      case 'Cafe': return Colors.orange;
      case 'Nhà hàng': return Colors.red;
      case 'Cắm trại': return Colors.green[700] ?? Colors.green;
      default: return Colors.grey;
    }
  }
}
