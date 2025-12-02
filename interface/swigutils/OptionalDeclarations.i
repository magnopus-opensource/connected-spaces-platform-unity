/*
 * Enable nullable reference type annotations for generated C# code
 * Important because we want to use `?` syntax for all Optional<T>
 * interfaces, and the CSharp compiler will warn otherwise.
 * (This is all legacy from C#8 allowing nullable reference types finally)
 * You can do this as a project level setting, but doing it like this means consumers don't need to care.
 */
%typemap(csimports) SWIGTYPE %{
#nullable enable
%}

/* 
 * Call the typemap macros to declare all the optional types the api expresses
 * Reference types (classes) and value types (Nullable<T>) are handled differently,
 * with value types using .HasValue() and .Value(), in the interop layer, whilst
 * reference types just use `null` (? is merely an annotation). This is because
 * value types are implicitly convertible to Nullable<T>.
 * From the c# users perspective, everything looks like T? in the interface.
 *
 * You should include this before general api declaration
 */

%include "swigutils/typemaps/Csp_Optional.i"

DEFINE_OPTIONAL_REFERENCE_TYPE(OptionalFeatureFlagArray, csp::common::Array<csp::FeatureFlag>)
DEFINE_OPTIONAL_REFERENCE_TYPE(OptionalHotspotSequenceChangedNetworkEventData, csp::common::HotspotSequenceChangedNetworkEventData)

DEFINE_OPTIONAL_REFERENCE_TYPE(OptionalString, csp::common::String) //string is a reference type in c#.

DEFINE_OPTIONAL_VALUE_TYPE(OptionalShort, short)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalInt, int)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalFloat, float)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalDouble, double)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalBool, bool)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalChar, char)

DEFINE_OPTIONAL_VALUE_TYPE(OptionalByte, unsigned char)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalSByte, signed char)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalUShort, unsigned short)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalUInt, unsigned int) 
DEFINE_OPTIONAL_VALUE_TYPE(OptionalLong, long long)
DEFINE_OPTIONAL_VALUE_TYPE(OptionalULong, unsigned long long)