using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Media;

/// <summary>API links in DTOs, built from <see cref="StorageOptions.PublicBaseUrl"/>, the API's public origin.</summary>
internal sealed class ApiUrls(IOptions<StorageOptions> options) : IApiUrls
{
    public const string BasePath = "/api/v1";

    public string Absolute(string path) => options.Value.PublicBaseUrl.TrimEnd('/') + BasePath + path;
}
