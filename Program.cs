// 2026-04-25 16:58:21

namespace WebAPI {
    #region

    using System.IO.Compression;
    using Microsoft.AspNetCore.ResponseCompression;
    using Microsoft.Extensions.FileProviders;
    using Microsoft.OpenApi;
    using Scalar.AspNetCore;
    using WebAPI.Database;
    using WebAPI.Utils.UMSystem;

    #endregion

    public static class Program {
        public static void Main(string[] args) {
            Config.load("cfg.toml");
            if (!Pool.create()) {
                Console.WriteLine("SQLite create failed");
                Thread.Sleep(10000);
                return;
            }

            WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

            // 配置HTTP压缩
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

            // 添加控制器和OpenApi文档
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
            
            var open_api = new Field<bool>("server::scalar_ui", true);
            if (open_api) {
                app.MapOpenApi();
                app.MapScalarApiReference(options => options.WithTitle("UMS API"));
            }

            // 添加静态文件目录
            string web_root = Path.Combine(AppContext.BaseDirectory, "web");
            if (!Directory.Exists(web_root)) {
                string alt = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "WebUI", "build", "web"));
                if (Directory.Exists(alt)) {
                    web_root = alt;
                }
            }
            if (Directory.Exists(web_root)) {
                app.UseStaticFiles(new StaticFileOptions { FileProvider = new PhysicalFileProvider(web_root), OnPrepareResponse = ctx => {
                    if (!app.Environment.IsDevelopment() && !ctx.File.Name.Equals("index.html", StringComparison.OrdinalIgnoreCase)) {
                        ctx.Context.Response.Headers["Cache-Control"] = "public, max-age=31536000, immutable";
                    }
                } });
            }

            app.UseHttpsRedirection();
            app.UseAuthorization();
            app.MapControllers();

            if (Directory.Exists(web_root)) {
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
