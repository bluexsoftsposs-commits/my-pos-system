import 'package:drift/drift.dart';

class SalesTable extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get userId => text()();
  RealColumn get total => real()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real()();
  RealColumn get discount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get status => text()();
  TextColumn get notes => text()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}