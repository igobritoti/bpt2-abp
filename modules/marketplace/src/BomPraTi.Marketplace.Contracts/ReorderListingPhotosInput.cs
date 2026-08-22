namespace BomPraTi.Marketplace.Contracts;

public sealed record ReorderListingPhotosInput(IReadOnlyList<Guid> PhotoIds);
