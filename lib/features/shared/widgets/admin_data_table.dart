import 'package:flutter/material.dart';

/// Advanced data table widget for admin portal
/// Based on Material Design 3 and Stitch design system
class AdminDataTable extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'Tidak ada data',
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.selectable = false,
    this.selectedRows = const {},
    this.onSelectionChanged,
    this.paginationRowsPerPage = 10,
    this.onPageChanged,
    this.totalRows,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final void Function(int rowIndex)? onRowTap;
  final bool isLoading;
  final String emptyMessage;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool selectable;
  final Set<int> selectedRows;
  final void Function(Set<int> selectedRows)? onSelectionChanged;
  final int paginationRowsPerPage;
  final void Function(int pageIndex)? onPageChanged;
  final int? totalRows;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  int _currentPage = 0;
  late Set<int> _selectedRows;

  @override
  void initState() {
    super.initState();
    _selectedRows = Set.from(widget.selectedRows);
  }

  @override
  void didUpdateWidget(AdminDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRows != widget.selectedRows) {
      _selectedRows = Set.from(widget.selectedRows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                widget.emptyMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final startRow = _currentPage * widget.paginationRowsPerPage;
    final endRow = startRow + widget.paginationRowsPerPage;
    final displayRows = widget.rows.sublist(
      startRow,
      endRow > widget.rows.length ? widget.rows.length : endRow,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DataTable(
                  columns: widget.columns,
                  rows: displayRows,
                  sortColumnIndex: widget.sortColumnIndex,
                  sortAscending: widget.sortAscending,
                  onSelectAll: widget.selectable
                      ? (isSelected) {
                          setState(() {
                            if (isSelected == true) {
                              for (int i = 0; i < displayRows.length; i++) {
                                _selectedRows.add(startRow + i);
                              }
                            } else {
                              for (int i = 0; i < displayRows.length; i++) {
                                _selectedRows.remove(startRow + i);
                              }
                            }
                          });
                          widget.onSelectionChanged?.call(_selectedRows);
                        }
                      : null,
                  dataRowMaxHeight: 56,
                  dataRowMinHeight: 48,
                  headingRowHeight: 48,
                  horizontalMargin: 12,
                  columnSpacing: 12,
                  dividerThickness: 0.5,
                  headingRowColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainer,
                  ),
                  dataRowColor: WidgetStatePropertyAll(
                    colorScheme.surface,
                  ),
                  showCheckboxColumn: widget.selectable,
                ),
              ),
            ),
          ),
        ),
        if (widget.rows.length > widget.paginationRowsPerPage)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan ${startRow + 1} - $endRow dari ${widget.totalRows ?? widget.rows.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() => _currentPage--);
                              widget.onPageChanged?.call(_currentPage);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Halaman sebelumnya',
                    ),
                    Text(
                      'Halaman ${_currentPage + 1} dari ${(widget.rows.length / widget.paginationRowsPerPage).ceil()}',
                      style: theme.textTheme.bodySmall,
                    ),
                    IconButton(
                      onPressed: endRow < widget.rows.length
                          ? () {
                              setState(() => _currentPage++);
                              widget.onPageChanged?.call(_currentPage);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Halaman berikutnya',
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Custom DataColumn for admin table
class AdminDataColumn extends DataColumn {
  const AdminDataColumn({
    required super.label,
    super.onSort,
    super.tooltip,
    this.width,
    this.alignment = Alignment.centerLeft,
  });

  final double? width;
  final Alignment alignment;
}

/// Custom DataCell for better styling
class AdminDataCell extends DataCell {
  const AdminDataCell(
    super.child, {
    super.onTap,
    super.placeholder = false,
    this.alignment = Alignment.centerLeft,
  });

  final Alignment alignment;
}
