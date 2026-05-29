import 'package:chiabill/data/models/place_comment_model.dart';
import 'package:chiabill/data/repositories/place_comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaceDetailController extends GetxController {
  final PlaceCommentRepository _commentRepo = PlaceCommentRepository();
  final int placeId;

  var comments = <PlaceCommentModel>[].obs;
  var isLoadingComments = false.obs;
  
  final commentController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  var replyingTo = Rxn<PlaceCommentModel>();

  PlaceDetailController({required this.placeId});

  @override
  void onClose() {
    commentController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    fetchComments();
  }

  Future<void> fetchComments() async {
    isLoadingComments.value = true;
    final res = await _commentRepo.getComments(placeId);
    if (res.success && res.data != null) {
      comments.assignAll(res.data!);
    }
    isLoadingComments.value = false;
  }

  Future<void> submitComment() async {
    if (commentController.text.trim().isEmpty) return;
    
    // Tắt bàn phím
    FocusManager.instance.primaryFocus?.unfocus();
    
    final content = commentController.text.trim();
    commentController.clear();
    
    if (replyingTo.value != null) {
      final res = await _commentRepo.replyComment(replyingTo.value!.id, content);
      if (res.success) {
        // Tải lại toàn bộ nếu là reply để đồng bộ cây comment
        await fetchComments();
        _scrollToBottom();
      } else {
        Get.snackbar("Lỗi", res.message ?? "Không thể gửi phản hồi", backgroundColor: Colors.red, colorText: Colors.white);
      }
      replyingTo.value = null;
    } else {
      final res = await _commentRepo.addComment(placeId, content);
      if (res.success && res.data != null) {
        // Thêm trực tiếp vào state local để UI update tức thì, không cần fetch lại toàn bộ
        comments.add(res.data!);
        _scrollToBottom();
      } else {
        Get.snackbar("Lỗi", res.message ?? "Không thể gửi bình luận", backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> toggleLike(int commentId, bool isReply, int? parentId) async {
    final res = await _commentRepo.toggleLike(commentId);
    if (res.success) {
      // Cập nhật state local để UI phản hồi nhanh
      if (!isReply) {
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          fetchComments();
        }
      } else {
        fetchComments();
      }
    }
  }

  void setReplyingTo(PlaceCommentModel? comment) {
    replyingTo.value = comment;
  }

  Future<void> deleteComment(int commentId) async {
    final res = await _commentRepo.deleteComment(commentId);
    if (res.success) {
      Get.snackbar("Thành công", "Đã xóa bình luận", backgroundColor: Colors.green, colorText: Colors.white);
      fetchComments();
    } else {
      Get.snackbar("Lỗi", res.message ?? "Không thể xóa bình luận", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateComment(int commentId, String content) async {
    if (content.trim().isEmpty) return;
    final res = await _commentRepo.updateComment(commentId, content.trim());
    if (res.success) {
      Get.snackbar("Thành công", "Đã cập nhật bình luận", backgroundColor: Colors.green, colorText: Colors.white);
      fetchComments();
    } else {
      Get.snackbar("Lỗi", res.message ?? "Không thể cập nhật bình luận", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
