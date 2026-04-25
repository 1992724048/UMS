// 2026-04-25 02:44:36

namespace WebAPI.Controllers {
    #region

    using Microsoft.AspNetCore.Mvc;
    using WebAPI.Filters;

    #endregion

    [ApiController, Route("api/[controller]/[action]")]
    public class SystemController : ControllerBase {
        /// <summary>获取服务器时间戳</summary>
        /// <returns>Unix 毫秒时间戳</returns>
        /// <response code = "200">Unix 毫秒时间戳</response>
        [HttpGet]
        public long time() => DateTimeOffset.Now.ToUnixTimeMilliseconds();

        /// <summary>检查当前会话是否为管理员</summary>
        /// <returns>管理员会话信息</returns>
        /// <response code = "200">是管理员</response>
        /// <response code = "401">未登录或非管理员</response>
        [HttpGet, Admin]
        public IActionResult admin_check() => this.Ok(new { code = 200, message = "admin" });
    }
}
