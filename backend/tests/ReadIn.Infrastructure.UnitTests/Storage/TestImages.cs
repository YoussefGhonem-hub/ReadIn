using System.Buffers.Binary;
using System.Text;
using SkiaSharp;

namespace ReadIn.Infrastructure.UnitTests.Storage;

/// <summary>Builds real encoded images (and hand-crafted malicious ones) in memory.</summary>
internal static class TestImages
{
    public static byte[] Encode(int width, int height, SKEncodedImageFormat format)
    {
        using var bitmap = new SKBitmap(width, height);
        using (var canvas = new SKCanvas(bitmap))
        {
            canvas.Clear(SKColors.SteelBlue);
            // A marker in the top-left corner lets tests check that orientation was applied.
            using var paint = new SKPaint { Color = SKColors.Red };
            canvas.DrawRect(0, 0, Math.Max(1, width / 4), Math.Max(1, height / 4), paint);
        }
        using var data = bitmap.Encode(format, 90);
        return data.ToArray();
    }

    /// <summary>
    /// A JPEG with an APP1 EXIF segment: orientation <paramref name="orientation"/> and an ImageDescription holding
    /// <paramref name="secret"/>, standing in for GPS data or a camera serial number.
    /// </summary>
    public static byte[] JpegWithExif(int width, int height, ushort orientation, string secret)
    {
        var jpeg = Encode(width, height, SKEncodedImageFormat.Jpeg);
        var text = Encoding.ASCII.GetBytes(secret + "\0");

        // TIFF (little endian): header, IFD0 with 2 entries, next-IFD = 0, then the description text.
        const int ifdOffset = 8;
        const int textOffset = ifdOffset + 2 + 2 * 12 + 4;
        var tiff = new byte[textOffset + text.Length];
        "II"u8.CopyTo(tiff);
        BinaryPrimitives.WriteUInt16LittleEndian(tiff.AsSpan(2), 42);
        BinaryPrimitives.WriteUInt32LittleEndian(tiff.AsSpan(4), ifdOffset);
        BinaryPrimitives.WriteUInt16LittleEndian(tiff.AsSpan(ifdOffset), 2);
        WriteEntry(tiff.AsSpan(ifdOffset + 2), tag: 0x010E, type: 2, count: (uint)text.Length, value: textOffset); // ImageDescription
        WriteEntry(tiff.AsSpan(ifdOffset + 14), tag: 0x0112, type: 3, count: 1, value: orientation);               // Orientation
        text.CopyTo(tiff, textOffset);

        var payload = "Exif\0\0"u8.ToArray().Concat(tiff).ToArray();
        var segment = new byte[4 + payload.Length];
        segment[0] = 0xFF;
        segment[1] = 0xE1;
        BinaryPrimitives.WriteUInt16BigEndian(segment.AsSpan(2), (ushort)(payload.Length + 2));
        payload.CopyTo(segment, 4);

        // Right after SOI (FF D8).
        return [.. jpeg[..2], .. segment, .. jpeg[2..]];

        static void WriteEntry(Span<byte> entry, ushort tag, ushort type, uint count, uint value)
        {
            BinaryPrimitives.WriteUInt16LittleEndian(entry, tag);
            BinaryPrimitives.WriteUInt16LittleEndian(entry[2..], type);
            BinaryPrimitives.WriteUInt32LittleEndian(entry[4..], count);
            BinaryPrimitives.WriteUInt32LittleEndian(entry[8..], value);
        }
    }

    /// <summary>
    /// A tiny PNG whose header claims <paramref name="width"/> × <paramref name="height"/>: decoding it would need
    /// gigabytes. The IHDR CRC is fixed up so the header itself is valid.
    /// </summary>
    public static byte[] PngClaiming(int width, int height)
    {
        var png = Encode(1, 1, SKEncodedImageFormat.Png);
        const int ihdrData = 8 + 8; // signature + length + "IHDR"
        BinaryPrimitives.WriteInt32BigEndian(png.AsSpan(ihdrData), width);
        BinaryPrimitives.WriteInt32BigEndian(png.AsSpan(ihdrData + 4), height);
        BinaryPrimitives.WriteUInt32BigEndian(png.AsSpan(ihdrData + 13), Crc32(png.AsSpan(12, 4 + 13)));
        return png;
    }

    /// <summary>The FourCC of every chunk in a WebP (RIFF) file.</summary>
    public static List<string> WebpChunks(byte[] webp)
    {
        var chunks = new List<string>();
        for (var offset = 12; offset + 8 <= webp.Length;)
        {
            chunks.Add(Encoding.ASCII.GetString(webp, offset, 4));
            var size = (int)BinaryPrimitives.ReadUInt32LittleEndian(webp.AsSpan(offset + 4));
            offset += 8 + size + (size & 1);
        }
        return chunks;
    }

    private static uint Crc32(ReadOnlySpan<byte> bytes)
    {
        var crc = 0xFFFFFFFFu;
        foreach (var b in bytes)
        {
            crc ^= b;
            for (var bit = 0; bit < 8; bit++) crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320u : crc >> 1;
        }
        return ~crc;
    }
}
