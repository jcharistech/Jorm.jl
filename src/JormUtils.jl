using Jorm

"""
    list_tables(connection_string::SQLiteConnectionString) 
    Returns the list of tables in DB 
"""
function list_tables(connection_string::Jorm.SQLiteConnectionString)
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


"""
    backup_sqlite_db(db::SQLite.DB, model) 
    # usage
    backup_sqlite_db("example.db", "example_backup.db")
    
"""
function backup_sqlite_db(db_path::String, backup_path::String)
    if isfile(db_path)
        cp(db_path, backup_path)
        println("SQLite database backed up successfully.")
    else
        println("SQLite database file not found.")
    end
end



"""
    backup_postgresql_db(db_name::String, host::String="localhost", user::String="postgres", password::String="", backup_file::String="backup.sql") 
    # Usage
    backup_postgresql_db("mydb", "localhost", "postgres", "mypassword", "backup.sql")
    
"""
function backup_postgresql_db(db_name::String, host::String="localhost", user::String="postgres", password::String="", backup_file::String="backup.sql")
    cmd = `pg_dump -h $host -U $user $db_name`
    if !isempty(password)
        cmd = `pg_dump -h $host -U $user -W $password $db_name`
    end
    output = read(cmd, String)
    open(backup_file, "w") do io
        write(io, output)
    end
    println("PostgreSQL database backed up successfully.")
end



