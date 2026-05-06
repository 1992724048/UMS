// 2026-04-25 18:09:59

namespace WebAPI.Controllers {
    #region

    using System.Collections.Concurrent;
    using Microsoft.AspNetCore.Mvc;
    using WebAPI.Utils;

    #endregion

    [ApiController, Route("api/[controller]/[action]")]
    public class CaptchaController : ControllerBase {
        static readonly ConcurrentDictionary<string, string> IpTokenMap = new();

        /// <summary>获取验证码</summary>
        /// <returns>验证码 token 和 SVG 图像</returns>
        /// <response code = "200" >生成成功</response>
        [HttpGet]
        public CaptchaData get() {
            string ip = this.get_ip();
            if (CaptchaController.IpTokenMap.TryGetValue(ip, out string? old_token)) {
                TokenList.remove(old_token);
                CaptchaController.IpTokenMap.TryRemove(ip, out string _);
            }

            Token<string> token = TokenList.generate<string>();
            token.Value = Captcha.generate();

            CaptchaController.IpTokenMap[ip] = token.TokenString;
            return new(token.TokenString, Captcha.render(token.Value));
        }

        internal static bool verify(string token, string code) {
            Token<string>? data = TokenList.find<string>(token);
            if (data == null) {
                return false;
            }

            TokenList.remove(token);
            foreach (KeyValuePair<string, string> kv in CaptchaController.IpTokenMap) {
                if (kv.Value != token) {
                    continue;
                }
                CaptchaController.IpTokenMap.TryRemove(kv.Key, out string _);
                break;
            }

            return data.Value == code;
        }

        string get_ip() => this.HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        public record CaptchaData(string Token, string Svg);
    }
}
