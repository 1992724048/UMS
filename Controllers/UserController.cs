// 2026-04-29 01:33:07

namespace WebAPI.Controllers {
    #region

    using System.Security.Cryptography;
    using System.Text;
    using Microsoft.AspNetCore.Mvc;
    using WebAPI.Filters;
    using WebAPI.Struct;
    using WebAPI.Utils;

    #endregion

    [ApiController, Route("api/[controller]/[action]")]
    public class UserController : ControllerBase {
        static readonly string ServerSecret = Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(32));

        /// <summary>用户登录</summary>
        /// <param name = "request" >登录凭证</param>
        /// <returns>cookie</returns>
        /// <response code = "200" >登录成功</response>
        /// <response code = "400" >验证码过期</response>
        /// <response code = "401" >输入不合法</response>
        /// <response code = "402" >用户名或密码错误</response>
        /// <response code = "403" >用户已被封禁</response>
        [HttpPost]
        public IActionResult login([FromBody] LoginRequest request) {
            if (!CaptchaController.verify(request.CaptchaToken, request.CaptchaCode)) {
                return this.Ok(new { code = 400, message = "验证码错误或已过期" });
            }

            if ((request.Username.Length < 8) || (request.Password.Length < 8)) {
                return this.Ok(new { code = 401, message = "用户名或密码至少 8 个字符" });
            }

            if (!Global.AllowedCharsRegex.IsMatch(request.Username) || !Global.AllowedCharsRegex.IsMatch(request.Password)) {
                return this.Ok(new { code = 401, message = "用户名或密码不符合输入要求" });
            }

            User? user = Global.EmailRegex.IsMatch(request.Username) ? Struct.User.find_with_email(request.Username) : Struct.User.find_with_name(request.Username);
            if (!user.HasValue || (user.Value.Password != Struct.User.hash(request.Password))) {
                return this.Ok(new { code = 402, message = "用户名或密码错误" });
            }

            if (user.Value.IsBanned) {
                return this.Ok(new { code = 403, message = "该账号已被封禁" });
            }

            string token = Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes($"{user.Value.Id}:{UserController.ServerSecret}:{DateTimeOffset.Now.ToUnixTimeMilliseconds()}")));
            Token<long> data = TokenList.generate<long>(token, TimeSpan.FromDays(7));
            data.Value = user.Value.Id;

            this.Response.Cookies.Append("session", token, new() { HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict, MaxAge = TimeSpan.FromDays(7) });
            return this.Ok(new { code = 200, message = "登录成功" });
        }

        /// <summary>获取用户列表</summary>
        /// <param name = "page" >页码，从 1 开始</param>
        /// <param name = "pageSize" >每页数量，默认 20</param>
        /// <returns>分页用户列表</returns>
        /// <response code = "200" >分页用户列表</response>
        /// <response code = "401" >未登录或无管理员权限</response>
        [HttpGet, Admin]
        public PageResult<User> list_users(int page = 1, int pageSize = 20) => Struct.User.list_page(page, pageSize);

        /// <summary>退出登录</summary>
        /// <returns>退出成功</returns>
        /// <response code = "200" >退出成功</response>
        [HttpPost]
        public IActionResult logout() {
            string? token = this.Request.Cookies["session"];
            if (token == null) {
                return this.Ok(new { code = 200, message = "ok" });
            }
            TokenList.remove(token);
            this.Response.Cookies.Append("session", "", new() { Expires = DateTimeOffset.UnixEpoch, HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict });
            return this.Ok(new { code = 200, message = "ok" });
        }

        /// <summary>用户注册</summary>
        /// <param name = "request" >注册信息</param>
        /// <returns>注册结果</returns>
        /// <response code = "200" >注册成功</response>
        /// <response code = "400" >输入不合法</response>
        /// <response code = "401" >验证码错误或已过期</response>
        /// <response code = "408" >邮箱已存在</response>
        /// <response code = "409" >用户名已存在</response>
        /// <response code = "500" >注册失败</response>
        [HttpPost]
        public IActionResult register([FromBody] RegisterRequest request) {
            if ((request.Username.Length < 8) || (request.Password.Length < 8)) {
                return this.Ok(new { code = 400, message = "用户名或密码至少 8 个字符" });
            }

            if (!Global.AllowedCharsRegex.IsMatch(request.Username) || !Global.AllowedCharsRegex.IsMatch(request.Password) || Global.EmailRegex.IsMatch(request.Username)) {
                return this.Ok(new { code = 400, message = "用户名或密码不符合输入要求" });
            }

            if (request.Email != null && !Global.EmailRegex.IsMatch(request.Email)) {
                return this.Ok(new { code = 409, message = "邮箱格式不合法" });
            }

            if (!CaptchaController.verify(request.CaptchaToken, request.CaptchaCode)) {
                return this.Ok(new { code = 401, message = "验证码错误或已过期" });
            }

            if (request.Email != null && Struct.User.find_with_email(request.Email).HasValue) {
                return this.Ok(new { code = 408, message = "邮箱已被注册" });
            }

            if (Struct.User.find_with_name(request.Username).HasValue) {
                return this.Ok(new { code = 409, message = "用户名已存在" });
            }

            User? user = Struct.User.create(request.Username, request.Password, request.Email ?? "", false);
            return user.HasValue ? this.Ok(new { code = 200, message = "注册成功" }) : this.Ok(new { code = 500, message = "注册失败" });
        }

        /// <summary>删除用户</summary>
        /// <param name = "id" >用户ID</param>
        /// <returns>结果</returns>
        /// <response code = "401" >未登录或非管理员</response>
        [HttpGet, Admin]
        public bool delete_user(int id) {
            User? user = Struct.User.find_with_id(id);
            return user != null && user.Value.delete();
        }

        /// <summary>更新用户</summary>
        /// <param name = "user" >用户信息</param>
        /// <returns>结果</returns>
        /// <response code = "401" >未登录或非管理员</response>
        /// <response code = "404" >未找到用户</response>
        /// <response code = "405" >输入不合法</response>
        /// <response code = "406" >用户名重复</response>
        /// <response code = "407" >邮箱重复</response>
        /// <response code = "408" >更新失败</response>
        [HttpPost, Admin]
        public IActionResult update_user([FromBody] User user) {
            User? data = Struct.User.find_with_id(user.Id);
            if (data == null) {
                return this.Ok(new { code = 404, message = "未找到用户" });
            }

            if ((user.Username.Length < 8) || (user.Password != "" && (user.Password.Length < 8))) {
                return this.Ok(new { code = 405, message = "用户名或密码至少 8 个字符" });
            }

            if (!Global.AllowedCharsRegex.IsMatch(user.Username) || (user.Password != "" && !Global.AllowedCharsRegex.IsMatch(user.Password)) || Global.EmailRegex.IsMatch(user.Username)) {
                return this.Ok(new { code = 405, message = "用户名或密码不符合输入要求" });
            }

            if (!Global.EmailRegex.IsMatch(user.Email)) {
                return this.Ok(new { code = 405, message = "邮箱格式不合法" });
            }

            if (user.Username != data.Value.Username && Struct.User.find_with_name(user.Username).HasValue) {
                return this.Ok(new { code = 406, message = "用户名重复" });
            }

            if (user.Email != data.Value.Email && Struct.User.find_with_email(user.Email).HasValue) {
                return this.Ok(new { code = 407, message = "邮箱重复" });
            }

            string password = data.Value.Password;
            data = user;
            data = data.Value with { Password = user.Password != "" ? Struct.User.hash(user.Password) : password };
            return this.Ok(!data.Value.update() ? new { code = 408, message = "更新失败" } : new { code = 200, message = "OK" });
        }

        /// <summary>检查当前会话是否为管理员</summary>
        /// <returns>管理员会话信息</returns>
        /// <response code = "200" >是管理员</response>
        /// <response code = "401" >未登录或非管理员</response>
        [HttpGet, Admin]
        public IActionResult admin_check() => this.Ok(new { code = 200, message = "admin" });

        /// <summary>登录请求</summary>
        /// <param name = "Username" >用户名（最少 8 个字符, 支持邮箱）</param>
        /// <param name = "Password" >密码（最少 8 个字符）</param>
        /// <param name = "CaptchaToken" >验证码 token</param>
        /// <param name = "CaptchaCode" >验证码内容</param>
        public record LoginRequest(string Username, string Password, string CaptchaToken, string CaptchaCode);

        /// <summary>注册请求</summary>
        /// <param name = "Username" >用户名（最少 8 个字符）</param>
        /// <param name = "Password" >密码（最少 8 个字符）</param>
        /// <param name = "Email" >邮箱（可选）</param>
        /// <param name = "CaptchaToken" >验证码 token</param>
        /// <param name = "CaptchaCode" >验证码内容</param>
        public record RegisterRequest(string Username, string Password, string? Email, string CaptchaToken, string CaptchaCode);
    }
}
