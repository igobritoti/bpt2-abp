using BomPraTi.Sellers.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Sellers.Data;

public sealed class SellersDbContext : AbpDbContext<SellersDbContext>
{
    public DbSet<SellerProfile> SellerProfiles => Set<SellerProfile>();

    public SellersDbContext(DbContextOptions<SellersDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<SellerProfile>(b =>
        {
            b.ToTable("SellerProfiles");
            b.Property(x => x.DisplayName).HasMaxLength(120).IsRequired();
            b.Property(x => x.WhatsAppNumber).HasMaxLength(15).IsRequired();
        });
    }
}
