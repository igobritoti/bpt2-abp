using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Marketplace.Data;

public sealed class MarketplaceDbContext : AbpDbContext<MarketplaceDbContext>
{
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<ListingPhoto> ListingPhotos => Set<ListingPhoto>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<SavedSearch> SavedSearches => Set<SavedSearch>();
    public DbSet<SavedSearchAlertMatch> SavedSearchAlertMatches => Set<SavedSearchAlertMatch>();
    public DbSet<SavedSearchAlertDetectionRequest> SavedSearchAlertDetectionRequests => Set<SavedSearchAlertDetectionRequest>();
    public DbSet<Lead> Leads => Set<Lead>();
    public DbSet<ListingReport> ListingReports => Set<ListingReport>();

    public MarketplaceDbContext(DbContextOptions<MarketplaceDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Listing>(b =>
        {
            b.ToTable("MarketplaceListings");
            b.Property(x => x.Title).HasMaxLength(180).IsRequired();
            b.Property(x => x.Price).HasPrecision(18, 2);
            b.Property(x => x.Description).HasMaxLength(4000).IsRequired();
            b.Property(x => x.Color).HasMaxLength(64);
            b.Property(x => x.City).HasMaxLength(120).IsRequired();
            b.Property(x => x.StateCode).HasMaxLength(2).IsRequired();
            b.HasIndex(x => new { x.Status, x.VehicleId });
            b.HasIndex(x => new { x.SellerId, x.Status });
        });

        builder.Entity<ListingPhoto>(b =>
        {
            b.ToTable("MarketplaceListingPhotos");
            b.HasIndex(x => new { x.ListingId, x.SortOrder });
            b.HasIndex(x => new { x.ListingId, x.MediaAssetId }).IsUnique();
        });

        builder.Entity<Favorite>(b =>
        {
            b.ToTable("MarketplaceFavorites");
            b.HasIndex(x => new { x.UserId, x.ListingId }).IsUnique();
        });

        builder.Entity<SavedSearch>(b =>
        {
            b.ToTable("MarketplaceSavedSearches");
            b.Property(x => x.CriteriaKey).HasMaxLength(64).IsRequired();
            b.Property(x => x.MinPrice).HasPrecision(18, 2);
            b.Property(x => x.MaxPrice).HasPrecision(18, 2);
            b.HasIndex(x => new { x.UserId, x.CriteriaKey }).IsUnique();
            b.HasIndex(x => new { x.UserId, x.CreatedAtUtc });
            b.HasIndex(x => new { x.AlertEnabled, x.Id });
        });

        builder.Entity<SavedSearchAlertMatch>(b =>
        {
            b.ToTable("MarketplaceSavedSearchAlertMatches");
            b.HasIndex(x => new { x.SavedSearchId, x.ListingId }).IsUnique();
            b.HasIndex(x => new { x.SavedSearchId, x.DetectedAtUtc });
        });

        builder.Entity<SavedSearchAlertDetectionRequest>(b =>
        {
            b.ToTable("MarketplaceSavedSearchAlertDetectionRequests");
            b.HasIndex(x => x.ListingId).IsUnique();
            b.HasIndex(x => new { x.ProcessedAtUtc, x.EnqueuedAtUtc });
        });

        builder.Entity<Lead>(b =>
        {
            b.ToTable("MarketplaceLeads");
            b.Property(x => x.Channel).HasMaxLength(64).IsRequired();
            b.Property(x => x.Outcome).HasConversion<string>().HasMaxLength(16);
            b.HasIndex(x => new { x.ListingId, x.CreatedAtUtc });
        });

        builder.Entity<ListingReport>(b =>
        {
            b.ToTable("MarketplaceListingReports");
            b.HasIndex(x => new { x.UserId, x.ListingId }).IsUnique();
            b.HasIndex(x => new { x.ListingId, x.CreatedAtUtc });
        });
    }
}
