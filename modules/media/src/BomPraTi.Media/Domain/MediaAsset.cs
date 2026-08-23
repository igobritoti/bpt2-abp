using Volo.Abp.Domain.Entities;

namespace BomPraTi.Media.Domain;

public sealed class MediaAsset : AggregateRoot<Guid>
{
    public string StorageKey { get; private set; } = null!;
    public string ContentType { get; private set; } = null!;
    public long Length { get; private set; }

    private MediaAsset() { }

    public MediaAsset(Guid id, string storageKey, string contentType, long length) : base(id)
    {
        if (string.IsNullOrWhiteSpace(storageKey)) throw new ArgumentException("Storage key is required.", nameof(storageKey));
        if (string.IsNullOrWhiteSpace(contentType)) throw new ArgumentException("Content type is required.", nameof(contentType));
        if (length <= 0) throw new ArgumentOutOfRangeException(nameof(length));

        StorageKey = storageKey.Trim();
        ContentType = contentType.Trim();
        Length = length;
    }
}
