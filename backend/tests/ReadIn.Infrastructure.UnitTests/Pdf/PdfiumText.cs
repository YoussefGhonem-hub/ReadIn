using System.Runtime.InteropServices;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// Page text as PDF viewers select and search it, through PDFium (the engine of Chrome's PDF viewer, bundled with
/// PDFtoImage). PDFium puts right-to-left text back in reading order, so Arabic can be compared with what was written.
/// PDFium is not thread-safe: callers run in <see cref="ArticlePdfCollection"/>, which never runs in parallel.
/// </summary>
internal static class PdfiumText
{
    private static readonly Lock Gate = new();
    private static bool _initialized;

    public static IReadOnlyList<string> Pages(byte[] pdf)
    {
        lock (Gate)
        {
            if (!_initialized)
            {
                FPDF_InitLibrary();
                _initialized = true;
            }

            var handle = GCHandle.Alloc(pdf, GCHandleType.Pinned);
            try
            {
                var document = FPDF_LoadMemDocument(handle.AddrOfPinnedObject(), pdf.Length, null);
                if (document == IntPtr.Zero) throw new InvalidOperationException("PDFium could not open the PDF.");
                try
                {
                    var pages = new List<string>();
                    for (var i = 0; i < FPDF_GetPageCount(document); i++)
                    {
                        var page = FPDF_LoadPage(document, i);
                        var text = FPDFText_LoadPage(page);
                        try
                        {
                            var count = FPDFText_CountChars(text);
                            var buffer = new ushort[count + 1];
                            var written = count == 0 ? 0 : FPDFText_GetText(text, 0, count, buffer);
                            var chars = new char[Math.Max(0, written - 1)];
                            for (var c = 0; c < chars.Length; c++) chars[c] = (char)buffer[c];
                            pages.Add(new string(chars));
                        }
                        finally
                        {
                            FPDFText_ClosePage(text);
                            FPDF_ClosePage(page);
                        }
                    }
                    return pages;
                }
                finally
                {
                    FPDF_CloseDocument(document);
                }
            }
            finally
            {
                handle.Free();
            }
        }
    }

    [DllImport("pdfium")] private static extern void FPDF_InitLibrary();
    [DllImport("pdfium")] private static extern IntPtr FPDF_LoadMemDocument(IntPtr data, int size, [MarshalAs(UnmanagedType.LPStr)] string? password);
    [DllImport("pdfium")] private static extern void FPDF_CloseDocument(IntPtr document);
    [DllImport("pdfium")] private static extern int FPDF_GetPageCount(IntPtr document);
    [DllImport("pdfium")] private static extern IntPtr FPDF_LoadPage(IntPtr document, int index);
    [DllImport("pdfium")] private static extern void FPDF_ClosePage(IntPtr page);
    [DllImport("pdfium")] private static extern IntPtr FPDFText_LoadPage(IntPtr page);
    [DllImport("pdfium")] private static extern void FPDFText_ClosePage(IntPtr textPage);
    [DllImport("pdfium")] private static extern int FPDFText_CountChars(IntPtr textPage);
    [DllImport("pdfium")] private static extern int FPDFText_GetText(IntPtr textPage, int start, int count, [Out] ushort[] result);
}
