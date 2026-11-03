using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.FileProviders;
using ReadIn.Application.Common.Uploads;
using ReadIn.Infrastructure;

namespace ReadIn.Api.Uploads;

/// <summary>
/// Serves <c>/uploads</c> from the uploads folder (SPEC §24, ADR 0010). Only <c>.webp</c> is served, at any depth;
/// every other file is a 404, so nothing in the folder can ever be executed or rendered as a page.
/// </summary>
public static class UploadsStaticFiles
{
    public const string CorsPolicy = "uploads";

    public static WebApplication UseUploads(this WebApplication app)
    {
        var root = app.Services.PrepareUploadsFolder();

        var webpOnly = new FileExtensionContentTypeProvider();
        webpOnly.Mappings.Clear();
        webpOnly.Mappings[".webp"] = "image/webp";

        app.Map(UploadPath.Root, uploads =>
        {
            // GET for the web origin, so the web app can draw images into a canvas (quote cards).
            uploads.UseCors(CorsPolicy);
            uploads.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(root),
                ContentTypeProvider = webpOnly,
                ServeUnknownFileTypes = false,
                OnPrepareResponse = context =>
                {
                    var headers = context.Context.Response.Headers;
                    headers.XContentTypeOptions = "nosniff";
                    headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'; sandbox";
                    // File names are random GUIDs and never reused, so a file never changes.
                    headers.CacheControl = "public, max-age=31536000, immutable";
                },
            });
            uploads.Run(context =>
            {
                context.Response.StatusCode = StatusCodes.Status404NotFound;
                return Task.CompletedTask;
            });
        });

        return app;
    }
}
