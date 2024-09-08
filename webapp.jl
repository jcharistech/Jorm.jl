include("Jorm.jl")
using Oxygen
using StructTypes

# Define the model
struct BlogPost
    title::String
    content::String
end

# Support JSON serialization and deserialization
StructTypes.StructType(::Type{BlogPost}) = StructTypes.Struct()

# Connect to the database and create the table
connection_string = Jorm.SQLiteConnectionString(database_name="blog.db")
db = Jorm.connect(connection_string)
tb = Jorm.tablename(BlogPost)
Jorm.create_table(db, BlogPost, tb)

# Define CRUD endpoints
@post "/api/v1/blogs/" function(req::HTTP.Request)
    data = Oxygen.json(req, BlogPost)
    Jorm.insert!(db, BlogPost, data)
    return data
end

@get "/api/v1/blogs/" function(req::HTTP.Request)
    results = Jorm.read_all(db, BlogPost)
    return results
end

@get "/api/v1/blogs/{blog_id}" function(req::HTTP.Request, blog_id::Int)
    result = Jorm.read_one(db, BlogPost, blog_id)
    return result
end

@patch "/api/v1/blogs/{blog_id}" function(req::HTTP.Request, blog_id::Int)
    data = Oxygen.json(req, BlogPost)
    Jorm.update!(db, BlogPost, blog_id, data)
    return data
end

@delete "/api/v1/blogs/{blog_id}" function(req::HTTP.Request, blog_id::Int)
    result = Jorm.delete!(db, BlogPost, blog_id)
    return result
end

# Start the server
serve(port=8001)