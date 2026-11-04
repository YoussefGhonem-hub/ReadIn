import '../rdoc_document.dart';

/// A cell of a table: [row] 0 is the header row, body rows start at 1.
typedef TablePosition = ({int row, int col});

/// The table tools (SPEC §13.2 table, the web editor's table tools).
enum TableOp { addRow, addColumn, deleteRow, deleteColumn }

/// Pure table edits within the schema's limits: one header row that always stays, 1–12 columns, at most 200 rows.
abstract final class TableEditing {
  static const maxColumns = 12;
  static const maxRows = 200;

  /// [table] after [op] at [cell], or the same table when the schema doesn't allow it.
  static RTable apply(RTable table, TableOp op, TablePosition cell) {
    final columns = table.header.length;
    final col = cell.col.clamp(0, columns - 1);
    return switch (op) {
      TableOp.addRow => table.rows.length >= maxRows
          ? table
          : _with(table, rows: [
              ...table.rows.take(cell.row),
              [for (var c = 0; c < columns; c++) const <RInline>[]],
              ...table.rows.skip(cell.row),
            ]),
      TableOp.addColumn => columns >= maxColumns
          ? table
          : _with(
              table,
              header: [...table.header.take(col + 1), const [], ...table.header.skip(col + 1)],
              rows: [
                for (final r in _filled(table.rows, columns)) [...r.take(col + 1), const <RInline>[], ...r.skip(col + 1)],
              ],
            ),
      // The header row is required.
      TableOp.deleteRow => cell.row < 1 || cell.row > table.rows.length
          ? table
          : _with(table, rows: [...table.rows]..removeAt(cell.row - 1)),
      TableOp.deleteColumn => columns <= 1
          ? table
          : _with(
              table,
              header: [...table.header]..removeAt(col),
              rows: [for (final r in _filled(table.rows, columns)) [...r]..removeAt(col)],
            ),
    };
  }

  /// Rows padded to [columns] cells, so column edits line up.
  static List<List<List<RInline>>> _filled(List<List<List<RInline>>> rows, int columns) => [
        for (final r in rows) [...r, for (var c = r.length; c < columns; c++) const <RInline>[]],
      ];

  static RTable _with(RTable t, {List<List<RInline>>? header, List<List<List<RInline>>>? rows}) =>
      RTable(t.id, dir: t.dir, header: header ?? t.header, rows: rows ?? t.rows);
}
