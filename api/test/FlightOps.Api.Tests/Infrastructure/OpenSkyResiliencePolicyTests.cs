using System.Net;
using FlightOps.Infrastructure.OpenSky;
using Microsoft.Extensions.Http;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Infrastructure;

[TestFixture]
public class OpenSkyResiliencePolicyTests
{
    [Test]
    public async Task RetryPolicy_retries_on_a_5xx_response_and_succeeds()
    {
        var handler = new SequenceHandler(
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable),
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable),
            new HttpResponseMessage(HttpStatusCode.OK)
        );
        var policyHandler = new PolicyHttpMessageHandler(OpenSkyResiliencePolicy.RetryPolicy())
        {
            InnerHandler = handler,
        };
        using var invoker = new HttpMessageInvoker(policyHandler);

        var response = await invoker.SendAsync(
            new HttpRequestMessage(HttpMethod.Get, "https://opensky-network.org/api/states/all"),
            CancellationToken.None
        );

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        Assert.That(handler.CallCount, Is.EqualTo(3));
    }

    [Test]
    public async Task RetryPolicy_gives_up_after_exhausting_retries_and_returns_the_last_failure()
    {
        var handler = new SequenceHandler(
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable),
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable),
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable),
            new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)
        );
        var policyHandler = new PolicyHttpMessageHandler(OpenSkyResiliencePolicy.RetryPolicy())
        {
            InnerHandler = handler,
        };
        using var invoker = new HttpMessageInvoker(policyHandler);

        var response = await invoker.SendAsync(
            new HttpRequestMessage(HttpMethod.Get, "https://opensky-network.org/api/states/all"),
            CancellationToken.None
        );

        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.ServiceUnavailable));
        Assert.That(handler.CallCount, Is.EqualTo(4)); // 1 initial attempt + 3 retries
    }

    [Test]
    public void A_response_slower_than_the_configured_timeout_is_cancelled()
    {
        var handler = new DelayHandler(TimeSpan.FromSeconds(30));
        using var httpClient = new HttpClient(handler) { Timeout = TimeSpan.FromMilliseconds(100) };

        Assert.ThrowsAsync<TaskCanceledException>(
            () => httpClient.GetAsync("https://opensky-network.org/api/states/all")
        );
    }

    private sealed class SequenceHandler : HttpMessageHandler
    {
        private readonly Queue<HttpResponseMessage> _responses;

        public SequenceHandler(params HttpResponseMessage[] responses)
        {
            _responses = new Queue<HttpResponseMessage>(responses);
        }

        public int CallCount { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        )
        {
            CallCount++;
            return Task.FromResult(_responses.Dequeue());
        }
    }

    private sealed class DelayHandler(TimeSpan delay) : HttpMessageHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken
        )
        {
            await Task.Delay(delay, cancellationToken);
            return new HttpResponseMessage(HttpStatusCode.OK);
        }
    }
}
