using BomPraTi.Ingestion.Domain;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace BomPraTi.Ingestion.Data;

public sealed class IngestionDbContext : AbpDbContext<IngestionDbContext>
{
    public DbSet<IngestionRecord> Records => Set<IngestionRecord>();

    public IngestionDbContext(DbContextOptions<IngestionDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.Entity<IngestionRecord>(b =>
        {
            b.ToTable("IngestionRecords");
            b.Property(x => x.Source).HasMaxLength(64).IsRequired();
            b.Property(x => x.ExternalId).HasMaxLength(256).IsRequired();
            b.Property(x => x.RawIdentity).HasMaxLength(1024).IsRequired();
            b.Property(x => x.Confidence).HasPrecision(5, 4);
            b.Property(x => x.Provenance).HasMaxLength(1024).IsRequired();
            b.HasIndex(x => new { x.Source, x.ExternalId }).IsUnique();
            b.HasIndex(x => x.ReconciledVehicleId);
        });
    }
}
