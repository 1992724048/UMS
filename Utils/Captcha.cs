// 2026-04-25 18:09:18

namespace WebAPI.Utils {
    #region

    using System.Text;

    #endregion

    public static class Captcha {
        const int CodeLen = 4;
        const string Chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        static readonly Random Rng = Random.Shared;

        public static string generate() => new(Enumerable.Range(0, Captcha.CodeLen).Select(_ => Captcha.Chars[Captcha.Rng.Next(Captcha.Chars.Length)]).ToArray());

        public static string render(string code) {
            var sb = new StringBuilder();
            const int w = 130;
            const int h = 48;
            sb.Append($"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{w}\" height=\"{h}\" viewBox=\"0 0 {w} {h}\">");
            sb.Append($"<rect width=\"{w}\" height=\"{h}\" fill=\"#f5f5f5\" rx=\"4\"/>");

            for (var i = 0; i < 3; i++) {
                int x1 = Captcha.Rng.Next(5, w / 2);
                int y1 = Captcha.Rng.Next(5, h - 5);
                int x2 = Captcha.Rng.Next(w / 2, w - 5);
                int y2 = Captcha.Rng.Next(5, h - 5);
                sb.Append($"<line x1=\"{x1}\" y1=\"{y1}\" x2=\"{x2}\" y2=\"{y2}\" stroke=\"#{Captcha.Rng.Next(160, 220):X2}{Captcha.Rng.Next(160, 220):X2}{Captcha.Rng.Next(160, 220):X2}\" stroke-width=\"1.5\"/>");
            }

            for (var i = 0; i < 30; i++) {
                int cx = Captcha.Rng.Next(5, w - 5);
                int cy = Captcha.Rng.Next(5, h - 5);
                int r = Captcha.Rng.Next(1, 3);
                sb.Append($"<circle cx=\"{cx}\" cy=\"{cy}\" r=\"{r}\" fill=\"#{Captcha.Rng.Next(140, 200):X2}{Captcha.Rng.Next(140, 200):X2}{Captcha.Rng.Next(140, 200):X2}\"/>");
            }

            int[] colors = [0x333333, 0x555555, 0x444444, 0x666666, 0x3a3a3a, 0x4a4a4a];
            int spacing = w / (code.Length + 1);
            for (var i = 0; i < code.Length; i++) {
                int x = (spacing * (i + 1)) - 6;
                int y = Captcha.Rng.Next(30, 40);
                int rotate = Captcha.Rng.Next(-12, 13);
                var color = $"#{colors[i % colors.Length]:X6}";
                sb.Append($"<text x=\"{x}\" y=\"{y}\" font-family=\"monospace,sans-serif\" font-size=\"26\" font-weight=\"bold\" fill=\"{color}\" transform=\"rotate({rotate}, {x}, {y})\">{code[i]}</text>");
            }

            sb.Append("</svg>");
            return sb.ToString();
        }
    }
}
