// 2026-04-29 01:33:07

namespace WebAPI.Controllers {
    #region

    using System.Collections.Concurrent;
    using System.Security.Cryptography;
    using System.Text;
    using Microsoft.AspNetCore.Mvc;
    using WebAPI.Filters;
    using WebAPI.Struct;

    #endregion

    public record SessionEntry(long UserId, long CreatedAt);

    [ApiController, Route("api/[controller]/[action]")]
    public class UserController : ControllerBase {
        const long SessionTtlMs = 7 * 24 * 60 * 60 * 1000L;
        public static readonly ConcurrentDictionary<string, SessionEntry?> Sessions = new();
        static readonly string ServerSecret = Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(32));

        static void cleanup_expired_sessions() {
            long cutoff = DateTimeOffset.Now.ToUnixTimeMilliseconds() - UserController.SessionTtlMs;
            foreach (string key in UserController.Sessions.Keys) {
                if (UserController.Sessions.TryGetValue(key, out SessionEntry? entry) && ((entry == null) || (entry.CreatedAt < cutoff))) {
                    UserController.Sessions.TryRemove(key, out SessionEntry _);
                }
            }
        }

        /// <summary>用户登录</summary>
        /// <param name = "request">登录凭证</param>
        /// <returns>session cookie</returns>
        /// <response code = "200">session cookie</response>
        /// <response code = "400">输入太短</response>
        /// <response code = "401">密码或用户名错误</response>
        [HttpPost]
        public IActionResult login([FromBody] LoginRequest request) {
            if ((request.Username.Length < 3) || (request.Password.Length < 3)) {
                return this.BadRequest();
            }

            if (!CaptchaController.verify(request.CaptchaToken, request.CaptchaCode)) {
                return this.Ok(new { code = 400, message = "验证码错误或已过期" });
            }

            User? user = Struct.User.find_with_name(request.Username);
            if (!user.HasValue || (user.Value.Password != Struct.User.hash(request.Password))) {
                return this.Ok(new { code = 401, message = "Username or password error" });
            }

            long now = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            string token = Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes($"{user.Value.Id}:{UserController.ServerSecret}:{now}")));
            UserController.Sessions[token] = new(user.Value.Id, now);
            UserController.cleanup_expired_sessions();

            this.Response.Cookies.Append("session", token, new() { HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict, MaxAge = TimeSpan.FromDays(7) });

            return this.Ok(new { code = 200, message = user.Value.to_json() });
        }

        /// <summary>获取用户列表</summary>
        /// <param name = "page">页码，从 1 开始</param>
        /// <param name = "pageSize">每页数量，默认 20</param>
        /// <returns>分页用户列表</returns>
        /// <response code = "200">分页用户列表</response>
        /// <response code = "401">未登录或无管理员权限</response>
        [HttpGet, Admin]
        public PageResult<User> list_users(int page = 1, int pageSize = 20) => Struct.User.list_page(page, pageSize);

        /// <summary>退出登录</summary>
        /// <returns>退出成功</returns>
        /// <response code = "200">退出成功</response>
        [HttpPost]
        public IActionResult logout() {
            string? token = this.Request.Cookies["session"];
            if (token == null) {
                return this.Ok(new { code = 200, message = "ok" });
            }
            UserController.Sessions.TryRemove(token, out SessionEntry _);
            this.Response.Cookies.Append("session", "", new() { Expires = DateTimeOffset.UnixEpoch, HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict });
            return this.Ok(new { code = 200, message = "ok" });
        }

        /// <summary>用户注册</summary>
        /// <param name = "request">注册信息</param>
        /// <returns>注册结果</returns>
        /// <response code = "200">注册成功</response>
        /// <response code = "400">验证码错误或输入不合法</response>
        /// <response code = "409">用户名已存在</response>
        [HttpPost]
        public IActionResult register([FromBody] RegisterRequest request) {
            if ((request.Username.Length < 3) || (request.Password.Length < 3)) {
                return this.Ok(new { code = 400, message = "用户名或密码至少 3 个字符" });
            }

            if (!CaptchaController.verify(request.CaptchaToken, request.CaptchaCode)) {
                return this.Ok(new { code = 400, message = "验证码错误或已过期" });
            }

            if (Struct.User.find_with_name(request.Username).HasValue) {
                return this.Ok(new { code = 409, message = "用户名已存在" });
            }

            User? user = Struct.User.create(request.Username, request.Password, request.Email ?? "", false);
            return user.HasValue ? this.Ok(new { code = 200, message = "注册成功" }) : this.Ok(new { code = 500, message = "注册失败" });
        }

        /// <summary>检查当前会话是否为管理员</summary>
        /// <returns>管理员会话信息</returns>
        /// <response code = "200">是管理员</response>
        /// <response code = "401">未登录或非管理员</response>
        [HttpGet, Admin]
        public IActionResult admin_check() => this.Ok(new { code = 200, message = "admin" });

        /// <summary>登录请求</summary>
        /// <param name = "Username">用户名（最少 3 个字符）</param>
        /// <param name = "Password">密码（最少 3 个字符）</param>
        /// <param name = "CaptchaToken">验证码 token</param>
        /// <param name = "CaptchaCode">验证码内容</param>
        public record LoginRequest(string Username, string Password, string CaptchaToken, string CaptchaCode);

        /// <summary>注册请求</summary>
        /// <param name = "Username">用户名（最少 3 个字符）</param>
        /// <param name = "Password">密码（最少 3 个字符）</param>
        /// <param name = "Email">邮箱（可选）</param>
        /// <param name = "CaptchaToken">验证码 token</param>
        /// <param name = "CaptchaCode">验证码内容</param>
        public record RegisterRequest(string Username, string Password, string? Email, string CaptchaToken, string CaptchaCode);
    }
}
