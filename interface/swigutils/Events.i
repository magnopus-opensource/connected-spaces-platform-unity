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
            if (_##EVENT_NAME##Adapter == null)
            {
                // First subscriber, create adapter. Note that this automatically subscribes the passed value.
                _##EVENT_NAME##Adapter = new ACTION_CALLBACK_TYPENAME(value);
                // Register with native code
                NATIVE_SETTER(_##EVENT_NAME##Adapter);
            }
            else
            {
                // We already had an adapter existing, just subscribe to the event.
                _##EVENT_NAME##Adapter!.Invoked += value;
                // Note: we should not need to call the NATIVE_SETTER again since it was supposed to be set on adapter creation.
            }
        }
        remove
        {
            if (_##EVENT_NAME##Adapter == null)
            {
                // This should not happen
                var eventNameAdapter = nameof(_##EVENT_NAME##Adapter);
                var eventName = nameof(EVENT_NAME);
%}

#ifdef SWIG_UNITY_EXTENSIONS
%proxycode %{
                UnityEngine.Debug.LogError($"{eventNameAdapter} is null when trying to remove subscriber from {eventName}.");
%}
#else
%proxycode %{
                System.Console.Error.WriteLine($"{eventNameAdapter} is null when trying to remove subscriber from {eventName}.");
%}
#endif

%proxycode %{
                return;
            }

            _##EVENT_NAME##Adapter.Invoked -= value;

            if (!_##EVENT_NAME##Adapter.HasSubscribers)
            {
                // Unregister from native code
                NATIVE_SETTER(null);

                // No more subscribers, clean up adapter
                _##EVENT_NAME##Adapter = null;
            }
        }
    }

%}   // End of proxycode
}    // End of extension

%enddef