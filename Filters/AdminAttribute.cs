// 2026-04-25 02:33:09

namespace WebAPI.Filters {
    #region

    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.Mvc.Filters;
    using WebAPI.Controllers;
    using WebAPI.Struct;
    using WebAPI.Utils;

    #endregion

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class AdminAttribute : Attribute, IAuthorizationFilter {
        public void OnAuthorization(AuthorizationFilterContext context) {
            string? token = context.HttpContext.Request.Cookies["session"];
            if (token == null) {
                context.Result = new UnauthorizedResult();
                return;
            }

            Token<SessionEntry>? data = TokenList.find<SessionEntry>(token);
            if (data?.Value == null) {
                context.Result = new UnauthorizedResult();
                return;
            }

            User? user = User.find_with_id(data.Value.UserId);
            if (user is not { IsAdmin: true }) {
                context.Result = new UnauthorizedResult();
            }
        }
    }
}
