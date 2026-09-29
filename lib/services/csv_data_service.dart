class CsvDataService {
  static const transactionHeaders = [
    'date',
    'type',
    'amount',
    'category',
    'account',
    'to_account',
    'merchant',
    'note',
    'tags',
  ];

  static String encode(List<List<String>> rows) =>
      rows.map((row) => row.map(_quote).join(',')).join('\r\n');

  static String _quote(String value) => '"${value.replaceAll('"', '""')}"';

  static List<List<String>> decode(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == '"') {
        if (quoted && i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        row.add(field.toString());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' && i + 1 < source.length && source[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        field.write(char);
      }
    }
    if (quoted) {
      throw const FormatException('CSV has an unclosed quoted field.');
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }
}
