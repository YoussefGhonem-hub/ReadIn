namespace ReadIn.Application.Features.Taxonomy;

public sealed record FieldDto
{
    public Guid Id { get; init; }
    public string Slug { get; init; } = default!;
    public string Name { get; init; } = default!;
    public string NameAr { get; init; } = default!;
    public string NameEn { get; init; } = default!;
    public string Icon { get; init; } = default!;
    public string Color { get; init; } = default!;
    public bool IsSensitive { get; init; }
    public int TopicCount { get; init; }
}

public sealed record TopicDto
{
    public Guid Id { get; init; }
    public Guid FieldId { get; init; }
    public string Slug { get; init; } = default!;
    public string Name { get; init; } = default!;
    public string NameAr { get; init; } = default!;
    public string NameEn { get; init; } = default!;
}
