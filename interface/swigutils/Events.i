/*
 * This file defines a macro to conveniently generate a new event property in C# on a specific class. The new event
 * registers to a native C++ callback under the hood, and uses an action adapter (which is not directly
 * exposed to subscribers) to work. The reason for us to introduce such a macro is that it protects our delegate from 
 * being misused by other classes (e.g. by manually instantiating the adapter and forgetting to keep it alive, or by 
 * trying to alter the list of subscribers from within a subscriber scope). Another reason for us to introduce the 
 * macro is to give a specific name to an event that better represents its belonging to a specific class (such as 
 * OnNewLoginTokenReceived or OnUserPermissionsChanged for the UserSystem), without requiring client developers to
 * manually do it. This is a feature we already used for example in our Unity client, and we believe could benefit
 * also generic C# applications that make use of CSP.
 *
 * The lifetime of the callback used by the action adapter of the new event is tied to the lifetime of the adapter itself,
 * which exists as long as the event has at least one subscriber. This is handled automatically, and is one less thing
 * that client developers need to worry about thanks to this macro.
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
 * 2. A managed action adapter must already exist via MAKE_ACTION_ADAPTER.
 *
 * ----------------------------------------------------------------------
 * USAGE (C#)
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
 * Client developers do NOT need to manage adapter lifetimes or native registration.
 */

/*
 * Parameters:
 *
 * EVENT_NAME: The C# event name, e.g., OnNewLoginTokenReceived
 * ACTION_ADAPTER_TYPENAME: The action adapter type (e.g., ConnectedSpacesPlatformDotNet.LoginTokenInfoCallback).  
 *     Note that that the action adapter needs to exist already.
 * NATIVE_SETTER: The native registration method (e.g. SetNewLoginTokenReceivedCallback).
 * PAYLOAD_TYPE: The type passed to subscribers (e.g. csp.systems.LoginTokenInfoResult).
 * FULLY_NAMESPACED_CLASST: The full C++ class to extend (e.g. csp.systems.UserSystem).
 */
%define MAKE_EVENT_FOR_CALLBACK(
    EVENT_NAME,
    ACTION_ADAPTER_TYPENAME,
    NATIVE_SETTER,
    PAYLOAD_TYPE,
    FULLY_NAMESPACED_CLASST
)

#ifndef SWIG_ACTION_CALLBACK_##ACTION_ADAPTER_TYPENAME##_DEFINED
  %echo "[ERROR] MAKE_EVENT_FOR_CALLBACK: action adapter '" #ACTION_ADAPTER_TYPENAME "' was not defined! Cannot make event adapter around it."
#else

%extend FULLY_NAMESPACED_CLASST {
%proxycode %{

    // Single native action adapter instance for this event
    private ConnectedSpacesPlatformDotNet.##ACTION_ADAPTER_TYPENAME##? _##EVENT_NAME##Adapter;

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
                _##EVENT_NAME##Adapter = new ConnectedSpacesPlatformDotNet.##ACTION_ADAPTER_TYPENAME##(value);
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

#endif

%enddef