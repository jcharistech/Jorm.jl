module Jorm
using SQLite
using DataFrames
using LibPQ

# Write your package code here.
export RawSQL,@raw_sql,tablename,getmodel_data
export connect,disconnect,SQLiteConnectionString
export create_table,delete_table
export read_one_sql,insert_sql,update_sql,delete_sql,filter_by_sql,groupby_sql,read_all_sql
export read_one,insert!,update!,delete!,read_all
export delete_db,drop_all_tables


"""
    struct RawSQL  
        value: String 

A struct to hold raw SQL Queries
"""
struct RawSQL
    value::String 
end


"""
    macro raw_sql(v::String)
        -> RawSQL

Create a `RawSQL` instance from a given SQL query string.
"""
macro raw_sql(v::String)
    return :(RawSQL($v))
end


# """
#     to_raw_sql(data::String)
#         -> RawSQL

# Create a `RawSQL` instance from a given SQL query string.
# """
# function to_raw_sql(data::String)
#     query = RawSQL(data)
#     return query
# end

# Model  ==> TableName
# Struct ==> TableName 

"""
    tablename(model) 
    Generate the table name for a given model. The table name is derived from the model's type name, converting it to lowercase and joining words with underscores.
struct MyModel end
println(tablename(MyModel))  # Output: "my_model"

"""
function tablename(model)
      return join("_$text" for text in lowercase.(split(String(Base.typename(model).name), r"(?=[A-Z])")))[2:end]
end


# connection to db 

Base.@kwdef struct SQLiteConnectionString
    database_name::String
end

Base.@kwdef struct PostgreSQLConnectionString 
    endpoint::String
    username::String
    password::String
    port::Int
    database_name::String
end
# use LibPQ.jl 

"""
    connect(connection_string::String)
        -> SQLite.DB

Establish a connection to an SQLite database using the provided connection string.
"""
function connect(connection_string::SQLiteConnectionString)
    db = SQLite.DB(connection_string.database_name)
    return db
end

"""
    connect(connection_string::String)
        -> LibPQ.Connection

Establish a connection to an SQLite database using the provided connection string.
"""
function connect(connection_string::PostgreSQLConnectionString)
    LibPQ.Connection(
        "host=" * connection_string.endpoint * " user=" * connection_string.username * " password=" * connection_string.password * " port=" * string(connection_string.port) * " dbname=" * connection_string.database_name
    )
end

"""
    disconnect(db::SQLite.DB)
        -> Nothing

Close the connection to the SQLite database.
"""
function disconnect(db::SQLite.DB)::Nothing
    SQLite.close(db)
    return nothing
end


"""
    disconnect(db::LibPQ.Connection)
        -> Nothing

Close the connection to the PostgreSQL database.
"""
function disconnect(db::LibPQ.Connection)::Nothing
    LibPQ.close(db)
    return nothing
end

"""
    execute_query(db::SQLite.DB, query::RawSQL, params::Vector{Any}=Any[]) 
    Returns the executed sql 
"""
function execute_query(db::SQLite.DB, query::RawSQL, params::Vector{Any}=Any[];toDF::Bool=false)
    if toDF
        return SQLite.DBInterface.execute(db, query.value, params) |> DataFrame
    else
        return SQLite.DBInterface.execute(db, query.value, params) 
    end
end


"""
    execute_query(db::LibPQ.Connection, query::RawSQL, params::Vector{Any}=Any[]) 
    Returns the executed sql 
"""
function execute_query(db::LibPQ.Connection, query::RawSQL, params::Vector{Any}=Any[];toDF::Bool=false)
    if toDF
        return LibPQ.execute(db, query.value, params) |> DataFrame
    else
        return LibPQ.execute(db, query.value, params) 
    end
end

"""
    create_table(db::SQLite.DB, model, tableName)
    Creates a table in the database based on the model.
"""
function create_table(db::SQLite.DB, model::Type, tableName)
    # Create an instance of the model to access its fields
    fields = fieldnames(model)
    field_types = fieldtypes(model)
    # field_types = [typeof(getfield(model, field)) for field in fields]
    field_definitions = [ "$(field) $(typeof_to_sql(field_type))" for (field, field_type) in zip(fields, field_types) ]
    query = "CREATE TABLE IF NOT EXISTS $tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, $(join(field_definitions, ", ")))"
    DBInterface.execute(db, query)
end

# Define the typeof_to_sql function
function typeof_to_sql(field_type)
    if field_type == Int64
        return "INTEGER"
    elseif field_type == Float64
        return "REAL"
    elseif field_type == String
        return "TEXT"
    elseif field_type == DateTime
        return "TEXT"  # SQLite does not have a specific datetime type, so we use TEXT
    else
        error("Unsupported type: $field_type")
    end
