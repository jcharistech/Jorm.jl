module Jorm
using SQLite

# Write your package code here.
export RawSQL,@raw_sql,tablename
export connect,disconnect,SQLiteConnectionString

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



# crud as sql 
# crud 


end
