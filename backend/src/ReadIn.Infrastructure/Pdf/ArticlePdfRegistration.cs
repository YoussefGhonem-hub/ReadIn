using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Articles.Pdf;

namespace ReadIn.Infrastructure.Pdf;

internal static class ArticlePdfRegistration
{
    /// <summary>Article PDFs (SPEC F33): one Chromium, the build limits and the renderer, shared by every request.</summary>
    public static IServiceCollection AddArticlePdf(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<ArticlePdfOptions>(configuration.GetSection(ArticlePdfOptions.Section));
        services.AddSingleton<ChromiumBrowser>();
        services.AddSingleton<PdfBuildGate>();
        services.AddSingleton<IArticlePdfRenderer, ArticlePdfRenderer>();
        return services;
    }
}
