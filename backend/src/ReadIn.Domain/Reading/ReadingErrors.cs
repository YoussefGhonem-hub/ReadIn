using ReadIn.Domain.Common;

namespace ReadIn.Domain.Reading;

public static class ReadingErrors
{
    /// <summary>Two reports for the same user created the same day or progress row at once; the client sends it again.</summary>
    public static readonly Error Conflict = Error.Conflict("reading.conflict", "Another reading report was saved at the same time. Send it again.");
}
