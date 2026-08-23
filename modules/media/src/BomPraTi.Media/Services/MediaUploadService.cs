using BomPraTi.Media.Contracts;
using BomPraTi.Media.Domain;
using BomPraTi.Media.Storage;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Guids;
using Volo.Abp.Uow;
using Volo.Abp.Validation;

namespace BomPraTi.Media.Services;

public sealed class MediaUploadService : IMediaUploadService, ITransientDependency
{
    private const int MaxUploadBytes = 20 * 1024 * 1024;

    private readonly IRepository<MediaAsset, Guid> _assets;
    private readonly IGuidGenerator _guidGenerator;
    private readonly IUnitOfWorkManager _unitOfWorkManager;
    private readonly IMediaBlobStore _blobStore;

    public MediaUploadService(
        IRepository<MediaAsset, Guid> assets,
        IGuidGenerator guidGenerator,
        IUnitOfWorkManager unitOfWorkManager,
        IMediaBlobStore blobStore)
    {
        _assets = assets;
        _guidGenerator = guidGenerator;
        _unitOfWorkManager = unitOfWorkManager;
        _blobStore = blobStore;
    }

    public async Task<MediaAssetRefDto> UploadAsync(
        Stream content,
        string? declaredContentType = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(content);

        using var buffer = new MemoryStream();
        var chunk = new byte[81920];
        while (true)
        {
            var read = await content.ReadAsync(chunk, cancellationToken);
            if (read == 0)
            {
                break;
            }

            if (buffer.Length + read > MaxUploadBytes)
            {
                throw new AbpValidationException("Media upload exceeds the 20 MiB limit.");
            }

            await buffer.WriteAsync(chunk.AsMemory(0, read), cancellationToken);
        }

        if (buffer.Length == 0)
        {
            throw new AbpValidationException("Media upload is empty.");
        }

        var detected = DetectImage(buffer.GetBuffer().AsSpan(0, (int)Math.Min(buffer.Length, 12)));
        var declared = NormalizeContentType(declaredContentType);
        if (declared is not null && declared != detected.ContentType)
        {
            throw new AbpValidationException("Declared content type does not match the uploaded image bytes.");
        }

        var id = _guidGenerator.Create();
        var storageKey = $"assets/{id:N}{detected.Extension}";
        buffer.Position = 0;
        await _blobStore.SaveAsync(storageKey, buffer, cancellationToken);

        try
        {
            using var uow = _unitOfWorkManager.Begin(requiresNew: true, isTransactional: true);
            var asset = new MediaAsset(id, storageKey, detected.ContentType, buffer.Length);
            await _assets.InsertAsync(asset, autoSave: true, cancellationToken: cancellationToken);
            await uow.CompleteAsync();
            return new MediaAssetRefDto(asset.Id, asset.ContentType, asset.Length);
        }
        catch
        {
            await _blobStore.DeleteAsync(storageKey, CancellationToken.None);
            throw;
        }
    }

    private static string? NormalizeContentType(string? contentType)
    {
        if (string.IsNullOrWhiteSpace(contentType))
        {
            return null;
        }

        var normalized = contentType.Split(';', 2)[0].Trim().ToLowerInvariant();
        return normalized == "image/jpg" ? "image/jpeg" : normalized;
    }

    private static DetectedImage DetectImage(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
        {
            return new DetectedImage("image/jpeg", ".jpg");
        }

        if (bytes.Length >= 8 &&
            bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
            bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A)
        {
            return new DetectedImage("image/png", ".png");
        }

        if (bytes.Length >= 12 &&
            bytes[0] == (byte)'R' && bytes[1] == (byte)'I' && bytes[2] == (byte)'F' && bytes[3] == (byte)'F' &&
            bytes[8] == (byte)'W' && bytes[9] == (byte)'E' && bytes[10] == (byte)'B' && bytes[11] == (byte)'P')
        {
            return new DetectedImage("image/webp", ".webp");
        }

        throw new AbpValidationException("Only JPEG, PNG and WebP image uploads are accepted.");
    }

    private sealed record DetectedImage(string ContentType, string Extension);
}
