```@meta
CurrentModule = Jorm
```

# Jorm.jl
#### A Simple Object-Relational Mapping Library for Julia

### Overview

`Jorm.jl` is a simple Julia package designed to simplify interactions between Julia code and databases. It provides a straightforward Object-Relational Mapping (ORM) layer, allowing you to work with databases using Julia structs and functions.
The current database support include SQLite. 
+ Future supporting database will include PostGreSQL, MySQL and more.

You can use Jorm.jl as an ORM Layer with Oxygen.jl Framework to handle your database operations. The name `Jorm.jl` is a combination of `Julia` + `ORM`.

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


### Other Julia ORM Like Libraries
Jorm.jl is a simple and young ORM tool for working with Web Apps and Databases, but it's not ideal for all applications. For users with more specialized needs, consider using:
+ SearchLight.jl
+ FunnyORM.jl
+ SQLite.jl
+ LibPQ.jl
+ Wasabi.jl
+ etc
+ 

### Questions
If there is something you expect Jorm.jl to be capable of, but cannot figure out how to do, please reach out with questions. Additionally you can check out the introduction to Jorm.jl.


Documentation for [Jorm](https://github.com/jcharistech/Jorm.jl).

*Jesus Saves @JCharisTech*

