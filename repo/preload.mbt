///|
priv struct PreloadRelation {
  relation : Relation
  condition : @sql.Cond?
}

///|
pub struct Preloader {
  priv database : DB
  priv relations : Array[PreloadRelation]
}

///|
pub fn DB::preload(self : DB, relations : Array[Relation]) -> Preloader {
  let database = self
  let loader = { database, relations: [], }
  loader.then_preload(relations)
}

///|
pub fn DB::preload_cond(
  self : DB,
  relation : Relation,
  condition : @sql.Cond,
) -> Preloader {
  { database: self, relations: [{ relation, condition: Some(condition), }], }
}

///|
pub fn preload(relations : Array[Relation]) -> Preloader raise RepoError {
  current_db().preload(relations)
}

///|
pub fn Preloader::then_preload(
  self : Preloader,
  relations : Array[Relation],
) -> Preloader {
  for relation in relations {
    self.relations.push({ relation, condition: None, })
  }
  self
}

///|
pub fn Preloader::then_preload_cond(
  self : Preloader,
  relation : Relation,
  condition : @sql.Cond,
) -> Preloader {
  self.relations.push({ relation, condition: Some(condition), })
  self
}

///|
pub fn Preloader::exec(
  self : Preloader,
  primary_records : Array[Record],
) -> Unit raise {
  if primary_records.length() == 0 {
    return
  }
  for preload in self.relations {
    self.load_relation(preload, primary_records)
  }
}

///|
fn Preloader::load_relation(
  self : Preloader,
  preload : PreloadRelation,
  primary_records : Array[Record],
) -> Unit raise {
  let relation = preload.relation
  let primary_key = match relation.kind {
    BelongsTo => relation.foreign_key
    _ => relation.primary_key
  }
  let related_key = match relation.kind {
    BelongsTo => relation.primary_key
    _ => relation.foreign_key
  }
  let keys = collect_keys(primary_records, primary_key)
  if keys.length() == 0 {
    assign_relations(primary_records, relation, primary_key, [])
    return
  }
  let related_table = schema_ref(relation.table)
  let in_relation = @sql.in_cond(
    @sql.val(related_table.field(related_key)),
    keys.map(key => @sql.val(key)),
  )
  let condition = match preload.condition {
    Some(extra) => @sql.all_of([in_relation, extra])
    None => in_relation
  }
  let related_records = find_maps(
    self.database,
    @sql.select_fields([related_table.all_fields()])
    .from_table(related_table)
    .where_(condition),
  )
  assign_relations(primary_records, relation, primary_key, related_records)
}

///|
fn collect_keys(records : Array[Record], key : String) -> Array[Int64] {
  let seen : Map[Int64, Bool] = Map([])
  let keys : Array[Int64] = []
  for record in records {
    match record.get(key) {
      Some(value) =>
        match value_as_int64(value) {
          Some(id) =>
            if !seen.contains(id) {
              seen[id] = true
              keys.push(id)
            }
          None => ()
        }
      None => ()
    }
  }
  keys
}

///|
fn assign_relations(
  primary_records : Array[Record],
  relation : Relation,
  primary_key : String,
  related_records : Array[Record],
) -> Unit {
  let related_key = match relation.kind {
    BelongsTo => relation.primary_key
    _ => relation.foreign_key
  }
  for primary in primary_records {
    let id = match primary.get(primary_key) {
      Some(value) => value_as_int64(value)
      None => None
    }
    let matches : Array[Record] = []
    match id {
      Some(expected) =>
        for related in related_records {
          match related.get(related_key) {
            Some(value) =>
              if value_as_int64(value) == Some(expected) {
                matches.push(related)
              }
            None => ()
          }
        }
      None => ()
    }
    match relation.kind {
      HasMany =>
        primary[relation.name] = @sql.Value::Array(
          matches.map(record => @sql.Value::Object(record)),
        )
      _ =>
        primary[relation.name] = match matches.get(0) {
          Some(record) => @sql.Value::Object(record)
          None => @sql.Value::Null
        }
    }
  }
}
