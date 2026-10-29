///|
pub(all) enum RelationType {
  HasOne
  HasMany
  BelongsTo
} derive(Debug, Eq)

///|
pub(all) struct Relation {
  kind : RelationType
  name : String
  table : @db.Table
  foreign_key : String
  primary_key : String
}

///|
pub fn has_one(
  table : @db.Table,
  foreign_key : String,
  primary_key~ : String = "id",
  name~ : String = table.name,
) -> Relation {
  { kind: HasOne, name, table, foreign_key, primary_key, }
}

///|
pub fn has_many(
  table : @db.Table,
  foreign_key : String,
  primary_key~ : String = "id",
  name~ : String = table.name,
) -> Relation {
  { kind: HasMany, name, table, foreign_key, primary_key, }
}

///|
pub fn belongs_to(
  table : @db.Table,
  foreign_key : String,
  primary_key~ : String = "id",
  name~ : String = table.name,
) -> Relation {
  { kind: BelongsTo, name, table, foreign_key, primary_key, }
}