end

function getmodel_data(model)
    fields = fieldnames(model)
    field_types = [typeof(getfield(model, field)) for field in fields]
    field_definitions = [ "$(field) $(typeof_to_sql(field_type))" for (field, field_type) in zip(fields, field_types) ]
    return field_definitions
end

function delete_table(db::SQLite.DB, model) 
    query = "DROP TABLE IF EXISTS $(tablename(model))"
    DBInterface.execute(db, query)
end

"""
    list_tables(connection_string::SQLiteConnectionString) 
    Returns the list of tables in DB 
"""
function list_tables(connection_string::SQLiteConnectionString)
    # Connect to the database
    db = SQLite.DB(connection_string.database_name)
    # Get the list of tables
    tables = SQLite.tables(db)
    SQLite.close(db)
    return tables
    
end

"""
    ls_tables(connection_string::SQLiteConnectionString) 
    Returns the list of tables in DB 
"""
function ls_tables(connection_string::Jorm.SQLiteConnectionString)
    db = SQLite.DB(connection_string.database_name)
    query = "SELECT name FROM sqlite_master WHERE type='table'"
    results = DBInterface.execute(db, query)
    tables = [row.name for row in results]
    close(db)
    return tables
end


"""
    drop_all_tables(connection_string::SQLiteConnectionString) 
    Delete or Drop all tables for a given table 
"""
function drop_all_tables(connection_string::Jorm.SQLiteConnectionString)
    # Connect to the database
    db = SQLite.DB(connection_string.database_name)

    # Retrieve table names
    query = "SELECT name FROM sqlite_master WHERE type='table'"
    results = DBInterface.execute(db, query)
    tables = [row.name for row in results]

    # Drop each table
    for table in tables
        if table != "sqlite_sequence"  # Avoid dropping sqlite_sequence which is used for autoincrement
            drop_query = "DROP TABLE IF EXISTS $table"
            DBInterface.execute(db, drop_query)
        end
    end

    # Close the database connection
    close(db)
end

"""
    delete_db(connection_string::Jorm.SQLiteConnectionString)
    Deletes or removes a an sqlite database

"""
function delete_db(connection_string::Jorm.SQLiteConnectionString)
    db_path = connection_string.database_name
    if isfile(db_path)
        rm(db_path)
        println("SQLite database deleted successfully.")
    else
        println("SQLite database file not found.")
    end
end


"""
    delete_db(connection_string::Jorm.PostgreSQLConnectionString)
    Deletes or removes a an PostgreSQL database

"""
function delete_db(connection_string::Jorm.PostgreSQLConnectionString)
    # conn = LibPQ.connect("host=$host user=$user password=$password dbname=postgres")
    # query = "DROP DATABASE $db_name"
    LibPQ.Connection(
        "host=" * connection_string.endpoint * " user=" * connection_string.username * " password=" * connection_string.password * " port=" * string(connection_string.port) * " dbname=" * connection_string.database_name
    )
    query = "DROP DATABASE $db_name"
    try
        LibPQ.execute(conn, query)
        println("PostgreSQL database deleted successfully.")
    catch e
        println("Error deleting PostgreSQL database: $e")
    finally
        LibPQ.close(conn)
    end
end


"""
    delete_all(db::SQLite.DB, model) 
    Deletes all data in the table for the given model
"""
function delete_all!(db::SQLite.DB, model)
    query = "DELETE FROM $(tablename(model))"
    DBInterface.execute(db, query)
end




# Function to generate the SQL query for reading one record
function read_one_sql(model)
    query = "SELECT * FROM $(tablename(model)) WHERE id = ?"
    return RawSQL(query)
end

# Function to generate the SQL query for reading all record
function read_all_sql(model)
    query = "SELECT * FROM $(tablename(model))"
    return RawSQL(query)
end

# Function to generate the SQL query for creating a new record
function insert_sql(model)
    columns = join(fieldnames(model), ", ")
    placeholders = join(repeat("?", length(fieldnames(model))), ", ")
    query = "INSERT INTO $(tablename(model)) ($columns) VALUES ($placeholders)"
    return RawSQL(query)
end

# Function to generate the SQL query for updating a record
function update_sql(model)
    columns = join([string(field, " = ?") for field in fieldnames(model)], ", ")
    query = "UPDATE $(tablename(model)) SET $columns WHERE id = ?"
    return RawSQL(query)
end

# Function to generate the SQL query for deleting a record
function delete_sql(model)
    query = "DELETE FROM $(tablename(model)) WHERE id = ?"
    return RawSQL(query)
end

