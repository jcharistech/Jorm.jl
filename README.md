# Jorm

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jcharistech.github.io/Jorm.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jcharistech.github.io/Jorm.jl/dev/)
[![Build Status](https://github.com/jcharistech/Jorm.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/jcharistech/Jorm.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/jcharistech/Jorm.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jcharistech/Jorm.jl)


---

# Jorm.jl
## Object-Relational Mapping for Julia

### Overview

`Jorm.jl` is a simple Julia package designed to simplify interactions between Julia code and databases. It provides a straightforward Object-Relational Mapping (ORM) layer, allowing you to work with databases using Julia structs and functions.
The current database support includes SQLite. 
+ Future  plan is to offer support for databases such as PostGreSQL, MySQL and more.

### Installation

To install `Jorm.jl`, use the Julia package manager:

```julia
using Pkg
Pkg.add("Jorm")
```

### Usage

#### Connecting to a Database

To connect to a SQLite database, use the `connect` function:

```julia
connection_string = Jorm.SQLiteConnectionString(database_name="example.db")
db = Jorm.connect(connection_string)
```

#### Creating Tables

Create a table based on a Julia struct. We omit the id since it is by default an autoincrement but you can still access it via `.id`

```julia
struct BlogArticle
    title::String
    content::String
end

tb = Jorm.tablename(BlogArticle)
Jorm.create_table(db, BlogArticle, tb)
```

#### CRUD Operations

Perform basic CRUD (Create, Read, Update, Delete) operations:

```julia
# Create a new record
data = BlogArticle("First Title", "My Blog Post")
Jorm.insert!(db, BlogArticle, data)

# Read all records
results = Jorm.read_all(db, BlogArticle)
for row in results
    @test row.id == 1
end

# Update an existing record
updated_data = BlogArticle("First Title", "Updated Blog Post")
Jorm.update!(db, BlogArticle, 1, updated_data)

# Read one record by ID
result = Jorm.read_one(db, BlogArticle, 1)
println(result)

# Delete a record
result = Jorm.delete!(db, BlogArticle, 1)
result = Jorm.read_one(db, BlogArticle, 1)
@test isempty(result)
```

#### Closing the Database Connection

Close the database connection and delete the database file if needed:

```julia
Jorm.disconnect(db)
Jorm.delete_db(connection_string)
```

### Example

Here is a complete example demonstrating the usage of `Jorm.jl`:

```julia

struct BlogArticle
     title::String
    content::String
end

connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
tb = Jorm.tablename(BlogArticle)
db = Jorm.connect(connection_string)
Jorm.create_table(db, BlogArticle, tb)

# Create a new record
data = BlogArticle("First Title", "My Blog Post")
Jorm.insert!(db, BlogArticle, data)

# Read all records
results = Jorm.read_all(db, BlogArticle)
for row in results
    @test row.id == 1
end

# Serialize the data
Jorm.serialize_to_list(results)

# Update an existing record
updated_data = BlogArticle("First Title", "Updated Blog Post")
Jorm.update!(db, BlogArticle, 1, updated_data)

# Read one record by ID
result = Jorm.read_one(db, BlogArticle, 1)
println(result)

# Read one record by key
result = Jorm.getfirst(db, BlogArticle,"title", "First Title")
println(result)




for row in results
    println(row.id)
    println(row.content)
end

# Delete a record
result = Jorm.delete!(db, BlogArticle, 1)
result = Jorm.read_one(db, BlogArticle, 1)
@test isempty(result)

# Close the database connection
Jorm.disconnect(db)
Jorm.delete_db(connection_string)

```

### API Documentation

For detailed API documentation, please refer to the [Jorm.jl API Documentation](https://jcharistech.github.io/Jorm.jl).

### Contributing

Contributions are welcome. 
Please open an issue or pull request on the [Jorm.jl GitHub repository](https://github.com/jcharistech/Jorm.jl).

### License

`Jorm.jl` is licensed under the MIT License. See [LICENSE.md](https://github.com/jcharistech/Jorm.jl/blob/main/LICENSE.md) for details.

### Acknowledgments

Special thanks to the Julia community and future contributors who have helped shape this package.

---
