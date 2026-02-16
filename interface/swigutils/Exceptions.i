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