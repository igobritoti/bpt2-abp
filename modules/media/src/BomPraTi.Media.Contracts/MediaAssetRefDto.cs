namespace BomPraTi.Media.Contracts;

public sealed record MediaAssetRefDto(
    Guid Id,
    string ContentType,
    long Length);
