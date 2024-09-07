using Jorm
using Test
using SQLite


@testset "Raw SQL" begin
    # Write your tests here.
    @test @raw_sql("SELECT * FROM my_table;") == Jorm.RawSQL("SELECT * FROM my_table;")
end


@testset "Jorm.jl Utils" begin
    struct BlogModel
        id::Int 
        title::String 
    end 

    @test tablename(BlogModel) == "blog_model"
end


# Test that the connection is established successfully
@testset "Connections" begin
    # Test with a valid connection string
    connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
    db = Jorm.connect(connection_string)
    @test typeof(db) == SQLite.DB
    Jorm.disconnect(db)

end


struct BlogPost
    id::Int 
    title::String 
    content::String 
end

# Test setup: Create a temporary database for testing
function setup_test_db()
    db = SQLite.DB("test.db")
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY, name TEXT)")
    SQLite.execute(db, "INSERT INTO test_table (id, name) VALUES (1, 'John')")
    return db
end

# Test teardown: Close and delete the temporary database
function teardown_test_db(db)
    SQLite.close(db)
    rm("test.db")
end

@testset "Utils" begin
    @test Jorm.tablename(BlogPost) == "blog_post"
    @test @raw_sql("SELECT * FROM my_table") == Jorm.RawSQL("SELECT * FROM my_table")
end


# Test that the connection is established successfully
@testset "Invalid Connection" begin
    # Test with an invalid connection string (this should throw an error)
    invalid_connection_string = "invalid_path"
    @test_throws MethodError Jorm.connect(invalid_connection_string)
end

# Test that the query executes successfully and returns the correct result
@testset "Execute Query" begin
    db = setup_test_db()
    query = Jorm.RawSQL("SELECT * FROM test_table WHERE id = ?")
    params = Any["John"]
    result = Jorm.execute_query(db, query, params)
    for row in result
        @test row.id == 1
        @test row.name == "John"
    end
    # insert new 
    query2 = Jorm.RawSQL("INSERT INTO test_table (id, name) VALUES (?, ?)")
    params2 = Any[2, "Peter"]
    result2 = Jorm.execute_query(db, query2, params2)

    for row in result2
        @test row.id == 2
        @test row.name == "Peter"
    end
    query3 = Jorm.RawSQL("INSERT INTO test_table (id, name) VALUES (?, ?)")
    params3 = Any[3, "Petro"]
   
    result2df = Jorm.execute_query(db, query3, params3,toDF=true)
    # @test typeof(result2df) == DataFrame
    teardown_test_db(db)
end

@testset "List Tables" begin
    connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
    result = Jorm.list_tables(connection_string)
    for r in result
        @test r === nothing
    end
end


@testset "Show SQL Constructs" begin
    # Example usage:
    struct MyModel
        id::Int
        name::String
        age::Int
    end


    data = MyModel(1, "John Doe", 30)

    @test read_one_sql(MyModel).value == "SELECT * FROM my_model WHERE id = ?"
    @test insert_sql(MyModel).value == "INSERT INTO my_model (id, name, age) VALUES (?, ?, ?)"
    @test update_sql(MyModel).value == "UPDATE my_model SET id = ?, name = ?, age = ? WHERE id = ?"
    @test delete_sql(MyModel).value == "DELETE FROM my_model WHERE id = ?"
    @test read_all_sql(MyModel).value == "SELECT * FROM my_model"

end


# Test the create_table function
@testset "Create Table" begin

    struct Blog
        title::String
        content::String
    end

    connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
    tb = Jorm.tablename(Blog)
    db = Jorm.connect(connection_string)

    # Create the table
    Jorm.create_table(db, Blog, tb)

    # Check if the table exists
    result = Jorm.list_tables(connection_string)
    @test !isempty(result)

    # Close the database connection
    Jorm.disconnect(db)

    # Remove the test database file
    rm("test.db", force=true)
end

@testset "CRUD Test" begin
    struct BlogArticle
        title::String
        content::String
    end
    connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
    tb = Jorm.tablename(BlogArticle)
    db = Jorm.connect(connection_string)
    Jorm.create_table(db,BlogArticle,tb)
    
    # Create a new record
    data = BlogArticle("First Title","My Blog Post")
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


    for row in results
        @test row.id == 1
        @test row.content == "Updated Blog Post"
    end


    # Read one record by ID
    result = Jorm.delete!(db, BlogArticle, 1)
    result = Jorm.read_one(db, BlogArticle, 1)
    @test isempty(result)

    # Close the database connection
    Jorm.disconnect(db)
    Jorm.delete_db(connection_string)


end


# Test setup
@testset "Show Filter By SQL Constructs" begin
    @test Jorm.filter_by_sql("my_table", A = 4, B = "d") == (RawSQL("SELECT * FROM my_table WHERE A = '4' AND B = 'd'"), Any[4, "d"])
    @test Jorm.filter_by_sql("my_table", B = "d") == (RawSQL("SELECT * FROM my_table WHERE B = 'd'"), Any["d"])
    @test Jorm.filter_by_sql("my_table", A = 4, B = "d", operator = "OR") == (RawSQL("SELECT * FROM my_table WHERE A = '4' OR B = 'd'"), Any[4, "d"])

end



@testset "Group By SQL Constructs" begin
        # Example usage:
    table_name = "my_table"
    group_by_columns = ["column1", "column2"]
    select_columns = ["column1", "column2", "SUM(column3) AS total"]
    having_conditions = Dict("SUM(column3)" => 100)
    order_by_columns = ["column1", "column2"]

    query, params = Jorm.groupby_sql(table_name; group_by_columns, select_columns, having_conditions, order_by_columns)
    @test query == "SELECT [\"column1\", \"column2\", \"SUM(column3) AS total\"] FROM my_table GROUP BY column1, column2 HAVING SUM(column3) = ? ORDER BY column1, column2"
    
end