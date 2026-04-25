// 2026-04-24 23:28:52

namespace WebAPI.Database {
    #region

    using System.Data.SQLite;
    using WebAPI.Struct;

    #endregion

    public static class Pool {
        const string DbPath = "data.db";
        public static SQLiteConnection get_connection() => new($"Data Source={Pool.DbPath};Version=3;");

        public static bool create() {
            bool is_new = !File.Exists(Pool.DbPath);
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS users\n(\n\tuid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tusername TEXT not null,\n\tpassword TEXT not null,\n\temail TEXT,\n\tcreate_time integer not null,\n\tis_admin integer not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS app_keys\n(\n\tkid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tkey_data TEXT not null,\n\tis_use integer not null,\n\tuse_time integer,\n\tadd_time integer not null,\n\tcreate_time integer not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS apps\n(\n\taid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tapp_name TEXT not null,\n\tapp_disable integer not null,\n\tcreate_time integer not null,\n\tkey_num integer not null,\n\tuser_num integer not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS app_user_data\n(\n\tid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tuser_id integer not null,\n\tapp_id integer not null,\n\tkey_id integer not null,\n\tcreate_time integer not null,\n\texpiration_time integer not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }

            if (!is_new) {
                return true;
            }
            using var insert_cmd = new SQLiteCommand("INSERT INTO users(username, password, email, is_admin, create_time) VALUES ('Admin', @password, '', 1, @create_time)", conn);
            insert_cmd.Parameters.AddWithValue("@password", User.hash("123456"));
            insert_cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());
            insert_cmd.ExecuteNonQuery();
            return true;
        }
    }
}
