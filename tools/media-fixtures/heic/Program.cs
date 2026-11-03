using System.Buffers.Binary;
using System.Text;
using ImageMagick;
using SkiaSharp;

// Generates the image fixtures for backend/tests/fixtures/media.
var probeDir = args[0];
var outDir = args[1];
Directory.CreateDirectory(outDir);

// 1. Real HEVC-coded HEIC: hvcC + sample from an ffmpeg MP4, wrapped in a minimal HEIF container.
var mp4 = File.ReadAllBytes(Path.Combine(probeDir, "frame.mp4"));
var hvcC = FindBox(mp4, "hvcC") ?? throw new InvalidOperationException("hvcC not found");
var mdat = FindBox(mp4, "mdat") ?? throw new InvalidOperationException("mdat not found");
var sample = mdat[8..];
var heic = BuildHeif(hvcC, sample, 640, 480);
File.WriteAllBytes(Path.Combine(outDir, "sample.heic"), heic);
using (var m = new MagickImage(heic, new MagickReadSettings { Format = MagickFormat.Heic }))
    Console.WriteLine($"heic: {heic.Length} bytes, decodes as {m.Width}x{m.Height}");

// 2. JPEG 1200x800 with EXIF orientation 6 (display = 800x1200) and GPS + camera tags.
using (var bmp = Gradient(1200, 800, SKColors.SteelBlue, SKColors.Orange))
{
    // Mark the top-left (stored) corner red so orientation can be asserted after rotation.
    using (var canvas = new SKCanvas(bmp)) canvas.DrawRect(0, 0, 120, 120, new SKPaint { Color = SKColors.Red });
    var jpeg = bmp.Encode(SKEncodedImageFormat.Jpeg, 90).ToArray();
    using var img = new MagickImage(jpeg);
    var exif = new ExifProfile();
    exif.SetValue(ExifTag.Orientation, (ushort)6);
    exif.SetValue(ExifTag.Make, "ReadInTestCam");
    exif.SetValue(ExifTag.Model, "Fixture-1");
    exif.SetValue(ExifTag.GPSLatitudeRef, "N");
    exif.SetValue(ExifTag.GPSLatitude, [new Rational(30, 1), new Rational(2, 1), new Rational(0, 1)]);
    exif.SetValue(ExifTag.GPSLongitudeRef, "E");
    exif.SetValue(ExifTag.GPSLongitude, [new Rational(31, 1), new Rational(14, 1), new Rational(0, 1)]);
    img.SetProfile(exif);
    img.Orientation = OrientationType.RightTop; // ImageMagick writes this into EXIF Orientation (6)
    img.Write(Path.Combine(outDir, "exif-rotated.jpg"));
    Console.WriteLine($"jpg: {new FileInfo(Path.Combine(outDir, "exif-rotated.jpg")).Length} bytes");
}

// 3. Small PNG (no upscaling) and a mid-size WebP.
using (var bmp = Gradient(200, 150, SKColors.SeaGreen, SKColors.Khaki))
    File.WriteAllBytes(Path.Combine(outDir, "small.png"), bmp.Encode(SKEncodedImageFormat.Png, 100).ToArray());
using (var bmp = Gradient(1000, 700, SKColors.MediumPurple, SKColors.LightSalmon))
    File.WriteAllBytes(Path.Combine(outDir, "medium.webp"), bmp.Encode(SKEncodedImageFormat.Webp, 80).ToArray());
Console.WriteLine("done");

static SKBitmap Gradient(int w, int h, SKColor a, SKColor b)
{
    var bmp = new SKBitmap(w, h);
    using var canvas = new SKCanvas(bmp);
    using var shader = SKShader.CreateLinearGradient(new SKPoint(0, 0), new SKPoint(w, h), [a, b], SKShaderTileMode.Clamp);
    canvas.DrawRect(0, 0, w, h, new SKPaint { Shader = shader });
    using var stripes = new SKPaint { Color = SKColors.White.WithAlpha(90), StrokeWidth = Math.Max(2, w / 80f) };
    for (var x = 0; x < w + h; x += w / 8) canvas.DrawLine(x, 0, x - h, h, stripes);
    return bmp;
}

// Finds a box anywhere in an ISO-BMFF tree (depth-first) and returns it including its header.
static byte[]? FindBox(ReadOnlySpan<byte> data, string type)
{
    string[] containers = ["moov", "trak", "mdia", "minf", "stbl"];
    var offset = 0;
    while (offset + 8 <= data.Length)
    {
        var size = (int)BinaryPrimitives.ReadUInt32BigEndian(data[offset..]);
        var boxType = Encoding.ASCII.GetString(data.Slice(offset + 4, 4));
        if (size < 8 || offset + size > data.Length) break;
        if (boxType == type) return data.Slice(offset, size).ToArray();
        if (containers.Contains(boxType) && FindBox(data.Slice(offset + 8, size - 8), type) is { } inner) return inner;
        if (boxType == "stsd" && FindBox(data.Slice(offset + 16, size - 16), type) is { } entry) return entry;
        if (boxType == "hvc1" && FindBox(data.Slice(offset + 8 + 78, size - 8 - 78), type) is { } cfg) return cfg;
        offset += size;
    }
    return null;
}

static byte[] Box(string type, params byte[][] payload)
{
    var body = payload.SelectMany(p => p).ToArray();
    var result = new byte[8 + body.Length];
    BinaryPrimitives.WriteUInt32BigEndian(result, (uint)result.Length);
    Encoding.ASCII.GetBytes(type).CopyTo(result, 4);
    body.CopyTo(result, 8);
    return result;
}

static byte[] FullBox(string type, byte version, int flags, params byte[][] payload) =>
    Box(type, [[version, (byte)(flags >> 16), (byte)(flags >> 8), (byte)flags], .. payload]);

static byte[] U16(int v) { var b = new byte[2]; BinaryPrimitives.WriteUInt16BigEndian(b, (ushort)v); return b; }
static byte[] U32(long v) { var b = new byte[4]; BinaryPrimitives.WriteUInt32BigEndian(b, (uint)v); return b; }
static byte[] Ascii(string s) => Encoding.ASCII.GetBytes(s);

static byte[] BuildHeif(byte[] hvcC, byte[] sample, int width, int height)
{
    var ftyp = Box("ftyp", Ascii("heic"), U32(0), Ascii("mif1"), Ascii("heic"));

    byte[] Meta(long dataOffset) => FullBox("meta", 0, 0,
        FullBox("hdlr", 0, 0, U32(0), Ascii("pict"), new byte[12], [0]),
        FullBox("pitm", 0, 0, U16(1)),
        FullBox("iinf", 0, 0, U16(1),
            FullBox("infe", 2, 0, U16(1), U16(0), Ascii("hvc1"), [0])),
        // iloc v0: offset_size=4, length_size=4, base_offset_size=0, reserved=0.
        FullBox("iloc", 0, 0, [0x44, 0x00], U16(1), U16(1), U16(0), U16(1), U32(dataOffset), U32(sample.Length)),
        Box("iprp",
            Box("ipco", hvcC, FullBox("ispe", 0, 0, U32(width), U32(height))),
            // ipma: 1 item, 2 associations: hvcC (essential) and ispe.
            FullBox("ipma", 0, 0, U32(1), U16(1), [2], [0x81], [0x02])));

    var metaSize = Meta(0).Length;
    var dataOffset = ftyp.Length + metaSize + 8;
    return [.. ftyp, .. Meta(dataOffset), .. Box("mdat", sample)];
}
