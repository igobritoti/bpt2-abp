using BomPraTi.Catalog.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Catalog.Data;

public sealed class CatalogDbContext : AbpDbContext<CatalogDbContext>
{
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<VehicleModel> Models => Set<VehicleModel>();
    public DbSet<Generation> Generations => Set<Generation>();
    public DbSet<VehicleVersion> Versions => Set<VehicleVersion>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();

    public CatalogDbContext(DbContextOptions<CatalogDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Brand>(b =>
        {
            b.ToTable("CatalogBrands");
            b.Property(x => x.Name).HasMaxLength(128).IsRequired();
            b.Property(x => x.NormalizedName).HasMaxLength(128).IsRequired();
            b.HasIndex(x => x.NormalizedName).IsUnique();
        });

        builder.Entity<VehicleModel>(b =>
        {
            b.ToTable("CatalogModels");
            b.Property(x => x.Name).HasMaxLength(128).IsRequired();
            b.Property(x => x.NormalizedName).HasMaxLength(128).IsRequired();
            b.HasIndex(x => new { x.BrandId, x.NormalizedName }).IsUnique();
        });

        builder.Entity<Generation>(b =>
        {
            b.ToTable("CatalogGenerations");
            b.Property(x => x.Name).HasMaxLength(128).IsRequired();
            b.HasIndex(x => new { x.ModelId, x.Name });
        });

        builder.Entity<VehicleVersion>(b =>
        {
            b.ToTable("CatalogVersions");
            b.Property(x => x.Name).HasMaxLength(180).IsRequired();
            b.Property(x => x.NormalizedName).HasMaxLength(180).IsRequired();
            b.HasIndex(x => new { x.ModelId, x.GenerationId, x.NormalizedName }).IsUnique();
        });

        builder.Entity<Vehicle>(b =>
        {
            b.ToTable("CatalogVehicles");
            b.HasIndex(x => new { x.BrandId, x.ModelId, x.GenerationId, x.VersionId, x.ModelYear }).IsUnique();
        });
    }
}
