using Jorm
using Test

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