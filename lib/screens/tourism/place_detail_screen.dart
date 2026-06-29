import 'package:cached_network_image/cached_network_image.dart';
import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/place_model.dart';
import '../../controllers/place_detail_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'album_detail_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late PlaceDetailController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller = Get.put(PlaceDetailController(placeId: widget.place.id), tag: "place_${widget.place.id}");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final headerImage = place.images.isNotEmpty 
        ? place.images.first.imageUrl 
        : 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)]
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: headerImage,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: Colors.grey),
                    ),
                    // Gradient dark overlay cho title dễ đọc
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "tab_overview".tr),
                    Tab(text: "tab_info".tr),
                    Tab(text: "tab_gallery".tr),
                    Tab(text: "tab_comments".tr),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(place),
            _buildInfoTab(place),
            _buildGalleryTab(place),
            _buildCommentTab(place),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(PlaceModel place) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                place.category.tr,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const Spacer(),
              Icon(Icons.location_city, color: Colors.grey, size: 20),
              const SizedBox(width: 4),
              Text(place.city, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text("intro_label".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            place.summary,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 24),
          // Có thể thêm tính năng chỉ đường ở đây
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}");
                if (await canLaunchUrl(googleMapsUrl)) {
                  await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                } else {
                  Get.snackbar("error".tr, "cannot_open_google_maps".tr);
                }
              },
              icon: const Icon(Icons.directions),
              label: Text("directions".tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTab(PlaceModel place) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giờ hoạt động
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha:0.5))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time_filled, color: Colors.orange, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("opening_hours_label".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(place.openingHours.isNotEmpty ? place.openingHours : "not_updated".tr, style: const TextStyle(height: 1.5, fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bảng giá vé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha:0.5))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.confirmation_number, color: Colors.green, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ticket_info_label".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        place.ticketPrices.isNotEmpty ? place.ticketPrices : "updating".tr,
                        style: const TextStyle(height: 1.5, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(PlaceModel place) {
    // Nhóm ảnh theo album
    final Map<String, List<String>> albums = {
      'Phong cảnh': [],
      'Check-in': [],
      'Ẩm thực': [],
      'Trải nghiệm': [],
      'Khách sạn': [],
      'Khác': []
    };

    for (var img in place.images) {
      if (albums.containsKey(img.album)) {
        albums[img.album]!.add(img.imageUrl);
      } else {
        albums['Khác']!.add(img.imageUrl);
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: albums.keys.length,
      itemBuilder: (context, index) {
        String albumName = albums.keys.elementAt(index);
        List<String> images = albums[albumName]!;
        
        return GestureDetector(
          onTap: () {
            Get.to(() => AlbumDetailScreen(albumName: albumName, images: images, placeId: place.id));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: images.last, // Lấy ảnh mới nhất làm cover
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
                          )
                        : Image.asset(
                            'assets/images/no_image.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(albumName.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("images_count".trParams({'count': images.length.toString()}), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // _buildGallerySection no longer needed in this file

  Widget _buildCommentTab(PlaceModel place) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (_controller.isLoadingComments.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.comments.isEmpty) {
              return Center(child: Text("no_comments_yet".tr));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await _controller.fetchComments();
              },
              child: ListView.separated(
                controller: _controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _controller.comments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final comment = _controller.comments[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentItem(comment, isReply: false),
                      if (comment.replies.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0, top: 8.0),
                          child: Column(
                            children: comment.replies.map((reply) => _buildCommentItem(reply, isReply: true, parentId: comment.id)).toList(),
                          ),
                        )
                    ],
                  );
                },
              ),
            );
          }),
        ),
        Obx(() {
          if (_controller.replyingTo.value != null) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text("replying_to_user".trParams({'user': _controller.replyingTo.value!.user.name ?? ''}), style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _controller.setReplyingTo(null),
                  )
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller.commentController,
                  decoration: InputDecoration(
                    hintText: "write_comment_hint".tr,
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    )
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _controller.submitComment,
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCommentItem(dynamic comment, {required bool isReply, int? parentId}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 15 : 20,
          backgroundImage: comment.user.avatarUrl != null ? CachedNetworkImageProvider(comment.user.avatarUrl!) : null,
          backgroundColor: AppColors.primaryLight,
          child: comment.user.avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(comment.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (GetStorage().read('userId') == comment.user.id || GetStorage().read('user_id') == comment.user.id || GetStorage().read('id') == comment.user.id)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('edit'.tr)),
                        PopupMenuItem(value: 'delete', child: Text('delete'.tr, style: const TextStyle(color: Colors.red))),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          Get.defaultDialog(
                            title: "confirm".tr,
                            middleText: "delete_comment_confirm_msg".tr,
                            textConfirm: "delete".tr,
                            textCancel: "cancel".tr,
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () {
                              Get.back();
                              _controller.deleteComment(comment.id);
                            }
                          );
                        } else if (value == 'edit') {
                          final editController = TextEditingController(text: comment.content);
                          Get.defaultDialog(
                            title: "edit_comment_title".tr,
                            content: TextField(
                              controller: editController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            textConfirm: "save".tr,
                            textCancel: "cancel".tr,
                            buttonColor: AppColors.primary,
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              Get.back();
                              _controller.updateComment(comment.id, editController.text);
                            }
                          );
                        }
                      },
                    )
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _controller.toggleLike(comment.id, isReply, parentId),
                    child: Row(
                      children: [
                        Icon(
                          comment.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border, 
                          size: 16, 
                          color: comment.isLikedByCurrentUser ? Colors.red : Colors.grey
                        ),
                        const SizedBox(width: 4),
                        if (comment.likeCount > 0)
                          Text("${comment.likeCount}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!isReply)
                    GestureDetector(
                      onTap: () => _controller.setReplyingTo(comment),
                      child: Text("reply".tr, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
