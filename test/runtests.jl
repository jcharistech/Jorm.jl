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
@testset "Connection Tests" begin
    # Test with a valid connection string
    connection_string = Jorm.SQLiteConnectionString(database_name="test.db")
    db = Jorm.connect(connection_string)
    @test typeof(db) == SQLite.DB
    Jorm.disconnect(db)

end