# Wrapper function to display the SQL syntax
function show_sql(func, args...)
    if func == insert!
        return insert_sql(args)
    elseif func == update!
        return update_sql(args)
    elseif func == delete!
        return delete_sql(args)
    elseif func == read_one
        return read_one_sql(args)
    elseif func == read_all
        return read_all_sql(args)
    else
        error("Unsupported function")
    end
end

 
"""
    filter_by_sql(table_name; kwargs...)
    Filter data by condition from the database
"""
function filter_by_sql(table_name; kwargs...)
    # Initialize the WHERE clause
    where_clause = ""
    
    # Iterate over keyword arguments to build the WHERE clause
    conditions = []
    operator = get(kwargs, :operator, "AND")  # Default to AND if not specified
    params = []

    for (key, value) in kwargs
        if key == :operator
            continue  # Skip the operator keyword
        elseif key isa Symbol
            push!(conditions, "$key = '$value'")
            push!(params, value)
        elseif key isa Expr && key.head == :call
            # Handle binary operations like :A > 3
            push!(conditions, string(key))
        elseif key isa Expr && key.head == :comparison
            # Handle comparisons like :A > 3
            push!(conditions, string(key))
        else
            error("Unsupported condition type")
        end
    end
    
    # Combine conditions with the specified operator
    if !isempty(conditions)
        where_clause = "WHERE " * join(conditions, " $operator ")
    end
    
    # Construct the SQL query
    query = "SELECT * FROM $table_name $where_clause"
    return RawSQL(query), params
end

# CRUD functions using the above SQL generation and execution
"""
    read_one(db::SQLite.DB, model, id) 
    Returns a given model object when given the ID  
"""
function read_one(db::SQLite.DB, model, id)
    query = read_one_sql(model)
    params = Any[id]
    result = Jorm.execute_query(db, query, params)
    return result
end

"""
    read_all(db::SQLite.DB, model) 
    Returns all data of a given model object 
"""
function read_all(db::SQLite.DB, model)
    query = read_all_sql(model)
    result = Jorm.execute_query(db, query)
    return result
end


"""
    insert!(db::SQLite.DB, model::Type, data) 
    Insert or Add data to the DB for a given model
"""
function insert!(db::SQLite.DB, model::Type, data)
    query = insert_sql(model)
    params = Any[getfield(data, field) for field in fieldnames(model)]
    Jorm.execute_query(db, query, params)
end


"""
    update!(db::SQLite.DB, model, id, data)
    Update data to the DB for a given model
"""
function update!(db::SQLite.DB, model, id, data)
    query = update_sql(model)
    params = Any[getfield(data, field) for field in fieldnames(model)]
    push!(params, id)
    Jorm.execute_query(db, query, params)
end


"""
    delete!(db::SQLite.DB, model, id)
    Delete data for a given model
"""
function delete!(db::SQLite.DB, model, id)
    query = delete_sql(model)
    params = Any[id]
    Jorm.execute_query(db, query, params)
end


"""
    filter_by(db::SQLite.DB, model, table_name; kwargs...) 
    Returns the result of the given condition from the Database. This uses `SELECT`
"""
function filter_by(db::SQLite.DB, model, table_name; kwargs...)
    query,params = filter_by_sql(table_name;kwargs)
    result = Jorm.execute_query(db, query, params)
    return result
end


"""
    groupby_sql(table_name; group_by_columns, select_columns = "*", having_conditions = nothing, order_by_columns = nothing) 
    Returns the result of the given condition from the Database. This uses `SELECT`
"""
function groupby_sql(table_name; group_by_columns, select_columns = "*", having_conditions = nothing, order_by_columns = nothing)
    # Initialize the SELECT clause
    select_clause = select_columns

    # Initialize the GROUP BY clause
    group_by_clause = "GROUP BY " * join(group_by_columns, ", ")

    # Initialize the HAVING clause if conditions are provided
    having_clause = ""
    having_params = []
    if having_conditions !== nothing
        having_conditions_str = []
        for (column, value) in having_conditions
            push!(having_conditions_str, "$column = ?")
            push!(having_params, value)
        end
        having_clause = "HAVING " * join(having_conditions_str, " AND ")
    end

    # Initialize the ORDER BY clause if columns are provided
    order_by_clause = ""
    if order_by_columns !== nothing
        order_by_clause = "ORDER BY " * join(order_by_columns, ", ")
    end

    # Construct the SQL query using SQLStrings.jl
    query = "SELECT $select_clause FROM $table_name $group_by_clause"
    if !isempty(having_clause)
        query = "$query $having_clause"
    end
    if !isempty(order_by_clause)
        query = "$query $order_by_clause"
    end

    return query, having_params
end




end
