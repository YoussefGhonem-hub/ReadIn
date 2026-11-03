using FluentValidation;
using Mapster;
using MapsterMapper;
using Mediator;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Users;

namespace ReadIn.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediator((MediatorOptions options) =>
        {
            options.ServiceLifetime = ServiceLifetime.Scoped;
            options.GenerateTypesAsInternal = true;
            // Order matters (SPEC §6.3): Logging → Authorization → Validation → Caching. Personalization wraps the cache
            // so caller-specific fields are never stored in it (ADR 0011).
            options.PipelineBehaviors =
            [
                typeof(LoggingBehavior<,>),
                typeof(AuthorizationBehavior<,>),
                typeof(ValidationBehavior<,>),
                typeof(PersonalizationBehavior<,>),
                typeof(CachingBehavior<,>),
            ];
        });

        services.AddSingleton(CreateMapperConfig());
        services.AddScoped<IMapper, ServiceMapper>();

        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly, includeInternalTypes: true);

        services.AddHybridCache();
        services.AddSingleton<IRDocProcessor, RDocProcessor>();
        services.AddScoped<IUserAccessService, UserAccessService>();
        services.AddScoped<MeReader>();
        services.AddScoped<SessionIssuer>();
        services.AddScoped<AuditTrail>();
        services.AddScoped<PasswordConfirmation>();
        services.AddScoped<IdentityConfirmation>();
        services.AddScoped<PasswordSignIn>();
        services.AddScoped<UploadReferences>();
        services.AddScoped<UploadCleanup>();
        services.AddScoped<Features.Uploads.IMediaQuota, Features.Uploads.MediaQuota>();
        services.AddScoped<Features.Uploads.MediaFiles>();
        services.AddScoped<Features.Articles.ArticleAttachmentsReader>();

        AddDomainEventHandlers(services);
        return services;
    }

    /// <summary>All Mapster <see cref="IRegister"/> classes in Application, compiled into one config (SPEC §6.4).</summary>
    public static TypeAdapterConfig CreateMapperConfig()
    {
        var config = new TypeAdapterConfig();
        config.Scan(typeof(DependencyInjection).Assembly);
        return config;
    }

    private static void AddDomainEventHandlers(IServiceCollection services)
    {
        var handlerInterface = typeof(IDomainEventHandler<>);
        var registrations = typeof(DependencyInjection).Assembly.GetTypes()
            .Where(t => t is { IsAbstract: false, IsInterface: false })
            .SelectMany(t => t.GetInterfaces()
                .Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == handlerInterface)
                .Select(i => (Service: i, Implementation: t)));

        foreach (var (service, implementation) in registrations)
            services.AddScoped(service, implementation);
    }
}
