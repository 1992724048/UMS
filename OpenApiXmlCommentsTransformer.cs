// 2026-04-25 02:00:49

namespace WebAPI {
    #region

    using System.Reflection;
    using System.Xml.XPath;
    using Microsoft.AspNetCore.Mvc.Controllers;
    using Microsoft.AspNetCore.OpenApi;
    using Microsoft.OpenApi;
    using WebAPI.Filters;

    #endregion

    public class OpenApiXmlCommentsTransformer : IOpenApiOperationTransformer {
        readonly XPathNavigator? _nav;

        public OpenApiXmlCommentsTransformer() {
            var xml_file = $"{Assembly.GetEntryAssembly()!.GetName().Name}.xml";
            string xml_path = Path.Combine(AppContext.BaseDirectory, xml_file);
            if (!File.Exists(xml_path)) {
                return;
            }
            XPathDocument xml_doc = new(xml_path);
            this._nav = xml_doc.CreateNavigator();
        }

        public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken ct) {
            if ((this._nav == null) || context.Description.ActionDescriptor is not ControllerActionDescriptor action) {
                return Task.CompletedTask;
            }

            var member_name = $"M:{action.MethodInfo.DeclaringType!.FullName}.{action.MethodInfo.Name}(";
            XPathNavigator? summary = this._nav.SelectSingleNode($"//member[starts-with(@name, '{member_name}')]/summary");
            if (summary != null) {
                operation.Summary ??= summary.Value.Trim();
            }
            operation.Description = $"{context.Description.HttpMethod} /{context.Description.RelativePath}";

            XPathNavigator? returns = this._nav.SelectSingleNode($"//member[starts-with(@name, '{member_name}')]/returns");
            if ((returns != null) && (operation.Responses != null) && operation.Responses.TryGetValue("200", out IOpenApiResponse? ok_resp)) {
                ok_resp.Description = returns.Value.Trim();
            }
            
            XPathNodeIterator resp_nodes = this._nav.Select($"//member[starts-with(@name, '{member_name}')]/response");
            foreach (XPathNavigator node in resp_nodes) {
                string code = node.GetAttribute("code", "");
                string desc = node.Value.Trim();
                if (string.IsNullOrEmpty(code)) {
                    continue;
                }
                if ((operation.Responses != null) && operation.Responses.TryGetValue(code, out IOpenApiResponse? existing)) {
                    existing.Description = desc;
                } else {
                    operation.Responses?[code] = new OpenApiResponse { Description = desc };
                }
            }

            foreach (ParameterInfo param in action.MethodInfo.GetParameters()) {
                XPathNavigator? param_doc = this._nav.SelectSingleNode($"//member[starts-with(@name, '{member_name}')]/param[@name='{param.Name}']");
                if (param_doc == null) {
                    continue;
                }
                string text = param_doc.Value.Trim();
                IOpenApiParameter? op_param = operation.Parameters?.FirstOrDefault(p => p.Name == param.Name);
                op_param?.Description = text;
            }

            bool is_admin = (action.MethodInfo.GetCustomAttributes(typeof(AdminAttribute), false).Length > 0) || (action.ControllerTypeInfo.GetCustomAttributes(typeof(AdminAttribute), false).Length > 0);

            if (is_admin) {
                operation.Security = [
                    new() { [new("session")] = [] },
                    ];
            }

            return Task.CompletedTask;
        }
    }
}
