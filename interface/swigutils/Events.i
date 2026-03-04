/*
 * Support for exposing native C++ callback-style APIs as idiomatic C# events.
 *
 * This file defines MAKE_EVENT_FOR_CALLBACK, which maps a native
 * "SetXCallback(CallbackType)" API to a managed C# event.
 *
 * ----------------------------------------------------------------------
 * WHAT THIS MACRO REPRESENTS
 * ----------------------------------------------------------------------
 *
 * This macro is ONLY for long-lived, multi-fire notifications.
 *
 * Use it when the native API represents:
 *   - A signal or notification
 *   - That may fire zero or more times
 *   - That has no completion concept
 *
 * Examples:
 *   - State changes
 *   - Presence updates
 *   - Entity added / removed
 *
 * If the API represents a request/response or something that should be
 * awaited, DO NOT use this macro.
 *
 * ----------------------------------------------------------------------
 * RELATIONSHIP TO OTHER ABSTRACTIONS
 * ----------------------------------------------------------------------
 *
 * Callbacks:
 *   - Low-level transport mechanism (native → managed)
 *   - Implemented via SWIG directors and MAKE_ACTION_ADAPTER
 *   - Not user-facing
 *
 * Async APIs:
 *   - Single-shot operations
 *   - Exposed as Task<T>
 *   - Own and dispose their callback on completion
 *
 * Events (this macro):
 *   - Long-lived
 *   - Multicast
 *   - Not awaited
 *   - Owned by the publisher
 *
 * These abstractions have different lifetime and ownership rules and
 * intentionally use different macros.
 *
 * ----------------------------------------------------------------------
 * REQUIREMENTS
 * ----------------------------------------------------------------------
 *
 * 1. Native API must expose:
 *
 *      void SetXCallback(CallbackType callback);
 *
 *    Passing null must unregister the callback.
 *
 * 2. A managed callback adapter must already exist via MAKE_ACTION_ADAPTER.
 *
 * 3. AsyncLifetime.Root / Unroot must be available for GC safety.
 *
 * ----------------------------------------------------------------------
 * LIFETIME MODEL
 * ----------------------------------------------------------------------
 *
 * - One native callback adapter per event
 * - Adapter is created on first subscription
 * - Adapter is explicitly rooted while at least one subscriber exists
 * - Adapter is unregistered and unrooted when the last subscriber is removed
 *
 * This prevents:
 *   - GC collecting adapters still referenced by native code
 *   - Duplicate native registrations
 *   - Callback leaks
 *
 * ----------------------------------------------------------------------
 * CONSUMER USAGE (C#)
 * ----------------------------------------------------------------------
 *
 * Events exposed by this macro are consumed idiomatically:
 *
 *     instance.OnSomethingHappened += payload =>
 *     {
 *         // Handle event
 *     };
 *
 *     instance.OnSomethingHappened -= handler;
 *
 * Consumers do NOT:
 *   - Manage callbacks
 *   - Root adapters
 *   - Call native setters
 *
 * The binding layer owns all lifecycle concerns.
 *
 * ----------------------------------------------------------------------
 * THREADING
 * ----------------------------------------------------------------------
 *
 * Event handlers execute on the same thread as the native callback.
 * This macro does not impose any thread marshalling.
 */

/*
 * EVENT_NAME is the name of the event, e.g. OnNewLoginTokenReceived
 * ACTION_CALLBACK_TYPENAME is the type of the callback adapter class, for example 
 * ConnectedSpacesPlatformDotNet.LoginTokenInfoCallback.
 * NATIVE_SETTER is the native method that registers the callback, e.g. SetNewLoginTokenReceivedCallback
 * PAYLOAD_TYPE is the type of the payload passed to event handlers, e.g. csp.systems.LoginTokenInfoResult
 * FULLY_NAMESPACED_CLASST is the full namespaced C++ class name to extend, e.g. csp::systems::UserSystem
 */
%define MAKE_EVENT_FOR_CALLBACK(
    EVENT_NAME,
    ACTION_CALLBACK_TYPENAME,
    NATIVE_SETTER,
    PAYLOAD_TYPE,
    FULLY_NAMESPACED_CLASST
)
%extend FULLY_NAMESPACED_CLASST {
%proxycode %{

    // Native callback adapter instance (one per event)
    private ACTION_CALLBACK_TYPENAME? _##EVENT_NAME##Adapter;

    // Backing multicast delegate for the managed event
    private event System.Action<PAYLOAD_TYPE>? _##EVENT_NAME;

    /*
     * Public managed event.
     *
     * Native callback registration occurs on first subscription.
     * Native callback unregistration occurs when the last subscriber is removed.
     */
    public event System.Action<PAYLOAD_TYPE> EVENT_NAME
    {
        add
        {
            // First subscriber: register native callback
            if (_##EVENT_NAME == null)
                Register##EVENT_NAME##Callback();

            _##EVENT_NAME += value;
        }
        remove
        {
            _##EVENT_NAME -= value;

            // Last subscriber removed: unregister native callback
            if (_##EVENT_NAME == null)
                Unregister##EVENT_NAME##Callback();
        }
    }

    /*
     * Registers the native callback and roots the adapter.
     * This method is idempotent and safe to call multiple times.
     */
    private void Register##EVENT_NAME##Callback()
    {
        if (_##EVENT_NAME##Adapter != null)
            return;

        _##EVENT_NAME##Adapter =
            new ACTION_CALLBACK_TYPENAME(On##EVENT_NAME##Native);

        // Root the adapter to prevent GC while native code holds it
        ConnectedSpacesPlatformDotNet.AsyncLifetime.Root(_##EVENT_NAME##Adapter);

        // Register native callback
        NATIVE_SETTER(_##EVENT_NAME##Adapter);
    }

    /*
     * Unregisters the native callback and releases the adapter.
     * This method is idempotent and safe to call multiple times.
     */
    private void Unregister##EVENT_NAME##Callback()
    {
        if (_##EVENT_NAME##Adapter == null)
            return;

        // Unregister native callback
        NATIVE_SETTER(null);

        // Stop managed dispatch
        _##EVENT_NAME = null;

        // Unroot adapter and release reference
        ConnectedSpacesPlatformDotNet.AsyncLifetime.Unroot(_##EVENT_NAME##Adapter);
        _##EVENT_NAME##Adapter = null;
    }

    /*
     * Entry point invoked by native code via the callback adapter.
     * Forwards the payload to managed subscribers.
     */
    private void On##EVENT_NAME##Native(PAYLOAD_TYPE args)
        => _##EVENT_NAME?.Invoke(args);

%}    // End of proxy code
}     // End of extension
%enddef