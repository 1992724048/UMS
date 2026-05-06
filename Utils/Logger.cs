// 2026-05-06 16:42:48

namespace WebAPI.Utils {
    #region

    using System.Data.SQLite;

    #endregion

    public enum LogLevel {
        Debug,
        Info,
        Warn,
        Error,
    }

    public static class Logger {
        static readonly SQLiteConnection? Connection;

        static Logger() {
            Logger.Connection = Logger.get_connection();
            Logger.Connection.Open();

            using var cmd = new SQLiteCommand(@"
                CREATE TABLE IF NOT EXISTS logger
                (
                    time    INTEGER NOT NULL,
                    level   TEXT    NOT NULL,
                    content TEXT
                );", Logger.Connection);

            cmd.ExecuteNonQuery();
        }

        public static void log(LogLevel level, string content) {
            if (Logger.Connection == null || string.IsNullOrWhiteSpace(content)) {
                return;
            }

            DateTimeOffset now = DateTimeOffset.UtcNow;
            long unix = now.ToUnixTimeSeconds();

            const string sql = "INSERT INTO logger (time, level, content) VALUES (@time, @level, @content);";

            using var cmd = new SQLiteCommand(sql, Logger.Connection);
            cmd.Parameters.AddWithValue("@time", unix);
            cmd.Parameters.AddWithValue("@level", level.ToString());
            cmd.Parameters.AddWithValue("@content", content);
            cmd.ExecuteNonQuery();

            Console.WriteLine($"[{now:yyyy-MM-dd HH:mm:ss}] [{level}] {content}");
        }

        public static List<LogData> get_logs(long startUnix, long endUnix) {
            var list = new List<LogData>();

            const string sql = "SELECT time, level, content FROM logger WHERE time BETWEEN @start AND @end;";

            using var cmd = new SQLiteCommand(sql, Logger.Connection);
            cmd.Parameters.AddWithValue("@start", startUnix);
            cmd.Parameters.AddWithValue("@end", endUnix);

            using SQLiteDataReader? reader = cmd.ExecuteReader();
            while (reader.Read()) {
                list.Add(new(DateTimeOffset.FromUnixTimeSeconds(reader.GetInt64(0)), Enum.Parse<LogLevel>(reader.GetString(1)), reader.GetString(2)));
            }

            return list;
        }

        static SQLiteConnection get_connection() => new("Data Source=log.db;Version=3;Page Size=4096;Cache Size=-64000;Journal Mode=WAL;Synchronous=NORMAL;Pooling=True;");

        public record LogData(DateTimeOffset Offset, LogLevel Level, string Content);
    }
}
