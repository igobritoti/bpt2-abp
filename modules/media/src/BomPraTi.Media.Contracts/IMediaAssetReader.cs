namespace BomPraTi.Media.Contracts;

public interface IMediaAssetReader
{
    Task<MediaAssetRefDto?> GetAsync(Guid mediaAssetId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MediaAssetRefDto>> GetManyAsync(
        IReadOnlyCollection<Guid> mediaAssetIds,
        CancellationToken cancellationToken = default);
}
