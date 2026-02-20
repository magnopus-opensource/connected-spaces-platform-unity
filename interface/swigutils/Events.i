/*
 * MAKE_EVENT_FOR_CALLBACK
 * ----------------------
 *
 * Generates a managed C# event that is backed by a native CSP-style callback.
 *
 * This macro bridges native callbacks into idiomatic C# event semantics, allowing
 * C# clients to subscribe and unsubscribe using standard += / -= syntax without
 * writing any callback plumbing themselves.
 *
 * Key features:
 * -------------
 * - Multicast event support (multiple subscribers)
 * - Lazy native callback registration (on first subscription)
 * - Automatic native callback unregistration (on last unsubscription)
 * - Correct lifetime management of native callback adapters
 * - No additional user-side boilerplate required
 *
 * The macro emits managed C# code into the SWIG-generated proxy class using
 * %proxycode. It relies on an action-based callback adapter created via
 * MAKE_ACTION_CALLBACK.
 *
 * This macro is suitable for exposing "SetXCallback(...)" style APIs as C# events.
 *
 *
 * Assumptions / Requirements:
 * ---------------------------
 *
 * 1. A native setter function exists with the following form:
 *
 *      void SetXCallback(CallbackType callback);
 *
 *    This setter must accept a callback adapter (or nullptr / null to unregister).
 *
 * 2. A managed action callback adapter has already been defined using
 *    MAKE_ACTION_CALLBACK. That adapter must:
 *
 *    - Inherit from the director callback base type
 *    - Accept a System.Action<PAYLOAD_TYPE> in its constructor
 *    - Forward native callback invocations to the managed Action
 *
 *
 * Generated C# Members:
 * ---------------------
 *
 * The macro generates the following members inside the proxy class:
 *
 *   private ACTION_CALLBACK_TYPENAME _<EVENT_NAME>Adapter;
 *   private Action<PAYLOAD_TYPE> _<EVENT_NAME>;
 *   private int _<EVENT_NAME>SubscriberCount;
 *
 *   public event Action<PAYLOAD_TYPE> EVENT_NAME;
 *
 *   private void Register<EVENT_NAME>Callback();
 *   private void Unregister<EVENT_NAME>Callback();
 *   private void On<EVENT_NAME>Native(PAYLOAD_TYPE args);
 *
 *
 * Event semantics:
 * ----------------
 *
 * - Native callback registration occurs when the first subscriber is added.
 * - Native callback unregistration occurs when the last subscriber is removed.
 * - The callback adapter is strongly rooted for the duration of the subscription.
 * - The event supports multicast delegates.
 *
 * Threading semantics are identical to the underlying native callback. If main-thread
 * dispatch (e.g. Unity) is required, it must be layered on top of this mechanism.
 *
 *
 * Parameters:
 * -----------
 *
 * EVENT_NAME
 *   - The public name of the C# event to be generated.
 *   - Used to derive managed helper method names (Register*, On*Native, etc.).
 *   - Example: OnNewLoginTokenReceived
 *
 * ACTION_CALLBACK_TYPENAME
 *  - The fully-qualified managed type name of an action callback adapter
 *    generated via MAKE_ACTION_CALLBACK.
 *  - This type must include the SWIG module namespace.
 *  - Example:
 *      ConnectedSpacesPlatformDotNet.LoginTokenInfoResultActionCallback
 *
 * NATIVE_SETTER
 *   - The exact name of the native setter function used to register and unregister
 *     the callback.
 *   - This function is called with:
 *       - An adapter instance when registering
 *       - null when unregistering
 *   - Example: SetNewLoginTokenReceivedCallback
 *
 * PAYLOAD_TYPE
 *   - The managed payload type exposed to event subscribers.
 *   - May be a single type or a comma-separated list of types for multi-parameter
 *     callbacks.
 *   - Must match the signature expected by ACTION_CALLBACK_TYPENAME.
 *
 *
 * Usage Example:
 * --------------
 *
 *   // Define the action callback adapter (once per signature)
 *   MAKE_ACTION_CALLBACK(
 *       LoginTokenInfoCallback,
 *       LoginTokenInfoResultCallbackAdapter,
 *       LoginTokenInfoResult value,
 *       LoginTokenInfoResult,
 *       value
 *   )
 *
 *   // Expose the native callback as a C# event
 *   MAKE_EVENT_FOR_CALLBACK(
 *       OnNewLoginTokenReceived,
 *       ConnectedSpacesPlatformDotNet.LoginTokenInfoCallback,
 *       SetNewLoginTokenReceivedCallback,
 *       LoginTokenInfoResult
 *   )
 *
 *
 * Resulting C# usage:
 * -------------------
 *
 *   instance.OnNewLoginTokenReceived += result =>
 *   {
 *       // Handle event
 *   };
 *
 *   instance.OnNewLoginTokenReceived -= handler;
 *
 *
 * Notes:
 * ------
 * - Native callback registration is reference-counted per event.
 * - Removing a handler that was never added is safely ignored.
 * - Callback adapter lifetime is fully managed by the generated proxy.
 * - Async/await wrappers can be layered on top of the same callback adapters.
 */
%define MAKE_EVENT_FOR_CALLBACK(EVENT_NAME, ACTION_CALLBACK_TYPENAME, NATIVE_SETTER, PAYLOAD_TYPE)
%proxycode %{
    private ACTION_CALLBACK_TYPENAME? _##EVENT_NAME##Adapter;
    private System.Action<object, PAYLOAD_TYPE>? _##EVENT_NAME;
    private int _##EVENT_NAME##SubscriberCount;

    public event System.Action<object, PAYLOAD_TYPE> EVENT_NAME
    {
        add
        {
            _##EVENT_NAME += value;

            if (++_##EVENT_NAME##SubscriberCount == 1)
                Register##EVENT_NAME##Callback();
        }
        remove
        {
            _##EVENT_NAME -= value;

            if (_##EVENT_NAME##SubscriberCount <= 0)
                return;

            if (--_##EVENT_NAME##SubscriberCount == 0)
                Unregister##EVENT_NAME##Callback();
        }
    }

    private void Register##EVENT_NAME##Callback()
    {
        _##EVENT_NAME##Adapter =
            new ACTION_CALLBACK_TYPENAME(On##EVENT_NAME##Native);

        NATIVE_SETTER(_##EVENT_NAME##Adapter);
    }

    private void Unregister##EVENT_NAME##Callback()
    {
        // Stop managed dispatch first
        _##EVENT_NAME = null;

        // Unregister native callback
        NATIVE_SETTER(null);

        // Release adapter
        _##EVENT_NAME##Adapter = null;
    }

    private void On##EVENT_NAME##Native(PAYLOAD_TYPE args)
        => _##EVENT_NAME?.Invoke(this, args);
%}

%enddef

