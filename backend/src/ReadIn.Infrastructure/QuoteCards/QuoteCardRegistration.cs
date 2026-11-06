using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Articles.QuoteCards;

namespace ReadIn.Infrastructure.QuoteCards;

internal static class QuoteCardRegistration
{
    /// <summary>Quote cards (SPEC F24): drawn on the article PDFs' Chromium and build slots (registered by <c>AddArticlePdf</c>).</summary>
    public static IServiceCollection AddQuoteCards(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<QuoteCardOptions>(configuration.GetSection(QuoteCardOptions.Section));
        services.AddSingleton<IQuoteCardRenderer, QuoteCardRenderer>();
        return services;
    }
}
