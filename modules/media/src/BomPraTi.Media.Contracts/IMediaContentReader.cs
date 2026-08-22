namespace BomPraTi.Media.Contracts;

public interface IMediaContentReader
{
    Task<MediaContentDto?> OpenReadAsync(
        Guid mediaAssetId,
        CancellationToken cancellationToken = default);
}
