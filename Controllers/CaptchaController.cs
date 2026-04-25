// 2026-04-25 18:09:59

namespace WebAPI.Controllers {
    #region

    using System.Collections.Concurrent;
    using Microsoft.AspNetCore.Mvc;
    using WebAPI.Utils;

    #endregion

    [ApiController, Route("api/[controller]/[action]")]
    public class CaptchaController : ControllerBase {
        static readonly ConcurrentDictionary<string, CaptchaEntry> Store = new();
        static readonly TimeSpan Ttl = TimeSpan.FromMinutes(5);

        /// <summary>获取验证码</summary>
        /// <returns>验证码 token 和 SVG 图像</returns>
        /// <response code = "200">token + svg</response>
        [HttpGet]
        public IActionResult get() {
            CaptchaController.cleanup();

            var token = Guid.NewGuid().ToString("N");
            string code = Captcha.generate();

            CaptchaController.Store[token] = new(code, DateTimeOffset.UtcNow);

            return this.Ok(new { token, svg = Captcha.render(code) });
        }

        internal static bool verify(string token, string code) {
            if (CaptchaController.Store.TryRemove(token, out CaptchaEntry? entry)) {
                return entry.Code.Equals(code, StringComparison.OrdinalIgnoreCase) && ((DateTimeOffset.UtcNow - entry.CreatedAt) <= CaptchaController.Ttl);
            }
            return false;
        }

        static void cleanup() {
            DateTimeOffset cutoff = DateTimeOffset.UtcNow - CaptchaController.Ttl;
            foreach (string key in CaptchaController.Store.Keys) {
                if (CaptchaController.Store.TryGetValue(key, out CaptchaEntry? entry) && (entry.CreatedAt < cutoff)) {
                    CaptchaController.Store.TryRemove(key, out CaptchaEntry _);
                }
            }
        }

        record CaptchaEntry(string Code, DateTimeOffset CreatedAt);
    }
}
