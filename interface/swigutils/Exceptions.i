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
// SWIG Managed-Side Disposal Guard
//
// Defensive check preventing the passing of C# SWIG proxies with null native handles
// (already disposed in managed code) down to C++. 
// 
// IMPORTANT: This DOES NOT protect against C++-owned deletions (use-after-free) 
// where the C# handle remains non-zero.
//
// If this exception is thrown, it indicates a bug in the calling C# code
// (e.g., trying to use an object after it has been disposed).
// -----------------------------------------------------------------------------
%typemap(csin) SWIGTYPE * "($csinput != null && $csclassname.getCPtr($csinput).Handle == global::System.IntPtr.Zero) ? throw new global::System.ObjectDisposedException(\"$csinput\", \"Passed a disposed C# SWIG wrapper (null native handle) to C++. This indicates an object lifecycle bug needing investigation. Note: This does not detect C++-side deletions.\") : $csclassname.getCPtr($csinput)"
