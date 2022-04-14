# Materialize Avro File Sources Example

Materialize supports Avro files as a source.

https://materialize.com/docs/sql/create-source/file/

### Prerequisites

You will need to have the following installed:

- [Install Materialize](https://materialize.com/docs/install/).
- Install Avro CLI: `pip3 install avro`

### Creating an Avro file

Let's start by creating a simple schema file called `schema.avsc`.

```json
{
    "name": "row",
    "type": "record",
    "fields": [
      {"name": "a", "type": "long"},
      {"name": "b", "type": "int"}
    ]
}
```

Next, create a file called `records.json` and write the following JSON data:

```json
{"a": 1, "b": 2}
{"a": 3, "b": 4}
{"a": 5, "b": 6}
{"a": 7, "b": 8}
{"a": 9, "b": 10}
```

Finally, use the `avro` CLI to create your Avro file:

```bash
avro write --schema schema.avsc --input-type json --output records.ocf records.json
```

You can then use `avro cat` to read the file:

```bash
avro cat records.ocf
```

### Creating an Avro file source

Once we have the Avro file, we can create a source that reads from it.

First connect to the Materialize instace:

```sql
psql -U materialize -h localhost -p 6875
```

And create the source:

```sql
CREATE SOURCE avro_source
  FROM AVRO OCF '/local/path/records.ocf'
  WITH (tail = true);
```

Create a materialized view:

```sql
CREATE MATERIALIZED VIEW avro_view
  AS SELECT * FROM avro_source;
```

Query the materialized view:

```sql
SELECT * FROM avro_view;
```

### Useful Links

- [`CREATE SOURCE`: Local files](https://materialize.com/docs/sql/create-source/file/)
- [Materialize Cloud](https://materialize.com/cloud/)
- [Avro Introduction](https://streamingdata.io/systems/avro/)