using FluentValidation;

namespace FlightOps.Api.Requests;

public sealed class BoundingBoxRequestValidator : AbstractValidator<BoundingBoxRequest>
{
    public BoundingBoxRequestValidator()
    {
        RuleFor(x => x.LaMin).InclusiveBetween(-90, 90);
        RuleFor(x => x.LaMax).InclusiveBetween(-90, 90);
        RuleFor(x => x.LoMin).InclusiveBetween(-180, 180);
        RuleFor(x => x.LoMax).InclusiveBetween(-180, 180);
        RuleFor(x => x)
            .Must(x => x.LaMin < x.LaMax)
            .WithMessage("lamin must be less than lamax.")
            .OverridePropertyName("LaMin");
        RuleFor(x => x)
            .Must(x => x.LoMin < x.LoMax)
            .WithMessage("lomin must be less than lomax.")
            .OverridePropertyName("LoMin");
    }
}
