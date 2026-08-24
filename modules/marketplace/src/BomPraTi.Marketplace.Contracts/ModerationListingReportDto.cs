namespace BomPraTi.Marketplace.Contracts;

public sealed record ModerationListingReportDto(
    Guid ReportId,
    Guid ListingId,
    string ListingTitle,
    string ListingStatus,
    DateTime CreatedAtUtc);
