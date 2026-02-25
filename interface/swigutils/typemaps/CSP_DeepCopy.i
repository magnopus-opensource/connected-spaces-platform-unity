// Macro to add DeepCopy for any class
%define CSP_DEEP_COPY(CLASS)
    // C++ side: add a copy constructor wrapper
    %extend CLASS {
        CLASS* DeepCopy() {
            return new CLASS(*$self);
        }
    }

    // C# side: auto-generate DeepCopy() method that owns the copy
    %typemap(csclassmod) CLASS "
    public partial class $csclassname {
        public $csclassname DeepCopy() {
            global::System.IntPtr cPtr = ConnectedSpacesPlatformDotNetPINVOKE.$csclassname_DeepCopy(swigCPtr);
            return (cPtr == global::System.IntPtr.Zero) ? null : new $csclassname(cPtr, true);
        }
    }
    "
%enddef