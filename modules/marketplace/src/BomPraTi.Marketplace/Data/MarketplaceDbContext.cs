using BomPraTi.Marketplace.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Marketplace.Data;

public sealed class MarketplaceDbContext : AbpDbContext<MarketplaceDbContext>
{
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<ListingPhoto> ListingPhotos => Set<ListingPhoto>();
    public DbSet<ListingPromotion> ListingPromotions => Set<ListingPromotion>();
    public DbSet<ListingPriceChange> ListingPriceChanges => Set<ListingPriceChange>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<FavoritePriceDropMatch> FavoritePriceDropMatches => Set<FavoritePriceDropMatch>();
    public DbSet<SavedSearch> SavedSearches => Set<SavedSearch>();
    public DbSet<SavedSearchAlertMatch> SavedSearchAlertMatches => Set<SavedSearchAlertMatch>();
    public DbSet<SavedSearchAlertDeliveryIntent> SavedSearchAlertDeliveryIntents => Set<SavedSearchAlertDeliveryIntent>();
    public DbSet<SavedSearchEmailProviderEvent> SavedSearchEmailProviderEvents => Set<SavedSearchEmailProviderEvent>();
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

        builder.Entity<ListingPromotion>(b =>
        {
            b.ToTable("MarketplaceListingPromotions");
            b.HasIndex(x => x.ListingId).IsUnique();
            b.HasIndex(x => new { x.StartsAtUtc, x.EndsAtUtc });
        });

        builder.Entity<ListingPriceChange>(b =>
        {
            b.ToTable("MarketplaceListingPriceChanges");
            b.Property(x => x.PreviousPrice).HasPrecision(18, 2);
            b.Property(x => x.NewPrice).HasPrecision(18, 2);
            b.HasIndex(x => new { x.ListingId, x.ChangedAtUtc });
        });

        builder.Entity<Favorite>(b =>
        {
            b.ToTable("MarketplaceFavorites");
            b.HasIndex(x => new { x.UserId, x.ListingId }).IsUnique();
        });

        builder.Entity<FavoritePriceDropMatch>(b =>
        {
            b.ToTable("MarketplaceFavoritePriceDropMatches");
            b.Property(x => x.PreviousPrice).HasPrecision(18, 2);
            b.Property(x => x.NewPrice).HasPrecision(18, 2);
            b.HasIndex(x => new { x.UserId, x.ListingPriceChangeId }).IsUnique();
            b.HasIndex(x => new { x.ListingId, x.DetectedAtUtc });
        });

        builder.Entity<SavedSearch>(b =>
        {
            b.ToTable("MarketplaceSavedSearches");
            b.Property(x => x.CriteriaKey).HasMaxLength(64).IsRequired();
            b.Property(x => x.Color).HasMaxLength(64);
            b.Property(x => x.MinPrice).HasPrecision(18, 2);
            b.Property(x => x.MaxPrice).HasPrecision(18, 2);
            b.HasIndex(x => new { x.UserId, x.CriteriaKey }).IsUnique();
            b.HasIndex(x => new { x.UserId, x.CreatedAtUtc });
            b.HasIndex(x => new { x.AlertEnabled, x.Id });
            b.HasIndex(x => new { x.EmailEachNewMatchEnabled, x.Id });
        });

        builder.Entity<SavedSearchAlertMatch>(b =>
        {
            b.ToTable("MarketplaceSavedSearchAlertMatches");
            b.HasIndex(x => new { x.SavedSearchId, x.ListingId }).IsUnique();
            b.HasIndex(x => new { x.SavedSearchId, x.DetectedAtUtc });
        });

        builder.Entity<SavedSearchAlertDeliveryIntent>(b =>
        {
            b.ToTable("MarketplaceSavedSearchAlertDeliveryIntents");
            b.Property(x => x.Channel).HasMaxLength(32).IsRequired();
            b.Property(x => x.IdempotencyKey).HasMaxLength(96).IsRequired();
            b.Property(x => x.Status).HasConversion<string>().HasMaxLength(32).IsRequired();
            b.Property(x => x.RecipientFingerprint).HasMaxLength(64);
            b.Property(x => x.ProviderMessageId).HasMaxLength(256);
            b.HasIndex(x => new { x.SavedSearchAlertMatchId, x.Channel }).IsUnique();
            b.HasIndex(x => new { x.Status, x.NextAttemptAtUtc, x.LeaseExpiresAtUtc, x.CreatedAtUtc });
            b.HasIndex(x => x.IdempotencyKey).IsUnique();
        });

        builder.Entity<SavedSearchEmailProviderEvent>(b =>
        {
            b.ToTable("MarketplaceSavedSearchEmailProviderEvents");
            b.Property(x => x.Provider).HasMaxLength(32).IsRequired();
            b.Property(x => x.ProviderEventId).HasMaxLength(128).IsRequired();
            b.Property(x => x.ProviderMessageId).HasMaxLength(256).IsRequired();
            b.Property(x => x.EventType).HasMaxLength(64).IsRequired();
            b.HasIndex(x => new { x.Provider, x.ProviderEventId }).IsUnique();
            b.HasIndex(x => new { x.ProviderMessageId, x.ReceivedAtUtc });
        });

        builder.Entity<SavedSearchAlertDetectionRequest>(b =>
        {
            b.ToTable("MarketplaceSavedSearchAlertDetectionRequests");
            b.HasIndex(x => x.ListingId).IsUnique();
            b.HasIndex(x => new { x.ProcessedAtUtc, x.NextAttemptAtUtc, x.EnqueuedAtUtc });
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
