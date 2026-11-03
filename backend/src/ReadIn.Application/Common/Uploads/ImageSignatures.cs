namespace ReadIn.Application.Common.Uploads;

public enum ImageFormat
{
    Jpeg,
    Png,
    Webp,
}

/// <summary>
/// Detects the image format from its magic bytes. The file name and the Content-Type header are never trusted (SPEC §24).
/// </summary>
public static class ImageSignatures
{
    /// <summary>Bytes needed to recognize every supported format.</summary>
    public const int HeaderLength = 12;

    public static ImageFormat? Detect(ReadOnlySpan<byte> header)
    {
        if (header.StartsWith((ReadOnlySpan<byte>)[0xFF, 0xD8, 0xFF])) return ImageFormat.Jpeg;
        if (header.StartsWith((ReadOnlySpan<byte>)[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return ImageFormat.Png;
        if (header.Length >= HeaderLength && header[..4].SequenceEqual("RIFF"u8) && header[8..12].SequenceEqual("WEBP"u8))
            return ImageFormat.Webp;
        return null;
    }
}
