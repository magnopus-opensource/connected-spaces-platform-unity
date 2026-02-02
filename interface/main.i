/* Important to enable directors for anything that has callbacks, as that's the special 
 * SWIG magic that lets client code be called from inside C++.
 * The module name here should match the standard base name of the .dll */
%module(directors="1") ConnectedSpacesPlatform

/* Enable namespaces flags to try and keep original namespaces hierarchy */
%feature("nspace", 1);

/* Undefine all the CSP annotation macros so we have a chance of parsing the api naturally */
%include "swigutils/MacroZapper.i"

/* Enable void* mapping. See "Void pointers" section : https://www.swig.org/Doc4.1/CSharp.html */
%apply void *VOID_INT_PTR { void * }

%include "typemaps.i"
%include "stdint.i"
%include "enums.swg"
%include "swigutils/typemaps/Csp_String.i"
%include "swigutils/typemaps/Csp_Map.i"
%include "swigutils/typemaps/Csp_List.i"
%include "swigutils/typemaps/Csp_Array.i"

/* Optionals need a bit of config, as we need to setup the project to allow C# nullability */
#define SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES // Allow optional reference types (>C#8.0)
%include "swigutils/typemaps/Csp_Optional.i"
%include "swigutils/OptionalDeclarations.i"

%include "swigutils/CallbackAdapters.i"
%include "swigutils/AsyncAdapters.i"
%include "swigutils/Operators.i"
%include "swigutils/Equatable.i"

/* CSP non-exported symbols. Special exclusions that are too hard to fix upstream right this second.
   Anything here is a CSP mistake. They have types in their public interface that cannot be
   used downstream because they reference internal types/implementations. */
%ignore ToJson;
%ignore TierNameEnumToString;
%ignore TierFeatureEnumToString;
%ignore StringToTierNameEnum;
%ignore StringToTierFeatureEnum;

/* Declare the api */

/* CSP */
%include "CSP/CSPFoundation.i"

////////// COMMON /////////////////////////////////////////////////////////////

/* CSP/Common */
%include "CSP/Common/CancellationToken.i"
%include "CSP/Common/Hash.i"
%include "CSP/Common/LoginState.i"
%include "CSP/Common/MimeTypeHelper.i"
%include "CSP/Common/NetworkEventData.i"
%include "CSP/Common/ReplicatedValue.i"
%include "CSP/Common/Settings.i"
%include "CSP/Common/SharedConstants.i"
%include "CSP/Common/SharedEnums.i"
%include "CSP/Common/Vector.i"

/* CSP/Common/Interfaces */
/* If we ever want to implement interfaces in Csharp, rather than just using
 * C++ defined ones, we will need/want to declare these as %interface.
 * The following link is java doc, but the C# SWIG library is practically
 * identical : https://www.swig.org/Doc4.4/SWIGDocumentation.html#Java_interfaces 
 * This will absolutely matter in the case of multiple-inheritance, as non-interface
 * multi-inheritance is not supported in C#, unlike C++.
 * Currently, the specific implementation of these don't really matter very much
 * to C# users from an API perspective */
%include "CSP/Common/Interfaces/IAuthContext.i"
%include "CSP/Common/Interfaces/IJSScriptRunner.i"
%include "CSP/Common/Interfaces/InvalidInterfaceUserError.i"
%include "CSP/Common/Interfaces/IRealtimeEngine.i"
%include "CSP/Common/Interfaces/IScriptBinding.i"

/* CSP/Common/Systems/Log */
%include "CSP/Common/Systems/Log/LogSystem.i"
%include "CSP/Common/Systems/Log/LogLevels.i"

////////// SYSTEMS ////////////////////////////////////////////////////////////

/* CSP/Systems/Spaces */
%include "CSP/Systems/Spaces/UserRoles.i"

/* CSP/Systems*/
%include "CSP/Systems/SystemBase.i"
%include "CSP/Systems/WebService.i"
%include "CSP/Systems/SystemsResult.i"

/* CSP/Common/Systems/Quota */
%include "CSP/Systems/Quota/Quota.i"
%include "CSP/Systems/Quota/QuotaSystem.i"

/* CSP/Systems/ECommerce */
%include "CSP/Systems/ECommerce/ECommerce.i"
%include "CSP/Systems/ECommerce/ECommerceSystem.i"

////////// MULTIPLAYER  ///////////////////////////////////////////////////////



%include "swigutils/TemplateDeclarations.i"