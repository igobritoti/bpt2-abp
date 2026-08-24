namespace BomPraTi.Marketplace.Contracts;

public sealed class PublicListingSearchInput
{
    public Guid? VehicleId { get; init; }
    public Guid? SellerId { get; init; }
    public string? Brand { get; init; }
    public string? Model { get; init; }
    public string? City { get; init; }
    public string? StateCode { get; init; }
    public int? MinModelYear { get; init; }
    public int? MaxModelYear { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }
    public string? Query { get; init; }
    public int Skip { get; init; }
    public int Take { get; init; } = 20;
}
