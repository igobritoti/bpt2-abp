namespace BomPraTi.Media.Contracts;

public interface IMediaUploadService
{
    Task<MediaAssetRefDto> UploadAsync(
        Stream content,
        string? declaredContentType = null,
        CancellationToken cancellationToken = default);
}
