using FlightOps.Api.Requests;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Requests;

[TestFixture]
public class BoundingBoxRequestValidatorTests
{
    private readonly BoundingBoxRequestValidator _validator = new();

    [Test]
    public void Valid_bounding_box_passes()
    {
        var request = new BoundingBoxRequest
        {
            LaMin = 10,
            LoMin = 10,
            LaMax = 20,
            LoMax = 20,
        };

        var result = _validator.Validate(request);

        Assert.That(result.IsValid, Is.True);
    }

    [Test]
    public void LaMin_greater_than_or_equal_to_LaMax_fails()
    {
        var request = new BoundingBoxRequest
        {
            LaMin = 20,
            LoMin = 10,
            LaMax = 20,
            LoMax = 20,
        };

        var result = _validator.Validate(request);

        Assert.That(result.IsValid, Is.False);
    }

    [Test]
    public void Latitude_out_of_range_fails()
    {
        var request = new BoundingBoxRequest
        {
            LaMin = -100,
            LoMin = 10,
            LaMax = 20,
            LoMax = 20,
        };

        var result = _validator.Validate(request);

        Assert.That(result.IsValid, Is.False);
    }
}
