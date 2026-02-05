using Xunit;

/* Tests should work fine in parallel, but this makes native debugging much simpler */
[assembly: CollectionBehavior(DisableTestParallelization = true)]