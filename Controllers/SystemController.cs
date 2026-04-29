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
    }
}
