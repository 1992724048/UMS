// 2026-04-24 23:57:36

namespace WebAPI.Struct {
    #region

    using System.Data.SQLite;
    using System.Text.Json;
    using WebAPI.Database;

    #endregion

    public class Key(string keyData) {
        static readonly JsonSerializerOptions JsonOptions = new();
        public long AddTime { get; set; }
        public long CreateTime { get; init; }
        public bool IsUse { get; set; }
        public string KeyData { get; set; } = keyData;
        public long? UseTime { get; set; }
        public long Id { get; init; }

        public static Key? create(string keyData) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("INSERT INTO app_keys(key_data, is_use, add_time, create_time) VALUES (@key_data, @is_use, @add_time, @create_time); SELECT last_insert_rowid();", conn);
            cmd.Parameters.AddWithValue("@key_data", keyData);
            cmd.Parameters.AddWithValue("@is_use", false);
            cmd.Parameters.AddWithValue("@add_time", 0L);
            cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());

            var new_id = (long)cmd.ExecuteScalar();
            return new_id > 0 ? new Key(keyData) { Id = new_id, AddTime = 0L } : null;
        }

        public static Key? find_with_id(long kid) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT kid, key_data, is_use, use_time, add_time, create_time FROM app_keys WHERE kid = @kid", conn);
            cmd.Parameters.AddWithValue("@kid", kid);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            if (!reader.Read()) {
                return null;
            }

            return new(reader.GetString(reader.GetOrdinal("key_data"))) { Id = reader.GetInt64(reader.GetOrdinal("kid")), IsUse = reader.GetBoolean(reader.GetOrdinal("is_use")), UseTime = reader.IsDBNull(reader.GetOrdinal("use_time")) ? null : reader.GetInt64(reader.GetOrdinal("use_time")), AddTime = reader.GetInt64(reader.GetOrdinal("add_time")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) };
        }

        public static Key? find_with_key_data(string keyData) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT kid, key_data, is_use, use_time, add_time, create_time FROM app_keys WHERE key_data = @key_data", conn);
            cmd.Parameters.AddWithValue("@key_data", keyData);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            if (!reader.Read()) {
                return null;
            }

            return new(reader.GetString(reader.GetOrdinal("key_data"))) { Id = reader.GetInt64(reader.GetOrdinal("kid")), IsUse = reader.GetBoolean(reader.GetOrdinal("is_use")), UseTime = reader.IsDBNull(reader.GetOrdinal("use_time")) ? null : reader.GetInt64(reader.GetOrdinal("use_time")), AddTime = reader.GetInt64(reader.GetOrdinal("add_time")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) };
        }

        public bool save() {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            if (this.Id <= 0) {
                return false;
            }

            using var cmd = new SQLiteCommand("UPDATE app_keys SET key_data = @key_data, is_use = @is_use, use_time = @use_time, add_time = @add_time WHERE kid = @id", conn);
            cmd.Parameters.AddWithValue("@id", this.Id);
            cmd.Parameters.AddWithValue("@key_data", this.KeyData);
            cmd.Parameters.AddWithValue("@is_use", this.IsUse);
            cmd.Parameters.AddWithValue("@use_time", (object?)this.UseTime ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@add_time", this.AddTime);

            return cmd.ExecuteNonQuery() > 0;
        }

        public string to_json() => JsonSerializer.Serialize(this, Key.JsonOptions);

        public static Key? from_json(string json) => JsonSerializer.Deserialize<Key>(json, Key.JsonOptions);

        public static PageResult<Key> list_page(int page = 1, int pageSize = 20) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var count_cmd = new SQLiteCommand("SELECT COUNT(*) FROM app_keys", conn);
            var total = (long)count_cmd.ExecuteScalar();

            using var cmd = new SQLiteCommand("SELECT kid, key_data, is_use, use_time, add_time, create_time FROM app_keys ORDER BY kid DESC LIMIT @limit OFFSET @offset", conn);
            cmd.Parameters.AddWithValue("@limit", pageSize);
            cmd.Parameters.AddWithValue("@offset", (page - 1) * pageSize);

            using SQLiteDataReader reader = cmd.ExecuteReader();
            var data = new List<Key>();
            while (reader.Read()) {
                data.Add(new(reader.GetString(reader.GetOrdinal("key_data"))) { Id = reader.GetInt64(reader.GetOrdinal("kid")), IsUse = reader.GetBoolean(reader.GetOrdinal("is_use")), UseTime = reader.IsDBNull(reader.GetOrdinal("use_time")) ? null : reader.GetInt64(reader.GetOrdinal("use_time")), AddTime = reader.GetInt64(reader.GetOrdinal("add_time")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) });
            }

            return new() { Data = data, Total = total, Page = page, PageSize = pageSize };
        }
    }
}
