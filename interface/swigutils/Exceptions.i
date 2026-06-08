/*
 * General purpose exception handler.
 * This is responsible for converting native C++ exceptions into C# exceptions.
 * Note that the exception is detected only on SWIGPendingException.Retrieve().
 */
%exception {
  try {
    $action
  }
  catch (const std::exception& e) {
    SWIG_CSharpSetPendingException(SWIG_CSharpApplicationException, e.what());
    return $null;
  }
}

// -----------------------------------------------------------------------------
// Global Zombie Pointer Safety Guard
// Prevents dead SWIG proxy objects from passing invalid handles down to C++
// -----------------------------------------------------------------------------
%typemap(csin) SWIGTYPE * "($csinput != null && $csclassname.getCPtr($csinput).Handle == global::System.IntPtr.Zero) ? throw new global::System.ObjectDisposedException(\"$csinput\", \"Catastrophic Error: Cannot pass a zombie SWIG object with a deleted native pointer.\") : $csclassname.getCPtr($csinput)"