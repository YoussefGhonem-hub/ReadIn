import 'package:intl/intl.dart';

/// Western digits (0–9) everywhere for consistency with code (SPEC §14.2 rule 4).
String westernDigits(String input) => String.fromCharCodes(input.runes.map((c) {
      if (c >= 0x0660 && c <= 0x0669) return c - 0x0660 + 0x30; // Arabic-Indic
      if (c >= 0x06F0 && c <= 0x06F9) return c - 0x06F0 + 0x30; // Extended Arabic-Indic
      return c;
    }));

/// e.g. "12 أكتوبر 2026" / "Oct 12, 2026".
String formatDate(DateTime date, String languageCode) =>
    westernDigits(DateFormat.yMMMd(languageCode).format(date.toLocal()));

/// e.g. "12 أكتوبر 2026 2:30 م" / "Oct 12, 2026 2:30 PM", in local time.
String formatDateTime(DateTime date, String languageCode) =>
    westernDigits(DateFormat.yMMMd(languageCode).add_jm().format(date.toLocal()));

/// e.g. "أكتوبر 2026" / "October 2026".
String formatMonthYear(DateTime date, String languageCode) =>
    westernDigits(DateFormat.yMMMM(languageCode).format(date.toLocal()));
