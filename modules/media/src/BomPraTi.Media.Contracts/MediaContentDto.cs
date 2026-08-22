namespace BomPraTi.Media.Contracts;

public sealed record MediaContentDto(
    Stream Content,
    string ContentType,
    long Length);
