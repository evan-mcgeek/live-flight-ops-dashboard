using FlightOps.Api.Hubs;
using FlightOps.Domain;
using NUnit.Framework;

namespace FlightOps.Api.Tests.Hubs;

[TestFixture]
public class ActiveBoundingBoxRegistryTests
{
    [Test]
    public void Register_adds_group_to_active_groups()
    {
        var registry = new ActiveBoundingBoxRegistry();
        var bbox = new BoundingBox(1, 2, 3, 4);

        registry.Register("conn-1", "group-1", bbox);

        Assert.That(registry.ActiveGroups["group-1"], Is.EqualTo(bbox));
    }

    [Test]
    public void Register_overwrites_an_existing_group_with_the_same_name_for_the_same_connection()
    {
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));

        registry.Register("conn-1", "group-1", new BoundingBox(5, 6, 7, 8));

        Assert.That(registry.ActiveGroups["group-1"], Is.EqualTo(new BoundingBox(5, 6, 7, 8)));
    }

    [Test]
    public void Unregister_removes_group_when_its_last_connection_leaves()
    {
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));

        registry.Unregister("conn-1");

        Assert.That(registry.ActiveGroups.ContainsKey("group-1"), Is.False);
    }

    [Test]
    public void Unregister_keeps_group_active_while_other_connections_remain()
    {
        var registry = new ActiveBoundingBoxRegistry();
        var bbox = new BoundingBox(1, 2, 3, 4);
        registry.Register("conn-1", "group-1", bbox);
        registry.Register("conn-2", "group-1", bbox);

        registry.Unregister("conn-1");

        Assert.That(registry.ActiveGroups["group-1"], Is.EqualTo(bbox));
    }

    [Test]
    public void Register_moves_a_connection_from_its_previous_group_to_a_new_one()
    {
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));

        registry.Register("conn-1", "group-2", new BoundingBox(5, 6, 7, 8));

        Assert.That(registry.ActiveGroups.ContainsKey("group-1"), Is.False);
        Assert.That(registry.ActiveGroups["group-2"], Is.EqualTo(new BoundingBox(5, 6, 7, 8)));
    }

    [Test]
    public void Register_resets_the_group_clock_so_it_is_not_immediately_due()
    {
        var registry = new ActiveBoundingBoxRegistry();

        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));

        Assert.That(registry.IsDue("group-1", TimeSpan.FromSeconds(5)), Is.False);
    }

    [Test]
    public void IsDue_is_true_once_the_interval_has_elapsed_since_the_last_broadcast()
    {
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));

        Assert.That(registry.IsDue("group-1", TimeSpan.Zero), Is.True);
    }

    [Test]
    public void MarkBroadcast_resets_the_group_clock()
    {
        var registry = new ActiveBoundingBoxRegistry();
        registry.Register("conn-1", "group-1", new BoundingBox(1, 2, 3, 4));
        Assume.That(registry.IsDue("group-1", TimeSpan.Zero), Is.True);

        registry.MarkBroadcast("group-1");

        Assert.That(registry.IsDue("group-1", TimeSpan.FromSeconds(5)), Is.False);
    }

    [Test]
    public void IsDue_is_true_for_a_group_with_no_recorded_broadcast()
    {
        var registry = new ActiveBoundingBoxRegistry();

        Assert.That(registry.IsDue("unknown-group", TimeSpan.FromSeconds(5)), Is.True);
    }
}
