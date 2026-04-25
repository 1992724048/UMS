// 2026-04-24

namespace WebAPI.Struct {
    #region

    using System.Data.SQLite;
    using System.Text.Json;
    using WebAPI.Database;

    #endregion

    public class AppUserData(long userId, long appId, long keyId) {
        static readonly JsonSerializerOptions JsonOptions = new();
        public long AppId { get; set; } = appId;
        public long CreateTime { get; init; }
        public long ExpirationTime { get; set; }
        public long KeyId { get; set; } = keyId;
        public long UserId { get; set; } = userId;
        public long Id { get; init; }

        public static AppUserData? create(long userId, long appId, long keyId, long expirationTime) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("INSERT INTO app_user_data(user_id, app_id, key_id, expiration_time, create_time) VALUES (@user_id, @app_id, @key_id, @expiration_time, @create_time); SELECT last_insert_rowid();", conn);
            cmd.Parameters.AddWithValue("@user_id", userId);
            cmd.Parameters.AddWithValue("@app_id", appId);
            cmd.Parameters.AddWithValue("@key_id", keyId);
            cmd.Parameters.AddWithValue("@expiration_time", expirationTime);
            cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());

            var new_id = (long)cmd.ExecuteScalar();
            return new_id > 0 ? new AppUserData(userId, appId, keyId) { Id = new_id, CreateTime = DateTimeOffset.Now.ToUnixTimeMilliseconds(), ExpirationTime = expirationTime } : null;
        }

        public static AppUserData? find_with_id(long id) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT id, user_id, app_id, key_id, create_time, expiration_time FROM app_user_data WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("@id", id);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            if (!reader.Read()) {
                return null;
            }

            return new(reader.GetInt64(reader.GetOrdinal("user_id")), reader.GetInt64(reader.GetOrdinal("app_id")), reader.GetInt64(reader.GetOrdinal("key_id"))) { Id = reader.GetInt64(reader.GetOrdinal("id")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), ExpirationTime = reader.GetInt64(reader.GetOrdinal("expiration_time")) };
        }

        public static List<AppUserData> find_with_user_id(long userId) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT id, user_id, app_id, key_id, create_time, expiration_time FROM app_user_data WHERE user_id = @user_id", conn);
            cmd.Parameters.AddWithValue("@user_id", userId);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            var results = new List<AppUserData>();
            while (reader.Read()) {
                results.Add(new(reader.GetInt64(reader.GetOrdinal("user_id")), reader.GetInt64(reader.GetOrdinal("app_id")), reader.GetInt64(reader.GetOrdinal("key_id"))) { Id = reader.GetInt64(reader.GetOrdinal("id")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), ExpirationTime = reader.GetInt64(reader.GetOrdinal("expiration_time")) });
            }
            return results;
        }

        public static List<AppUserData> find_with_app_id(long appId) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT id, user_id, app_id, key_id, create_time, expiration_time FROM app_user_data WHERE app_id = @app_id", conn);
            cmd.Parameters.AddWithValue("@app_id", appId);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            var results = new List<AppUserData>();
            while (reader.Read()) {
                results.Add(new(reader.GetInt64(reader.GetOrdinal("user_id")), reader.GetInt64(reader.GetOrdinal("app_id")), reader.GetInt64(reader.GetOrdinal("key_id"))) { Id = reader.GetInt64(reader.GetOrdinal("id")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), ExpirationTime = reader.GetInt64(reader.GetOrdinal("expiration_time")) });
            }
            return results;
        }

        public static List<AppUserData> find_with_key_id(long keyId) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT id, user_id, app_id, key_id, create_time, expiration_time FROM app_user_data WHERE key_id = @key_id", conn);
            cmd.Parameters.AddWithValue("@key_id", keyId);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            var results = new List<AppUserData>();
            while (reader.Read()) {
                results.Add(new(reader.GetInt64(reader.GetOrdinal("user_id")), reader.GetInt64(reader.GetOrdinal("app_id")), reader.GetInt64(reader.GetOrdinal("key_id"))) { Id = reader.GetInt64(reader.GetOrdinal("id")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), ExpirationTime = reader.GetInt64(reader.GetOrdinal("expiration_time")) });
            }
            return results;
        }

        public bool save() {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            if (this.Id <= 0) {
                return false;
            }

            using var cmd = new SQLiteCommand("UPDATE app_user_data SET user_id = @user_id, app_id = @app_id, key_id = @key_id, expiration_time = @expiration_time WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("@id", this.Id);
            cmd.Parameters.AddWithValue("@user_id", this.UserId);
            cmd.Parameters.AddWithValue("@app_id", this.AppId);
            cmd.Parameters.AddWithValue("@key_id", this.KeyId);
            cmd.Parameters.AddWithValue("@expiration_time", this.ExpirationTime);

            return cmd.ExecuteNonQuery() > 0;
        }

        public string to_json() => JsonSerializer.Serialize(this, AppUserData.JsonOptions);

        public static AppUserData? from_json(string json) => JsonSerializer.Deserialize<AppUserData>(json, AppUserData.JsonOptions);

        public static PageResult<AppUserData> list_page(int page = 1, int pageSize = 20) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var count_cmd = new SQLiteCommand("SELECT COUNT(*) FROM app_user_data", conn);
            var total = (long)count_cmd.ExecuteScalar();

            using var cmd = new SQLiteCommand("SELECT id, user_id, app_id, key_id, create_time, expiration_time FROM app_user_data ORDER BY id DESC LIMIT @limit OFFSET @offset", conn);
            cmd.Parameters.AddWithValue("@limit", pageSize);
            cmd.Parameters.AddWithValue("@offset", (page - 1) * pageSize);

            using SQLiteDataReader reader = cmd.ExecuteReader();
            var data = new List<AppUserData>();
            while (reader.Read()) {
                data.Add(new(reader.GetInt64(reader.GetOrdinal("user_id")), reader.GetInt64(reader.GetOrdinal("app_id")), reader.GetInt64(reader.GetOrdinal("key_id"))) { Id = reader.GetInt64(reader.GetOrdinal("id")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")), ExpirationTime = reader.GetInt64(reader.GetOrdinal("expiration_time")) });
            }

            return new() { Data = data, Total = total, Page = page, PageSize = pageSize };
        }
    }
}
