import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/itinerary_item_response.dart';

class ExcelHelper {

  /// Kết quả của việc đọc file Excel sơ bộ
  static Future<ExcelParseResult?> pickAndPreParseExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      List<int> bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        return null;
      }

      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return null;

      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];
      if (table == null || table.maxRows == 0) return null;

      // Tìm hàng tiêu đề (header row) thực sự bằng cách tính điểm khớp từ khóa
      int headerRowIndex = 0;
      int maxScore = -1;

      for (int r = 0; r < table.rows.length && r < 10; r++) {
        final row = table.rows[r];
        int score = 0;
        for (var cell in row) {
          final val = cell?.value?.toString().toLowerCase().trim() ?? "";
          if (val.isEmpty) continue;
          if (val.contains("ngày") || val.contains("day") || val.contains("đợt") || val == "d") score++;
          if (val.contains("giờ") || val.contains("thời gian") || val.contains("mốc") || val.contains("time") || val == "t") score++;
          if (val.contains("hoạt động") || val.contains("lịch trình") || val.contains("chi tiết") || val.contains("activity") || val.contains("nội dung") || val == "a") score++;
          if (val.contains("địa điểm") || val.contains("nơi") || val.contains("map") || val.contains("location") || val == "l") score++;
          if (val.contains("ghi chú") || val.contains("note") || val == "n") score++;
          if (val.contains("chi phí") || val.contains("dự kiến") || val.contains("dự toán") || val.contains("cost") || val.contains("tiền") || val == "c") score++;
        }
        if (score > maxScore) {
          maxScore = score;
          headerRowIndex = r;
        }
        // Nếu khớp từ 3 cột trở lên, xác suất cực cao đây chính là dòng header
        if (score >= 3) {
          headerRowIndex = r;
          break;
        }
      }

      final headerRow = table.rows[headerRowIndex];
      List<String> headers = [];
      for (var cell in headerRow) {
        headers.add(cell?.value?.toString().trim() ?? "");
      }

      return ExcelParseResult(
        fileName: file.name,
        headers: headers,
        allRows: table.rows,
        headerRowIndex: headerRowIndex,
      );
    } catch (e) {
      return null;
    }
  }

  /// Tự động so khớp cột bằng chuỗi thông minh (Fuzzy Auto-Matching)
  static Map<String, int> autoMatchColumns(List<String> headers) {
    Map<String, int> mapping = {};
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      if (header.isEmpty) continue;

      if ((header.contains("ngày") || header.contains("day") || header.contains("đợt") || header == "date" || header == "d") && !mapping.containsKey("dayNumber")) {
        mapping["dayNumber"] = i;
      } else if ((header.contains("giờ") || header.contains("thời gian") || header.contains("mốc") || header.contains("time") || header.contains("khung giờ") || header == "t") && !mapping.containsKey("timeRange")) {
        mapping["timeRange"] = i;
      } else if ((header.contains("hoạt động") || header.contains("lịch trình") || header.contains("chi tiết") || header.contains("activity") || header.contains("nội dung") || header == "a") && !mapping.containsKey("activity")) {
        mapping["activity"] = i;
      } else if ((header.contains("địa điểm") || header.contains("nơi") || header.contains("map") || header.contains("location") || header.contains("địa chỉ") || header.contains("address") || header.contains("điểm đến") || header == "l") && !mapping.containsKey("location")) {
        mapping["location"] = i;
      } else if ((header.contains("ghi chú") || header.contains("note") || header.contains("lưu ý") || header.contains("chú ý") || header.contains("mô tả") || header.contains("description") || header == "n") && !mapping.containsKey("note")) {
        mapping["note"] = i;
      } else if ((header.contains("chi phí") || header.contains("dự kiến") || header.contains("dự toán") || header.contains("cost") || header.contains("tiền") || header.contains("đơn giá") || header.contains("giá") || header.contains("price") || header.contains("amount") || header == "c") && !mapping.containsKey("estimatedCost")) {
        mapping["estimatedCost"] = i;
      }
    }
    return mapping;
  }

  /// Phân tích toàn bộ dữ liệu Excel dựa vào mapping cột đã khớp
  static List<ItineraryItemResponse> parseRows({
    required List<List<Data?>> allRows,
    required Map<String, int> mapping,
    int startRowIndex = 1,
  }) {
    List<ItineraryItemResponse> items = [];
    if (allRows.length <= startRowIndex) return items;

    // Bước 1: Quét xem cột Ngày có chứa ngày cụ thể (dd/MM/yyyy...) hay không để tính mốc
    DateTime? minDate;
    final dayIdx = mapping["dayNumber"];
    if (dayIdx != null) {
      for (int i = startRowIndex; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isEmpty || dayIdx >= row.length) continue;
        final dayStr = row[dayIdx]?.value?.toString().trim() ?? "";
        final dateVal = _tryParseDate(dayStr);
        if (dateVal != null) {
          if (minDate == null || dateVal.isBefore(minDate)) {
            minDate = dateVal;
          }
        }
      }
    }

    int lastDayNum = 1;

    // Bỏ qua các hàng trước và chính hàng tiêu đề
    for (int i = startRowIndex; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.isEmpty) continue;

      // 1. Phân tích Day Number trước để có kế thừa mốc ngày từ dòng trước đó (trong trường hợp gộp ô hoặc để trống cột ngày)
      int dayNum = lastDayNum;
      if (dayIdx != null && dayIdx < row.length) {
        final dayStr = row[dayIdx]?.value?.toString().trim() ?? "";
        if (dayStr.isNotEmpty) {
          final dateVal = _tryParseDate(dayStr);
          if (dateVal != null && minDate != null) {
            // Tính khoảng cách ngày so với ngày nhỏ nhất tìm thấy
            dayNum = dateVal.difference(minDate).inDays + 1;
          } else {
            // Trích xuất số nếu không phải là ngày cụ thể
            final match = RegExp(r'\d+').firstMatch(dayStr);
            if (match != null) {
              dayNum = int.tryParse(match.group(0)!) ?? lastDayNum;
            }
          }
        }
      }
      if (dayNum < 1) dayNum = 1;
      lastDayNum = dayNum; // Luôn cập nhật lại mốc ngày cho dòng sau kế thừa

      // 2. Phải có hoạt động
      final activityIdx = mapping["activity"];
      if (activityIdx == null || activityIdx >= row.length) continue;
      final activityVal = row[activityIdx]?.value?.toString().trim() ?? "";
      if (activityVal.isEmpty) continue;

      // 3. Phân tích Khung giờ
      String? timeRange;
      final timeIdx = mapping["timeRange"];
      if (timeIdx != null && timeIdx < row.length) {
        timeRange = row[timeIdx]?.value?.toString().trim();
        if (timeRange != null && timeRange.isEmpty) timeRange = null;
      }

      // Địa điểm
      String? location;
      final locIdx = mapping["location"];
      if (locIdx != null && locIdx < row.length) {
        location = row[locIdx]?.value?.toString().trim();
        if (location != null && location.isEmpty) location = null;
      }

      // Ghi chú
      String? note;
      final noteIdx = mapping["note"];
      if (noteIdx != null && noteIdx < row.length) {
        note = row[noteIdx]?.value?.toString().trim();
        if (note != null && note.isEmpty) note = null;
      }

      // Chi phí dự kiến (hỗ trợ lọc các ký tự tiền tệ như đ, VND, dấu phẩy phân tách)
      double? estCost;
      final costIdx = mapping["estimatedCost"];
      if (costIdx != null && costIdx < row.length) {
        final costStr = row[costIdx]?.value?.toString().replaceAll(RegExp(r'[^0-9.]'), "") ?? "";
        estCost = double.tryParse(costStr);
      }

      items.add(ItineraryItemResponse(
        dayNumber: dayNum,
        timeRange: timeRange,
        activity: activityVal,
        location: location,
        note: note,
        estimatedCost: estCost,
      ));
    }
    return items;
  }

  static DateTime? _tryParseDate(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) return null;

    // Thử parse kiểu tiêu chuẩn yyyy-MM-dd
    var parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Thử parse kiểu dd/MM/yyyy hoặc dd-MM-yyyy
    final dateRegex = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');
    final match = dateRegex.firstMatch(cleaned);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // Thử parse kiểu yyyy/MM/dd
    final dateRegex2 = RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$');
    final match2 = dateRegex2.firstMatch(cleaned);
    if (match2 != null) {
      final year = int.tryParse(match2.group(1)!);
      final month = int.tryParse(match2.group(2)!);
      final day = int.tryParse(match2.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// Xuất lịch trình ra mảng byte Excel để chia sẻ
  static List<int>? exportToExcel(List<ItineraryItemResponse> items) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Thiết lập Header
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Khung giờ'),
      TextCellValue('Hoạt động'),
      TextCellValue('Địa điểm'),
      TextCellValue('Ghi chú'),
      TextCellValue('Chi phí dự toán')
    ]);

    // Thêm các hàng
    for (var item in items) {
      sheet.appendRow([
        IntCellValue(item.dayNumber),
        TextCellValue(item.timeRange ?? ""),
        TextCellValue(item.activity),
        TextCellValue(item.location ?? ""),
        TextCellValue(item.note ?? ""),
        DoubleCellValue(item.estimatedCost ?? 0.0),
      ]);
    }

    return excel.save();
  }
}

class ExcelParseResult {
  final String fileName;
  final List<String> headers;
  final List<List<Data?>> allRows;
  final int headerRowIndex;

  ExcelParseResult({
    required this.fileName,
    required this.headers,
    required this.allRows,
    required this.headerRowIndex,
  });
}