using FlightOps.Domain;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Domain;

[TestFixture]
public class BoundingBoxTests
{
    [Test]
    public void RoundToGrid_rounds_min_down_and_max_up_to_grid_boundaries()
    {
        var bbox = new BoundingBox(LaMin: 12, LoMin: 23, LaMax: 18, LoMax: 29);

        var rounded = bbox.RoundToGrid(gridDegrees: 5);

        Assert.That(rounded, Is.EqualTo(new BoundingBox(10, 20, 20, 30)));
    }

    [Test]
    public void CacheKey_formats_all_four_values_to_two_decimal_places()
    {
        var bbox = new BoundingBox(10, 20, 20, 30);

        Assert.That(bbox.CacheKey, Is.EqualTo("10.00_20.00_20.00_30.00"));
    }
}
