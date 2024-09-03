module Jorm
using SQLite
using DataFrames

# Write your package code here.
export RawSQL,@raw_sql,tablename
export connect,disconnect,SQLiteConnectionString
export create_table,delete_table
export read_one_sql,insert_sql,update_sql,delete_sql,filter_by_sql
export read_one,insert!,update!,delete!


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
    disconnect(db::SQLite.DB)
        -> Nothing

Close the connection to the SQLite database.
"""
function disconnect(db::SQLite.DB)::Nothing
    SQLite.close(db)
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
    create_table(db::SQLite.DB, model, tableName)
    Creates a table in the database based on the model.
"""
function create_table(db::SQLite.DB, model, tableName)
    fields = fieldnames(model)
    field_types = [typeof(getfield(model(), field)) for field in fields]
    field_definitions = [ "$(field) $(typeof_to_sql(field_type))" for (field, field_type) in zip(fields, field_types) ]
    query = "CREATE TABLE IF NOT EXISTS $tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, $(join(field_definitions, ", ")))"
    SQLite.execute!(db, query)
end

function typeof_to_sql(field_type)
        if field_type == Int
            return "INTEGER"
        elseif field_type == String
            return "TEXT"
        else
            error("Unsupported field type: $field_type")
        end
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
    delete_all(db::SQLite.DB, model) 
    Deletes all data in the table for the given model
"""
function delete_all!(db::SQLite.DB, model)
    query = "DELETE FROM $(tablename(model))"
    DBInterface.execute(db, query)
end




# Function to generate the SQL query for reading one record
function read_one_sql(model, id)
    query = "SELECT * FROM $(tablename(model)) WHERE id = ?"
    return query
end

# Function to generate the SQL query for creating a new record
function insert_sql(model, data)
    columns = join(fieldnames(model), ", ")
    placeholders = join(repeat("?", length(fieldnames(model))), ", ")
    query = "INSERT INTO $(tablename(model)) ($columns) VALUES ($placeholders)"
    return query
end

# Function to generate the SQL query for updating a record
function update_sql(model, id, data)
    columns = join([string(field, " = ?") for field in fieldnames(model)], ", ")
    query = "UPDATE $(tablename(model)) SET $columns WHERE id = ?"
    return query
end

# Function to generate the SQL query for deleting a record
function delete_sql(model, id)
    query = "DELETE FROM $(tablename(model)) WHERE id = ?"
    return query
end

# Wrapper function to display the SQL syntax
function show_sql(func, args...)
    if func == insert!
        return insert_sql(args, args)
    elseif func == update!
        return update_sql(args, args, args)
    elseif func == delete!
        return delete_sql(args, args)
    elseif func == read_one
        return read_one_sql(args, args)
    else
        error("Unsupported function")
    end
end

# CRUD functions using the above SQL generation and execution

"""
    read_one(db::SQLite.DB, model, id) 
    Returns a given model object when given the ID  
"""
function read_one(db::SQLite.DB, model, id)
    query = read_one_sql(model, id)
    params = Any[id]
    result = Jorm.execute_query(db, query, params)
    return result
end


"""
    insert!(db::SQLite.DB, model, data) 
    Insert or Add data to the DB for a given model
"""
function insert!(db::SQLite.DB, model, data)
    query = insert_sql(model, data)
    params = Any[getfield(data, field) for field in fieldnames(model)]
    Jorm.execute_query(db, query, params)
end


"""
    update!(db::SQLite.DB, model, id, data)
    Update data to the DB for a given model
"""
function update!(db::SQLite.DB, model, id, data)
    query = update_sql(model, id, data)
    params = Any[getfield(data, field) for field in fieldnames(model)]
    push!(params, id)
    Jorm.execute_query(db, query, params)
end


"""
    delete!(db::SQLite.DB, model, id)
    Delete data for a given model
"""
function delete!(db::SQLite.DB, model, id)
    query = delete_sql(model, id)
    params = Any[id]
    Jorm.execute_query(db, query, params)
end
# crud as sql 

# Define the function to filter data from the database
function filter_by_sql(table_name; kwargs...)
    # Initialize the WHERE clause
    where_clause = ""
    
    # Iterate over keyword arguments to build the WHERE clause
    conditions = []
    operator = get(kwargs, :operator, "AND")  # Default to AND if not specified
    
    for (key, value) in kwargs
        if key == :operator
            continue  # Skip the operator keyword
        elseif key isa Symbol
            push!(conditions, "$key = '$value'")
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
    return query
end
# crud 


end
