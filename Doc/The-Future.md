# The Future

Hi there! This is Elliot, one of the original authors of this interop surface.

The date today is 19/02/2026. I am going to attempt to dump all of the future speculation/where-the-bodies-are-buried notions that are in my head into this document.
Beware that this may become horrifically, perilously out of date by the time you read this, so use your best judgement.

The motivation here is that I am moving off the project full-time, and leaving it in the hands of the CSharp/Unity team, particularly Alessio, who has been working with me.

There's no narrative here, just segments of thought. Enjoy. :D

> [!NOTE]
>
> The things I say here arn't "Project Policy" or anything like that. I know some collaborators have valid disagreements to some of my takes here. This is a personal brain-dump, so take it with a grain of salt.

## Pushing SWIG Unity adaptations upstream

In order to work in all Unity compilation modes, (specifically IL2CPP), we use a custom SWIG forks that inserts the `[MonoPInvokeCallback]` attribute.
There's a neat description of the problem [here](https://gitlab.com/rdi-eg/docs/-/wikis/Targeting-iOS-on-Unity3D-using-C%23-swig-generated-code---pitfalls-and-gotchas/diff?version_id=130894855efdab4f0cbd9882e7dc35554fea92bd&view=inline), and our SWIG fork can be found [here](https://github.com/MAG-ElliotMorris/swig-il2cpp-directors).

