// 2026-05-07 16:19:26

namespace WebAPI.Utils {
    #region

    using System.Text.RegularExpressions;

    #endregion

    public static partial class Global {
        public static readonly Regex AllowedCharsRegex = Global.AllowedCharsRegex_();

        public static readonly Regex EmailRegex = Global.EmailRegex_();

        [GeneratedRegex(@"^[A-Za-z0-9!@#$%^&*()_+\-=\[\]{}|;:,.<>?]+$", RegexOptions.Compiled)]
        private static partial Regex AllowedCharsRegex_();

        [GeneratedRegex(@"^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$", RegexOptions.IgnoreCase | RegexOptions.Compiled, "zh-CN")]
        private static partial Regex EmailRegex_();
    }
}
