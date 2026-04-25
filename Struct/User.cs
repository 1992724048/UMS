// 2026-04-25 17:42:43

namespace WebAPI.Struct {
    #region

    using System.Data.SQLite;
    using System.Security.Cryptography;
    using System.Text;
    using System.Text.Json;
    using System.Text.Json.Serialization;
    using WebAPI.Database;

    #endregion

    public struct User(string username, string password, string email, bool isAdmin) {
        public string Username { get; set; } = username;

        [JsonIgnore]
        public string Password { get; set; } = password;

        public string Email { get; set; } = email;
        public bool IsAdmin { get; set; } = isAdmin;
        public long CreateTime { get; init; }

        public long Id { get; init; }

        public static string hash(string raw) => Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(raw)));

        public static User? create(string username, string password, string email, bool isAdmin) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("INSERT INTO users(username, password, email, is_admin, create_time) VALUES (@username, @password, @email, @isAdmin, @create_time); SELECT last_insert_rowid();", conn);
            cmd.Parameters.AddWithValue("@username", username);
            cmd.Parameters.AddWithValue("@password", User.hash(password));
            cmd.Parameters.AddWithValue("@email", email);
            cmd.Parameters.AddWithValue("@isAdmin", isAdmin);
            cmd.Parameters.AddWithValue("@create_time", DateTimeOffset.Now.ToUnixTimeMilliseconds());

            var new_id = (long)cmd.ExecuteScalar();
            return new_id > 0 ? new User(username, User.hash(password), email, isAdmin) { Id = new_id, CreateTime = DateTimeOffset.Now.ToUnixTimeMilliseconds() } : null;
        }

        public static User? find_with_name(string username) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT uid, username, password, email, is_admin, create_time FROM users WHERE username = @username", conn);
            cmd.Parameters.AddWithValue("@username", username);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            return reader.Read() ? new User(reader.GetString(reader.GetOrdinal("username")), reader.GetString(reader.GetOrdinal("password")), reader.GetString(reader.GetOrdinal("email")), reader.GetBoolean(reader.GetOrdinal("is_admin"))) { Id = reader.GetInt64(reader.GetOrdinal("uid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) } : null;
        }

        public static User? find_with_id(long uid) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var cmd = new SQLiteCommand("SELECT uid, username, password, email, is_admin, create_time FROM users WHERE uid = @uid", conn);
            cmd.Parameters.AddWithValue("@uid", uid);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            return reader.Read() ? new User(reader.GetString(reader.GetOrdinal("username")), reader.GetString(reader.GetOrdinal("password")), reader.GetString(reader.GetOrdinal("email")), reader.GetBoolean(reader.GetOrdinal("is_admin"))) { Id = reader.GetInt64(reader.GetOrdinal("uid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) } : null;
        }

        public bool save() {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            if (this.Id <= 0) {
                return false;
            }

            using var cmd = new SQLiteCommand("UPDATE users SET username = @username, password = @password, email = @email, is_admin = @isAdmin WHERE uid = @id", conn);
            cmd.Parameters.AddWithValue("@id", this.Id);
            cmd.Parameters.AddWithValue("@username", this.Username);
            cmd.Parameters.AddWithValue("@password", this.Password);
            cmd.Parameters.AddWithValue("@email", this.Email);
            cmd.Parameters.AddWithValue("@isAdmin", this.IsAdmin);

            return cmd.ExecuteNonQuery() > 0;
        }

        static readonly JsonSerializerOptions JsonOptions = new();

        public readonly string to_json() => JsonSerializer.Serialize(this, User.JsonOptions);

        public static User? from_json(string json) => JsonSerializer.Deserialize<User>(json, User.JsonOptions);

        public static PageResult<User> list_page(int page = 1, int pageSize = 20) {
            using SQLiteConnection conn = Pool.get_connection();
            conn.Open();

            using var count_cmd = new SQLiteCommand("SELECT COUNT(*) FROM users", conn);
            var total = (long)count_cmd.ExecuteScalar();

            using var cmd = new SQLiteCommand("SELECT uid, username, password, email, is_admin, create_time FROM users ORDER BY uid DESC LIMIT @limit OFFSET @offset", conn);
            cmd.Parameters.AddWithValue("@limit", pageSize);
            cmd.Parameters.AddWithValue("@offset", (page - 1) * pageSize);

            using SQLiteDataReader reader = cmd.ExecuteReader();
            var data = new List<User>();
            while (reader.Read()) {
                data.Add(new(reader.GetString(reader.GetOrdinal("username")), reader.GetString(reader.GetOrdinal("password")), reader.GetString(reader.GetOrdinal("email")), reader.GetBoolean(reader.GetOrdinal("is_admin"))) { Id = reader.GetInt64(reader.GetOrdinal("uid")), CreateTime = reader.GetInt64(reader.GetOrdinal("create_time")) });
            }

            return new() { Data = data, Total = total, Page = page, PageSize = pageSize };
        }
    }
}
