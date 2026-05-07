// 2026-04-24 23:28:52

namespace WebAPI.Database {
    #region

    using System.Data.SQLite;
    using WebAPI.Struct;

    #endregion

    public static class Conn {
        const string DbPath = "data.db";

        static Conn() {
            bool first = !File.Exists(Conn.DbPath);
            using SQLiteConnection conn = Conn.get_connection();
            conn.Open();

            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS users\n(\n\tuid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tusername TEXT not null,\n\tpassword TEXT not null,\n\temail TEXT default \"\",\n\tcreate_time integer default (strftime('%s','now') * 1000) not null,\n\tis_admin integer default false not null,\n\tis_banned integer default false not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS app_keys\n(\n\tkid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tkey_data TEXT not null,\n\tis_use integer default false not null,\n\tuse_time integer default 0,\n\tadd_time integer default 0 not null,\n\tcreate_time integer default (strftime('%s','now') * 1000) not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS apps\n(\n\taid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tapp_name TEXT not null,\n\tapp_disable integer default false not null,\n\tcreate_time integer default (strftime('%s','now') * 1000) not null,\n\tkey_num integer default 0 not null,\n\tuser_num integer default 0 not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }
            using (var cmd = new SQLiteCommand("CREATE TABLE IF NOT EXISTS app_user_data\n(\n\tid integer not null\n\t\tconstraint id\n\t\t\tprimary key autoincrement,\n\tuser_id integer not null,\n\tapp_id integer not null,\n\tkey_id integer not null,\n\tcreate_time integer default (strftime('%s','now') * 1000) not null,\n\texpiration_time integer default 0 not null\n);", conn)) {
                cmd.ExecuteNonQuery();
            }

            if (!first) {
                return;
            }

            using var insert_cmd = new SQLiteCommand("INSERT INTO users(username, password, email, is_admin, create_time) VALUES ('Admin123', @password, '', 1, @create_time)", conn);
            insert_cmd.Parameters.AddWithValue("@password", User.hash("12345678"));
            insert_cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());
            insert_cmd.ExecuteNonQuery();
        }

        public static SQLiteConnection get_connection() => new($"Data Source={Conn.DbPath};Version=3;Page Size=4096;Cache Size=-64000;Journal Mode=WAL;Synchronous=NORMAL;Pooling=True");
    }
}
