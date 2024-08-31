module Jorm

# Write your package code here.
export RawSQL,@raw_sql,tablename

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

# crud as sql 
# crud 


end
