import 'package:new_project/offline/firestore_shims.dart';

/// Universal date/time converter helper
/// Safely converts between Timestamp, int (epoch ms), String (ISO), and DateTime
/// Use this everywhere a date is read from or written to database/API

/// Convert any date value to DateTime?
/// Accepts: Timestamp, int (epoch ms), String (ISO), DateTime, null
/// Always returns DateTime? (null if conversion fails or input is null)
DateTime? safeDateFromDynamic(dynamic value) {
  if (value == null) return null;

  // Already a DateTime
  if (value is DateTime) {
    return value;
  }

  // Timestamp (Firestore)
  if (value is Timestamp) {
    try {
      return value.toDate();
    } catch (e) {
      return null;
    }
  }

  // int (epoch milliseconds)
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    } catch (e) {
      return null;
    }
  }

  // String (ISO format)
  if (value is String) {
    try {
      // Try parsing as ISO string
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      // Try parsing as epoch milliseconds string
      final epochMs = int.tryParse(value);
      if (epochMs != null) {
        return DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  return null;
}

/// Convert DateTime? to epoch milliseconds (int) for SQLite storage
/// Returns null if input is null
int? safeDateToEpochMs(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.toUtc().millisecondsSinceEpoch;
}

/// Convert DateTime? to Firestore Timestamp for Firestore storage
/// Returns null if input is null
Timestamp? safeDateToTimestamp(DateTime? dateTime) {
  if (dateTime == null) return null;
  try {
    return Timestamp.fromDate(dateTime.toUtc());
  } catch (e) {
    return null;
  }
}

/// Convert any date value to epoch milliseconds (int) for SQLite
/// Accepts: Timestamp, int, String (ISO or epoch), DateTime, null
/// Always returns int? (null if conversion fails or input is null)
int? safeDateToEpochMsFromDynamic(dynamic value) {
  final dateTime = safeDateFromDynamic(value);
  return safeDateToEpochMs(dateTime);
}
