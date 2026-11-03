using Mapster;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Uploads;

/// <summary>
/// MediaAsset → DTO (SPEC §6.4). Paths are stored relative to the uploads root; the URLs are made absolute with the
/// <see cref="Common.Interfaces.IFileStorage"/> passed as the <c>storage</c> map parameter (see <see cref="MediaMapping"/>).
/// </summary>
public sealed class MediaMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<MediaVariant, MediaVariantDto>()
            .Map(d => d.Url, s => MediaMapping.Url(s.Path));

        config.NewConfig<MediaAssetPage, MediaPageDto>()
            .Map(d => d.ThumbUrl, s => MediaMapping.Url(s.ThumbPath))
            .Map(d => d.ViewUrl, s => MediaMapping.Url(s.ViewPath));

        config.NewConfig<MediaAsset, MediaAssetDto>()
            .Map(d => d.SizeBytes, s => s.OriginalSizeBytes)
            .Map(d => d.PagesReady, s => s.Pages.Count)
            .Map(d => d.Pages, s => s.Pages.OrderBy(p => p.PageNo));
    }
}

/// <summary>Runs a media mapping with the storage that turns stored paths into public URLs.</summary>
public static class MediaMapping
{
    private const string StorageKey = "storage";

    public static string Url(string path) =>
        ((Common.Interfaces.IFileStorage)MapContext.Current!.Parameters[StorageKey]).GetPublicUrl(path);

    public static MediaAssetDto ToDto(this MediaAsset asset, TypeAdapterConfig config, Common.Interfaces.IFileStorage storage)
    {
        using var scope = new MapContextScope();
        scope.Context.Parameters[StorageKey] = storage;
        return asset.Adapt<MediaAssetDto>(config);
    }

    public static TDestination Map<TSource, TDestination>(TSource source, TypeAdapterConfig config, Common.Interfaces.IFileStorage storage)
    {
        using var scope = new MapContextScope();
        scope.Context.Parameters[StorageKey] = storage;
        return source.Adapt<TDestination>(config)!;
    }
}
