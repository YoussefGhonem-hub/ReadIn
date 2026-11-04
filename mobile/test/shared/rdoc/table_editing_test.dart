import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/editing/table_editing.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

List<RInline> _t(String text) => [RText(text)];

const _table = RTable('t', dir: 'auto', header: [
  [RText('A')],
  [RText('B')],
], rows: [
  [
    [RText('1')],
    [RText('2')],
  ],
  [
    [RText('3')],
    [RText('4')],
  ],
]);

void main() {
  group('TableEditing (the table tools)', () {
    test('adds a row below the cell and a column after it', () {
      final rowAdded = TableEditing.apply(_table, TableOp.addRow, (row: 1, col: 0));
      expect(rowAdded.rows, [
        [_t('1'), _t('2')],
        [const <RInline>[], const <RInline>[]],
        [_t('3'), _t('4')],
      ]);
      // From the header row, the new row is the first body row.
      expect(TableEditing.apply(_table, TableOp.addRow, (row: 0, col: 1)).rows.first, [const <RInline>[], const <RInline>[]]);

      final columnAdded = TableEditing.apply(_table, TableOp.addColumn, (row: 2, col: 0));
      expect(columnAdded.header, [_t('A'), const <RInline>[], _t('B')]);
      expect(columnAdded.rows.last, [_t('3'), const <RInline>[], _t('4')]);
      expect(columnAdded.id, 't');
    });

    test('deletes the row and the column of the cell; the header row stays', () {
      final rowDeleted = TableEditing.apply(_table, TableOp.deleteRow, (row: 1, col: 1));
      expect(rowDeleted.rows, [
        [_t('3'), _t('4')],
      ]);
      expect(identical(TableEditing.apply(_table, TableOp.deleteRow, (row: 0, col: 0)), _table), isTrue);

      final columnDeleted = TableEditing.apply(_table, TableOp.deleteColumn, (row: 0, col: 0));
      expect(columnDeleted.header, [_t('B')]);
      expect(columnDeleted.rows, [
        [_t('2')],
        [_t('4')],
      ]);
      // A table keeps at least one column.
      expect(identical(TableEditing.apply(columnDeleted, TableOp.deleteColumn, (row: 0, col: 0)), columnDeleted), isTrue);
    });

    test('respects the schema limits: 12 columns, 200 rows; short rows are padded', () {
      final wide = RTable('w', dir: 'auto', header: [for (var c = 0; c < 12; c++) _t('$c')], rows: const []);
      expect(identical(TableEditing.apply(wide, TableOp.addColumn, (row: 0, col: 3)), wide), isTrue);
      final long = RTable('l', dir: 'auto', header: [_t('h')], rows: [
        for (var r = 0; r < 200; r++) [_t('$r')],
      ]);
      expect(identical(TableEditing.apply(long, TableOp.addRow, (row: 4, col: 0)), long), isTrue);

      const ragged = RTable('r', dir: 'rtl', header: [
        [RText('a')],
        [RText('b')],
      ], rows: [
        [
          [RText('x')],
        ],
      ]);
      final next = TableEditing.apply(ragged, TableOp.addColumn, (row: 1, col: 1));
      expect(next.rows.single, [_t('x'), const <RInline>[], const <RInline>[]]);
      expect(next.dir, 'rtl');
    });
  });
}
