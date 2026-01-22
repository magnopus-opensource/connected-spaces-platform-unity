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

%optional_arithmetic(bool, OptBool)

%optional_arithmetic(std::int8_t, OptSignedByte)
%optional_arithmetic(std::int16_t, OptSignedShort)
%optional_arithmetic(std::int32_t, OptSignedInt)
%optional_arithmetic(std::uint8_t, OptUnsignedByte)
%optional_arithmetic(std::uint16_t, OptUnsignedShort)
%optional_arithmetic(std::uint32_t, OptUnsignedInt)
%optional_arithmetic(std::int64_t, OptSignedInt64)
%optional_arithmetic(std::uint64_t, OptUnsignedInt64)

%optional_arithmetic(float, OptFloat)
%optional_arithmetic(double, OptDouble)

%optional_string()

%optional(csp::common::Array<csp::FeatureFlag>)