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
%include "std_except.i"
%include "swiginterface.i"
%include "swigutils/typemaps/Csp_String.i"
%include "swigutils/typemaps/Csp_Map.i"
%include "swigutils/typemaps/Csp_List.i"
%include "swigutils/typemaps/Csp_Array.i"
%include "swigutils/typemaps/Csp_Optional.i"

/* Optionals need a bit of config, as we need to setup the project to allow C# nullability */
#define SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES // Allow optional reference types (>C#8.0)
%include "Declarations/OptionalDeclarations.i"
%include "Declarations/CallbackDeclarations.i"
%include "Declarations/AsyncDeclarations.i"

%include "swigutils/OuterObjectPins.i"
%include "swigutils/Exceptions.i"
%include "swigutils/Operators.i"
%include "swigutils/Equatable.i"
// Unity specific adaptations
%include "swigutils/UnityAdaptations.i"

/* CSP non-exported symbols. Special exclusions that are too hard to fix upstream right this second.
   Anything here is a CSP mistake. They have types in their public interface that cannot be
   used downstream because they reference internal types/implementations. Not to mention that they
   don't export free function symbols as a rule. */
%ignore ToJson;
%ignore FromJson;
%ignore TierNameEnumToString;
%ignore TierFeatureEnumToString;
%ignore StringToTierNameEnum;
%ignore StringToTierFeatureEnum;
%ignore ConvertDTOAssetDetailType;
%ignore ConvertStringToAssetPlatform;
%ignore ConvertAssetPlatformToString;
%ignore AssetDetailDtoToAsset;
%ignore PrototypeDtoToAssetCollection;
%ignore SequenceDtoToSequence;
%ignore AnchorDtoToAnchor;
%ignore SortMaintenanceInfos;

/* Declare the api, this is just including a bunch of .i files from the interface directory. */
%include "Declarations/APIDeclarations.i"

// Needs to be done after declaring the API.
%include "Declarations/TemplateDeclarations.i"