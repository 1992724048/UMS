// 2026-04-25 19:17:58

namespace WebAPI {
    #region

    using System.IO.Compression;
    using Microsoft.AspNetCore.ResponseCompression;
    using Microsoft.Extensions.FileProviders;
    using Microsoft.OpenApi;
    using Scalar.AspNetCore;
    using WebAPI.Utils;
    using WebAPI.Utils.UMSystem;

    #endregion

    public static class Program {
        public static void Main(string[] args) {
            Config.load("cfg.toml");

            var server_port = new Field<int>("server::port", 443);
            var certificate = new Field<string>("server::certificate", "");
            var certificate_password = new Field<string>("server::certificate_password", "");

            Logger.log(LogLevel.Debug, $"启动端口: {server_port.Value}");
            Logger.log(LogLevel.Debug, $"证书路径: {certificate.Value}");

            WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
            builder.WebHost.ConfigureKestrel(options => {
                if ((server_port > 0) && (server_port <= 65535)) {
                    options.ListenAnyIP(server_port, listenOptions => {
                        if (builder.Environment.IsDevelopment()) {
                            listenOptions.UseHttps();
                        } else {
                            listenOptions.UseHttps(certificate, certificate_password);
                        }
                    });
                    Console.WriteLine($"HTTPS 端口已配置: {server_port}");
                } else {
                    Console.WriteLine("错误: 未配置有效的 HTTPS 端口");
                }
            });

            builder.Services.AddHttpsRedirection(options => {
                options.HttpsPort = server_port;
                options.RedirectStatusCode = StatusCodes.Status307TemporaryRedirect;
            });
            builder.WebHost.UseUrls();

            builder.Services.AddRequestDecompression();
            builder.Services.AddResponseCompression(options => {
                options.EnableForHttps = true;
                options.Providers.Add<BrotliCompressionProvider>();
                options.Providers.Add<GzipCompressionProvider>();
            });
            builder.Services.Configure<BrotliCompressionProviderOptions>(options => {
                options.Level = CompressionLevel.Optimal;
            });
            builder.Services.Configure<GzipCompressionProviderOptions>(options => {
                options.Level = CompressionLevel.Optimal;
            });

            builder.Services.AddControllers();
            builder.Services.AddOpenApi(options => {
                options.AddOperationTransformer<OpenApiXmlCommentsTransformer>();
                options.AddDocumentTransformer((document, _, _) => {
                    OpenApiComponents components = document.Components ??= new();
                    components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
                    components.SecuritySchemes.Add("session", new OpenApiSecurityScheme { Type = SecuritySchemeType.ApiKey, Name = "session", In = ParameterLocation.Cookie, Description = "登录会话 cookie（管理员接口需要管理员会话）" });
                    return Task.CompletedTask;
                });
            });

            WebApplication app = builder.Build();
            app.UseRequestDecompression();
            app.UseResponseCompression();
            app.UseHttpsRedirection();
            app.UseAuthorization();
            app.MapControllers();

            var open_api = new Field<bool>("server::scalar_ui", true);
            if (open_api) {
                app.MapOpenApi();
                app.MapScalarApiReference(options => options.WithTitle("UMS API"));
            }

            string web_root = Path.Combine(AppContext.BaseDirectory, "web");
            if (!Directory.Exists(web_root) && app.Environment.IsDevelopment()) {
                string alt = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "WebUI", "build", "web"));
                if (Directory.Exists(alt)) {
                    web_root = alt;
                }
            }

            if (Directory.Exists(web_root)) {
                app.UseStaticFiles(new StaticFileOptions { FileProvider = new PhysicalFileProvider(web_root), OnPrepareResponse = ctx => {
                    if (!app.Environment.IsDevelopment() && !ctx.File.Name.Equals("index.html", StringComparison.OrdinalIgnoreCase)) {
                        ctx.Context.Response.Headers.CacheControl = "public, max-age=31536000, immutable";
                    }
                } });

                app.Use(async (context, next) => {
                    await next();
                    if ((context.Response.StatusCode == 404) && !context.Request.Path.StartsWithSegments("/api", StringComparison.OrdinalIgnoreCase)) {
                        context.Response.StatusCode = 200;
                        context.Response.ContentType = "text/html";
                        await context.Response.SendFileAsync(Path.Combine(web_root, "index.html"));
                    }
                });
            }

            app.Run();
            Config.save();
        }
    }
}
