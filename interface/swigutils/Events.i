/*
 * Expose native C++ callback APIs as idiomatic C# events.
 *
 * This macro defines MAKE_EVENT_FOR_CALLBACK, which wraps a native
 * "SetXCallback(CallbackType)" API into a C# event using an existing
 * action adapter callback. This allows:
 *   - C# consumers to subscribe/unsubscribe using += and -=
 *   - Automatic GC safety via AsyncLifetime rooting
 *   - Automatic registration/unregistration with native code
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
 * 3. AsyncLifetime.Root / AsyncLifetime.Unroot must exist for GC safety.
 *
 * ----------------------------------------------------------------------
 * LIFETIME & OWNERSHIP MODEL
 * ----------------------------------------------------------------------
 *
 * - One adapter instance per event, owned by the binding layer.
 * - Adapter is created on first subscription.
 * - Adapter is rooted while at least one subscriber exists.
 * - Adapter is unregistered and unrooted when the last subscriber is removed.
 *
 * This ensures:
 *   - Adapter is not GC-collected while native code holds a reference.
 *   - Duplicate native registrations are prevented.
 *   - No callback leaks occur.
 *
 * ----------------------------------------------------------------------
 * CONSUMER USAGE (C#)
 * ----------------------------------------------------------------------
 *
 * Events are consumed like standard C# events:
 *
 *     instance.OnSomethingHappened += payload =>
 *     {
 *         // Handle event
 *     };
 *
 *     instance.OnSomethingHappened -= handler;
 *
 * Consumers do NOT need to manage adapter lifetimes or native registration.
 *
 * ----------------------------------------------------------------------
 * THREADING
 * ----------------------------------------------------------------------
 *
 * Event handlers are invoked on the same thread as the native callback.
 * No thread marshalling is performed by this macro.
 */

/*
 * Parameters:
 *
 * EVENT_NAME: The C# event name, e.g., OnNewLoginTokenReceived
 * ACTION_CALLBACK_TYPENAME: The callback adapter type, e.g.,
 *     ConnectedSpacesPlatformDotNet.LoginTokenInfoCallback
 * NATIVE_SETTER: The native registration method, e.g.,
 *     SetNewLoginTokenReceivedCallback
 * PAYLOAD_TYPE: The type passed to subscribers, e.g., csp.systems.LoginTokenInfoResult
 * FULLY_NAMESPACED_CLASST: The full C++ class to extend, e.g.,
 *     csp.systems.UserSystem
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

    // Single native callback adapter instance for this event
    private ACTION_CALLBACK_TYPENAME? _##EVENT_NAME##Adapter;

    /// <summary>
    /// C# event exposing the native callback.
    /// Subscribers are automatically registered/unregistered with native code.
    /// </summary>
    public event System.Action<PAYLOAD_TYPE> EVENT_NAME
    {
        add
        {
            Ensure##EVENT_NAME##Registered();
            _##EVENT_NAME##Adapter!.Invoked += value;
        }
        remove
        {
            if (_##EVENT_NAME##Adapter == null)
                return;

            _##EVENT_NAME##Adapter.Invoked -= value;

            // If no subscribers remain, unregister native callback
            if (!_##EVENT_NAME##Adapter.HasSubscribers)
                Unregister##EVENT_NAME();
        }
    }

    /// <summary>
    /// Ensures the native adapter is created, rooted, and registered.
    /// Called automatically when the first subscriber is added.
    /// </summary>
    private void Ensure##EVENT_NAME##Registered()
    {
        if (_##EVENT_NAME##Adapter != null)
            return;

        _##EVENT_NAME##Adapter = new ACTION_CALLBACK_TYPENAME();

        // Root the adapter to prevent GC while native code holds it
        ConnectedSpacesPlatformDotNet.AsyncLifetime.Root(_##EVENT_NAME##Adapter);

        // Register with native code
        NATIVE_SETTER(_##EVENT_NAME##Adapter);
    }

    /// <summary>
    /// Unregisters the native callback and releases the adapter.
    /// Called automatically when the last subscriber is removed.
    /// </summary>
    private void Unregister##EVENT_NAME()
    {
        if (_##EVENT_NAME##Adapter == null)
            return;

        // Unregister from native code
        NATIVE_SETTER(null);

        // Release adapter and unroot to allow GC
        ConnectedSpacesPlatformDotNet.AsyncLifetime.Unroot(_##EVENT_NAME##Adapter);
        _##EVENT_NAME##Adapter = null;
    }

%}   // End of proxycode
}    // End of extension

%enddef