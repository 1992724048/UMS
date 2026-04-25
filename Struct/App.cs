// 2026-04-24

namespace WebAPI.Struct {
    #region

    using System.Data.SQLite;
    using System.Text.Json;
    using WebAPI.Database;

    #endregion

    public class App(string appName) {
        static readonly JsonSerializerOptions JsonOptions = new();
        public string AppName { get; set; } = appName;
        public long CreateTime { get; init; }
        public bool IsDisabled { get; set; }
        public long KeyNum { get; set; }
        public long UserNum { get; set; }
        public long Id { get; init; }

        public static App? create(string appName) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("INSERT INTO apps(app_name, app_disable, create_time, key_num, user_num) VALUES (@app_name, @app_disable, @create_time, @key_num, @user_num); SELECT last_insert_rowid();", conn);
            cmd.Parameters.AddWithValue("@app_name", appName);
            cmd.Parameters.AddWithValue("@app_disable", false);
            cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());
            cmd.Parameters.AddWithValue("@key_num", 0);
            cmd.Parameters.AddWithValue("@user_num", 0);

            var new_id = (long)cmd.ExecuteScalar();
            return new_id > 0 ? new App(appName) { Id = new_id, CreateTime = DateTimeOffset.Now.ToUnixTimeMilliseconds() } : null;
        }

        public static App? find_with_name(string appName) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT aid, app_name, app_disable, create_time, key_num, user_num FROM apps WHERE app_name = @app_name", conn);
            cmd.Parameters.AddWithValue("@app_name", appName);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            if (!reader.Read()) {
                return null;
            }
            return new(reader.GetString(reader.GetOrdinal("app_name"))) { Id = reader.GetInt64(reader.GetOrdinal("aid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), IsDisabled = reader.GetBoolean(reader.GetOrdinal("app_disable")), KeyNum = reader.GetInt64(reader.GetOrdinal("key_num")), UserNum = reader.GetInt64(reader.GetOrdinal("user_num")) };
        }

        public static App? find_with_id(long appId) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT aid, app_name, app_disable, create_time, key_num, user_num FROM apps WHERE aid = @id", conn);
            cmd.Parameters.AddWithValue("@id", appId);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            if (!reader.Read()) {
                return null;
            }
            return new(reader.GetString(reader.GetOrdinal("app_name"))) { Id = reader.GetInt64(reader.GetOrdinal("aid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), IsDisabled = reader.GetBoolean(reader.GetOrdinal("app_disable")), KeyNum = reader.GetInt64(reader.GetOrdinal("key_num")), UserNum = reader.GetInt64(reader.GetOrdinal("user_num")) };
        }

        public bool save() {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            if (this.Id <= 0) {
                return false;
            }

            using var cmd = new SQLiteCommand("UPDATE apps SET app_name = @app_name, app_disable = @app_disable, key_num = @key_num, user_num = @user_num WHERE aid = @id", conn);
            cmd.Parameters.AddWithValue("@id", this.Id);
            cmd.Parameters.AddWithValue("@app_name", this.AppName);
            cmd.Parameters.AddWithValue("@app_disable", this.IsDisabled);
            cmd.Parameters.AddWithValue("@key_num", this.KeyNum);
            cmd.Parameters.AddWithValue("@user_num", this.UserNum);

            return cmd.ExecuteNonQuery() > 0;
        }

        public string to_json() => JsonSerializer.Serialize(this, App.JsonOptions);

        public static App? from_json(string json) => JsonSerializer.Deserialize<App>(json, App.JsonOptions);

        public static PageResult<App> list_page(int page = 1, int pageSize = 20) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var count_cmd = new SQLiteCommand("SELECT COUNT(*) FROM apps", conn);
            var total = (long)count_cmd.ExecuteScalar();

            using var cmd = new SQLiteCommand("SELECT aid, app_name, app_disable, create_time, key_num, user_num FROM apps ORDER BY aid DESC LIMIT @limit OFFSET @offset", conn);
            cmd.Parameters.AddWithValue("@limit", pageSize);
            cmd.Parameters.AddWithValue("@offset", (page - 1) * pageSize);

            using SQLiteDataReader reader = cmd.ExecuteReader();
            var data = new List<App>();
            while (reader.Read()) {
                data.Add(new(reader.GetString(reader.GetOrdinal("app_name"))) { Id = reader.GetInt64(reader.GetOrdinal("aid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), IsDisabled = reader.GetBoolean(reader.GetOrdinal("app_disable")), KeyNum = reader.GetInt64(reader.GetOrdinal("key_num")), UserNum = reader.GetInt64(reader.GetOrdinal("user_num")) });
            }

            return new() { Data = data, Total = total, Page = page, PageSize = pageSize };
        }
    }
}
