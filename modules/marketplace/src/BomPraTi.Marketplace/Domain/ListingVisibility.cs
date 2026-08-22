namespace BomPraTi.Marketplace.Domain;

public static class ListingVisibility
{
    public static bool IsPublic(Listing listing) => listing.Status == ListingStatus.Published;

    public static IQueryable<Listing> PublicOnly(IQueryable<Listing> listings)
    {
        ArgumentNullException.ThrowIfNull(listings);
        return listings.Where(x => x.Status == ListingStatus.Published);
    }
}
