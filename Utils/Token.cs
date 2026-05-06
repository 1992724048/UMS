// 2026-05-06 15:18:53

namespace WebAPI.Utils {
    #region

    using System.Collections.Concurrent;
    using System.Timers;
    using NCrontab;

    #endregion

    public abstract class TokenBase {
        public required string TokenString { get; init; }
        public DateTimeOffset TimeOffset { get; init; }
        public TimeSpan Ttl { get; init; }
    }

    public class Token<T> : TokenBase {
        public T? Value { get; set; }
    }

    public static class TokenList {
        static readonly ConcurrentDictionary<string, TokenBase?> Tokens = new();
        static Timer? _cleanupTimer;
        static CrontabSchedule? _schedule;

        static TokenList() {
            TokenList.set_cleanup_schedule("0 4 * * *");
        }

        static void set_cleanup_schedule(string cronExpression) {
            TokenList._schedule = CrontabSchedule.Parse(cronExpression, new() { IncludingSeconds = false });
            TokenList.schedule_next_cleanup();
        }

        static void schedule_next_cleanup() {
            TokenList._cleanupTimer?.Stop();
            TokenList._cleanupTimer?.Dispose();

            if (TokenList._schedule == null) {
                return;
            }

            DateTime now = DateTime.Now;
            DateTime next_run = TokenList._schedule.GetNextOccurrence(now);
            TimeSpan interval = next_run - now;

            TokenList._cleanupTimer = new(interval.TotalMilliseconds);
            TokenList._cleanupTimer.Elapsed += (_, _) => {
                Logger.log(LogLevel.Info, $"本次清理 {TokenList.cleanup()} 个过期Token");
                TokenList.schedule_next_cleanup();
            };
            TokenList._cleanupTimer.AutoReset = false;
            TokenList._cleanupTimer.Start();

            Logger.log(LogLevel.Info, $"下次一次清理安排在: {next_run:yyyy-MM-dd HH:mm:ss} (Cron: {TokenList._schedule})");
        }

        public static Token<T> generate<T>(string token, TimeSpan ttl) {
            var token_obj = new Token<T> { TimeOffset = DateTimeOffset.UtcNow, TokenString = token, Ttl = ttl };
            TokenList.Tokens.AddOrUpdate(token, token_obj, (_, _) => token_obj);
            return token_obj;
        }

        public static Token<T> generate<T>(string token) => TokenList.generate<T>(token, TimeSpan.FromMinutes(5));

        public static Token<T> generate<T>(TimeSpan ttl) => TokenList.generate<T>(Guid.NewGuid().ToString("N"), ttl);

        public static Token<T> generate<T>() => TokenList.generate<T>(Guid.NewGuid().ToString("N"), TimeSpan.FromMinutes(5));

        public static Token<T>? find<T>(string token, bool autoRemoveExpired = true) {
            if (!TokenList.Tokens.TryGetValue(token, out TokenBase? obj)) {
                return null;
            }

            if (obj is not Token<T> value) {
                return null;
            }

            if ((obj.TimeOffset + obj.Ttl) >= DateTimeOffset.UtcNow) {
                return value;
            }

            if (autoRemoveExpired) {
                TokenList.Tokens.TryRemove(token, out TokenBase _);
            }
            return null;
        }

        public static bool remove(string token) => TokenList.Tokens.TryRemove(token, out TokenBase _);

        static int cleanup() {
            var expired = TokenList.Tokens.Where(kv => kv.Value != null && (kv.Value.TimeOffset + kv.Value.Ttl) < DateTimeOffset.UtcNow).Select(kv => kv.Key).ToList();
            return expired.Count(key => TokenList.Tokens.TryRemove(key, out TokenBase _));
        }
    }
}
