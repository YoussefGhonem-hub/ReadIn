using Mapster;
using ReadIn.Application.Common.Mapping;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Taxonomy;

public sealed class TaxonomyMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<Field, FieldDto>()
            .Map(d => d.Name, s => LocalizedProjection.Ui == "en" ? s.NameEn : s.NameAr)
            .Map(d => d.TopicCount, s => s.Topics.Count(t => t.IsEnabled));

        config.NewConfig<Topic, TopicDto>()
            .Map(d => d.Name, s => LocalizedProjection.Ui == "en" ? s.NameEn : s.NameAr);
    }
}
