using BomPraTi.Media.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Media.Data;

public sealed class MediaDbContext : AbpDbContext<MediaDbContext>
{
    public DbSet<MediaAsset> MediaAssets => Set<MediaAsset>();

    public MediaDbContext(DbContextOptions<MediaDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<MediaAsset>(b =>
        {
            b.ToTable("MediaAssets");
            b.Property(x => x.StorageKey).HasMaxLength(512).IsRequired();
            b.Property(x => x.ContentType).HasMaxLength(128).IsRequired();
            // MediaAssetId is the identity. Multiple logical assets may intentionally
            // reference the same provider object/storage key.
            b.HasIndex(x => x.StorageKey);
        });
    }
}
