/* This file pins callbacks used in action adapters, and awaitable functions.
 * Specifically, the lifetime of the pinned callbacks in those use cases is defined as follows:
 * - For awaitable functions (see AsyncAdapters.i), callbacks are kept alive (pinned) until the await X() function call completes.
 * - For action adapters (see AsyncAdapters.i), callbacks are kept alive (pinned) as long as the action adapter exists.
 * Furthermore, since event adapters (see Events.i) rely on the action adapters mechanism to work, indirectly the 
 * callbacks in use by event adapters are also kept alive, as long as there is a subscriber to the event that keeps 
 * alive the related action adapter for that event.
 * Note: outside of the cases listed above, this does NOT pin every callback, and client developer have to keep alive 
 * the callbacks that they register outside of those usages by manually pinning them explicitly to avoid premature GC. */

// Callbacks pinning to avoid premature GC collection.
%pragma(csharp) modulecode=%{
/// <summary>
/// Static class to hold references to callbacks, preventing them from being garbage collected while they are still needed.
/// Callbacks should be added to this set when they are created, and removed once they have been invoked.
/// </summary>
/// <remarks>
/// When handling callbacks while the async method is running or the action adapter that makes use of it exists, we need
/// to be careful to keep a reference to the callback safely in memory until it is called. Otherwise, the garbage 
/// collector may collect it before it is invoked, leading to unexpected behavior or SIGSEGV. To do that, we use this 
/// custom class that holds all the callbacks inside an HashSet that prevents leaks due to premature garbage collection.
/// </remarks>
internal static class AsyncLifetime
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
        
        // Only add to root if not already rooted
        if(IsRooted(callback))
        {
            // This should never happen
            System.Diagnostics.Debug.Fail($"Attempted to root a callback that was already rooted: {callback}");
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
    /// Returns true if the specified callback was rooted, false otherwise.
    /// </summary>
    /// <param name="callback">The callback being checked.</param>
    /// <returns>True if already rooted, false otherwise.</returns>
    internal static bool IsRooted(object callback)
    {
        if (callback == null)
        {
            return false;
        }
        
        return _roots.ContainsKey(callback);
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