There have been [several attempts](https://github.com/MAG-ElliotMorris/swig-il2cpp-directors/commit/95de8e26fdf10984abb2e6a574c265edde2734bf) to make this adaptation to the upstream SWIG repo, that have failed/been delayed for what seems like purely procedural reasons, or just people getting bored and giving up.

It would be good for us, and others, if this change landed upstream. However, the change as implemented likely won't be accepted, because I didn't account for [callback overloads](https://github.com/MAG-ElliotMorris/swig-il2cpp-directors/blob/b4fbd52177d8d70add87b44b0fa09b476269b232/Source/Modules/csharp.cxx#L4096), as we never use the return type of the callback, let alone overload on them.

## LocalCHS integration testing

Our CI pipeline is github actions based. This is pleasant, but does have the implication that we are outside of the Magnopus VPN, and thus can't run end-to-end integration tests.

Whether we even want to do this is an open question. Service interaction is not _the point_ of an interop surface, but CSP is such a service oriented API it is conceivable the two concerns could interact.

There's several solutions to this, if you wished to pursue them:

- Move to a CI system inside the VPN (teamcity currently)
- Figure out how to get CHS access from outside the VPN for testing, or enter the VPN from inside an actions runner.
- Use LocalCHS to test against a locally hosted CHS instance.

A similar problem applies to testing within the Unity environment itself, although the problem is more about managing licenses there.

## Further Unity adaptations

Currently we do minimal adaptations to Unity specific types behind the `SWIG_UNITY_EXTENSIONS` flag. Adding methods to convert Vector types and whatnot.

You could go quite a bit further here if you wished, even changing the API such that when generated with Unity extensions, Unity types are what is passed directly in and out of interfaces. I can't imagine what sort of conveniences/extensions you might want, but I'm sure there's a lot.

> [!WARNING]
>
> Please remember that Unity is not the only target of this repo. The Unity adaptations are behind build flags for a good reason. Do not confuse accidental complexity incurred by the Magnopus Unity Team to general Unity, or god forbid, .NET problems. 

## Beware infinitely growing test suites

There is a common wisdom that the more tests == the more better. This is a thought terminating cliche and false.

The XUnit tests are our primary gating tests, and they're reasonably okay. However, they were written in order to support development, and are not all necessarily useful as continually running tests.

It is important that a full cycle of this project remains reasonably fast, Do not add tests that take a long time to execute to the default execution profile of this test project, or any test project that runs on commit. You can use the environment variable driven `Fact` annotation to add tests that do not run by default.

The reason this is important is that we want the CSP team to maintain interfaces during their PR process. If you make this difficult or frictionful, that will stop

## All the warnings
Upon delivery of this project, there is a fair amount of compiler/SWIG warnings.

I am _almost_ certain that these are harmless, and I think they fall into just a few categories that can be resolved all at once. Y'all should get rid of them. If I find a spare second I may do something on this before I rotate off the project. Knowing how reality works though ... I doubt it.

Once you get rid of them, turn on warnings as errors for your own good.

## Don't fear the C++
SWIG is extremely flexible, and you can achieve various adaptations at different layers in the stack.

It's going to seem easier to C# devs to insert proxycode into the C# layer. Whilst this is often the correct choice, remember to reflect on whether you're doing this merely out of unfamiliarity. It is sometimes the best choice to insert C++ level adaptations, as you can have access to additional API's at that level.

A good example of this is hashing. We _could_ have solved hashing purely at the C# level, but that would create disconnected implementation from the underlying C++, and potentially lead to subtle bugs later on down the line. Remember, any additional software layer is a potential point of failure. Systems with more layers exponentially approach guaranteed likelihood of error even if each given layer has a low error-rate. 

It may be uncomfortable, especially if you need to do cross team work with the CSP team, but there is virtue here. Just something to keep in mind.

## Misleading action signiatures
The signature to `SetLogCallback` is as follows.

```csharp
public void SetLogCallback(LogCallbackHandlerAdapter InLogCallback); 
```

However, `LogCallbackHandlerAdapter` is not what you want to construct to pass into this function. That is a director type, and is in fact a base class. What you actually want to do is use the [action adapter](../interface/Declarations/AsyncDeclarations.i) that inherits from this base type :

```csharp
  using ConnectedSpacesPlatformDotNet.LogCallback callback1 = new ConnectedSpacesPlatformDotNet.LogCallback((logLevel, message) =>
  {
    //Do something, probably log eh?
  });

  logSystem.SetLogCallback(callback1);
```

It is unfortunate that there's no clear way to discover what the inherited type is from the signature, short of looking at the declarations.

Perhaps there are ways to remedy this, even naming the director object ,`LogCallbackHandlerAdapter` in this instance, to something like `LogCallbackHandlerAdapterDirectorBase` may help.

The location of these adapters is also suspect, is `ConnectedSpacesPlatformDotNet` the best place for them?

## Action-based registerable callbacks & lifetime management

In order to keep async callbacks alive, they are pinned in a [central pinning array](../interface/swigutils/AsyncLifetime.i) until the task completes, with either a success or failure state. This is the case for functions that look like `X x = await X();` when called.

For registerable callbacks that looks like :

```csharp
ConnectedSpacesPlatformDotNet.MyActionAdapter MyAction((x) => {
    Log(x);
});

CSPSystem.SetCallback(MyAction);
```

this is not the case. These callbacks need to be kept safe from the garbage collector manually by the implementor.

It is conceivable to use this same central pinning array to pin even registerable callbacks. There's some pleasentness to this, as it means you never have to worry about GC when interacting with CSP in the common case, and it provides a central buffer of all currently registered callbacks in the system, that I can imagine being useful in all sorts of fun ways.

However, there are problems also. Registerable callbacks have no defined end, unlike async style callbacks they may be called more than once. When do you unpin them, if ever? It seems natural to me that C# devs are capable of managing callback lifetime, and perhaps even unexpected that we would pin them, as that isn't what happens when working with delegates/actions. Then again, i'm not an expert C# dev so I don't know what is most expectable.

## Profiling & Performance

It is unknown how much overhead this interop layer introduces. That being said, it's unknown how much overhead CSP introduces generally. At the present time, the org pays very little attention to performance profiling.

Tbh, I don't disagree with this stance, although it is becoming stark that we need _some_ data on this sort of stuff, if only to guard against pathological performance regressions. 

## Do you need all this API?

This is a declarative project, the main API declarations are [here.](../interface/Declarations/APIDeclarations.i)

Do you actually want all this API? Unity is a unique SKU with unique needs. It would be virtuous to only expose the API you actually care about. This is totally doable and not that much effort, just don't include the `.i` files you don't care about. You'd want to do this behind some sort of guard or configuration variable, because you still want the whole API available to general consumers. A utility to only include subsets of API seems appealing ... although I wonder if that's a patch-job over CSP modularization. 

Keep in mind there may be dependencies between different pieces of API, but the compiler will tell you about this.

> [!WARNING]
>
> Remember to check the install directory manually when changing API declarations. If there are any SWIGTYPE files, that means that there is declared API surface that SWIG does not know how to wrap and has exposed an opaque pointer. It may be advisable to create a CI check that bans SWIGTYPE files.

## Debug Visualisations

An ergonomics issue with this sort of approach where every object is a pointer-managing proxy is that when debugging, you can't always inspect the internals of an object, as all you can see is `swigCPtr`. You can always step down through getters, but that's burdensome.

CSharp has some [pleasant looking ways](https://learn.microsoft.com/en-us/visualstudio/debugger/using-the-debuggerdisplay-attribute?view=visualstudio) of dealing with this. The real challenge will be in finding a worthwhile tradeoff the makes maintaining the debug visualizations worth the squeeze. Possibly a reflection based solution?

## Autogenerating Declarations

This is not a fully automatic code generator, it requires explicit declarations for some element, in particular async interfaces. This provides a fair amount of flexibility, you can see how we use this to invoke copy constructors for callback results, removing ownership concerns for reference types.

There will be an instinct to automate many of these declarations as they are so rote. This isn't inherently unvirtuous, but I invite you to reflect on this before you do it.

If you do end up doing this, you'll need a way to iterate through C++ declarations. SWIG may provide a way as it has a full compiler toolchain to lean on, but I am not aware of anything. DO NOT try to parse C++ headers yourself, it is formally impossible to do without annotation, and informally a bloody hard thing to be doing even if you limit yourself to a language subset. The whole point of this project was to free the underlying CSP headers from the restrictions half-baked manual parses were causing.

It is not yet clear how burdensome maintaining these declarations is going to be. Automation may be a completely redundant exercise if maintaining them never becomes a significant problem.

> [!WARNING]
>
> If you're still struggling to write declarations correctly, you're not prepared to automate them. Automation is something you do to alleviate human burden, not human understanding.

## ThrowOnFailure Pattern

This repo inherited a pattern from the Magnopus Unity repo, ThrowOnFailue, it's guarded behind a build flag `ENABLE_THROW_EXCEPTION_ON_RESULTBASE_FAILURE` which is on by default.

What this does is convert any `ResultBase` object that finishes with a failure flag into an exception, which is a custom exception defined in Csharp.

My personal take is that this pattern is a _tad_ too specific to sit in this repo. If CSP had a uniform callback mechanic I might think differently, but it can return many other types in its callbacks other than `ResultBase`, which don't have clear failure states and will not throw in the same way. This won't be able to be documented clearly enough for new users to understand the difference.

The need to adjust this repo in order to integrate with existing patterns in the Magnopus Unity repo was valid, but nonetheless, ruminate on this. It is at least behind a flag, so users can still choose to interact with CSP in the standard way.

## Packaging
At time of writing, we haven't finished packaging fully. It seems obvious that this repo should publish directly to package index's if possible. I don't know how to make that happen, but it'd be neat. 

## Shared Team Ownership
This project will live in the magnopus opensource repo, and be a landing page for .NET and Unity developers who wish to consume the connected spaces platform.

With our present team arrangement, this implies shared ownership of this repo between the CSP and Unity teams.

How I imagine this is going to work is something like this.

- CSP has a backwards integration in their CI. When a CSP PR is raised, the CI will pull this repo and run a build and its unit tests.
- If this repo fails to build due to an interface break, CSP will address that immediately. They will commit to a `v.next` branch that will not require code review. It is vital that the CI be fast and stable.
- At such a time that the Unity team wishes to perform a release, they will merge `v.next` into `main` and perform a release using the artifacts that the projects CI generates on `main`. They should do this before CSP merges new interface updates for the _next_ release, or be sure to merge the appropriate reference.
- New API will be declared by the Unity team. Although I can imagine there's wiggle room on this, especially for large new api surfaces. I'd prefer the Unity team to be proactively pulling what they want rather than just having everything pushed on them.

If there is no release automation written by the time I have left the project, write some, it's not hard.

> [!NOTE]
>
> The Unity team owns this repo, they are the final decision makers, and the people who hold ultimate responsibility for any problems. 

## Wrapping brand new API
As best as I can remember, here's the checklist for when you are wrapping brand new API. I'm going to try to be exhaustive, most API won't need all of this.

Much of this can just be vibed once you have added the api declaration by running the generator and figuring out why there are SWIGTYPE files being generated. But if you'd prefer something more formal, here you go.

- If it is a completely new file, add a new `.i` file to `interface/CSP`. Use the same pattern as the other `.i` files, these are almost all identical.
    - If the file contains a type that is an interface, declare that in the `.i` file using `%interface_impl(csp::namespace::IMyType);`
    - If the file inherits from a type in a namespace other than its own, add the using directive for it in the `.i` file. (This is annoying, i'd like if there was a better solve for this.) 
    ```c
    //This type inherits from a type in another namespace (common, IRealtimeEngine), so we need the using directive
    %typemap(csimports) csp::multiplayer::OfflineRealtimeEngine %{
    using csp.common;
    %}
    ```
- Add this `.i` file to [APIDeclarations.i](../interface/Declarations/APIDeclarations.i)
- If there are new callback signatures, go to [CallbackDeclarations.i](../interface/Declarations/CallbackDeclarations.i) and add a `MAKE_CALLBACK` call.
- If there is an async interface (awaitable), go to [AsyncDeclarations.i](../interface/Declarations/APIDeclarations.i) and add a `MAKE_ASYNC` call.
  - If the async interface is instead a registerable callback, and not an awaitable one, ie `SetLogCallback`, add a `MAKE_ACTION_CALLBACK` declaration instead.
- If you hit compile errors that look like template symbol errors, you may need to add a template declaration to [TemplateDeclarations.i](../interface/Declarations/TemplateDeclarations.i)
- If there is an Optional type in the interface, add the `%optional` declaration to [OptionalDeclarations.i](../interface/Declarations/OptionalDeclarations.i)
- If the new type wants to be value or pointer equatable, add either `MAKE_VALUE_EQUATABLE` or `MAKE_POINTER_EQUATABLE` to [Equatable.i](../interface/swigutils/Equatable.i) (This should maybe be moved to `EquatableDeclarations.i, come to think of it.)
- Run the build. Open the XUnit test project, try to use your API to verify that it works. You probably don't need specific tests for specific API in this project, unless there's something novel happening in the interop mechanisms themselves. If you're doing that, then you probably don't need to be following this guide!