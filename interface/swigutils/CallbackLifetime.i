// Callbacks pinning to avoid premature GC collection.
%pragma(csharp) modulecode=%{
/// <summary>
/// Static class to hold references to callbacks, preventing them from being garbage collected while they are still needed.
/// Callbacks should be added to this set when they are created, and removed once they have been invoked.
/// </summary>
/// <remarks>
/// When handling callbacks while the async method is running, we need to be careful to keep a reference to the callback
/// safely in memory until it is called. Otherwise, the garbage collector may collect it before it is invoked, leading to
/// unexpected behavior or SIGSEGV. To do that, we use this custom class that holds all the callbacks inside an
/// HashSet that prevents leaks due to premature garbage collection.
/// </remarks>
internal static class CallbackLifetime
{
    /// <summary>
    /// ConcurrentDictionary to hold references to callbacks. This ensures that callbacks are not garbage collected while they are
    /// still needed. Callbacks should be added to this set when they are created, and removed once they have been invoked.
    /// </summary>
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<object, byte> _roots = new();
    
    /// <summary>
    /// Roots the callback, preventing it from being garbage collected. This should be called when the callback is created,
    /// to ensure it stays alive until it is invoked.
    /// </summary> 
    /// <param name="callback">The callback to root.</param>
    internal static void Root(object callback)
    {
        if (callback == null)
        {
            return;
        }
    
        // Atomic, thread-safe add
        if (!_roots.TryAdd(callback, 0))
        {
          // This should never happen
          System.Diagnostics.Debug.Fail($"Attempted to root a callback that was already rooted: {callback}");
        }
    }
    
    /// <summary>
    /// Unroots the callback, allowing it to be garbage collected if there are no other references to it. 
    /// This should be called once the callback has been invoked, to prevent memory leaks.
    /// </summary> 
    /// <param name="callback">The callback to unroot.</param>
    internal static void Unroot(object callback)
    {
        if (callback == null)
        {
            return;
        }
    
        // Atomic, thread-safe remove
        if (!_roots.TryRemove(callback, out _))
        {
          // This should never happen
          System.Diagnostics.Debug.Fail($"Attempted to unroot a callback that was not rooted: {callback}");
        }
    }
}
%}