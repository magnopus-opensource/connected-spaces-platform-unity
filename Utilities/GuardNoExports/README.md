This script runs on the include directory of the fetched CSP release during the generation step.

See the script itself for implementation details, but the gist is we're working around the CSP_NO_EXPORT and CSP_START_IGNORE
annotations that the legacy wrapper generator uses. We do this by modifying the input headers to insert `#ifndef SWIG` blocks
around these things.

Having these guards is mandatory. Builds will fail without them.

This tool previously just deleted them from the headers, but that caused ABI breaks due to that also removing methods
from the SWIG C++ compile, including virtual methods. When put this way it is obvious this would break ABI, as the specific
layout of virtual methods is vital for ABI compatibility, and this created a mismatch between the CSP source and what SWIG
was compiling.
This way, the symbols are still visible to the C++ compiler, but not to the SWIG parser, meaning SWIG won't generate public
functions for these things. This crucially avoids the C++ compile referencing the inappropriately public internal types
that are sometimes contained within these blocks, which would cause us to fail to compile because we don't have (or want!)
the internal libs that provide these types (like async++) linked. 

This script performs an in-place mutation of the headers. If you are using `-DCSP_ROOT_DIR=` to use a custom CSP, you
should be aware of this. The non mutated headers are left in place in an `include_original` directory. It's unlikely
you'll be able to run this script twice, so if using a custom CSP, you will want to use `-DGUARD_CSP_NO_EXPORTS=Off` in
subsequent runs. This has no impact if you're just using the regular build options, as that downloads CSP and runs the
script fresh every time.

You'll note the test data, this is just a few files taken from CSP at time of writing to check the behavior.
You can invoke the tests by running `python3 -m pytest` from this directory. The tests just do a directory diff between
output and expectations.

The output for this doesn't have to be pretty, we just need the symbols gone. You'll note how we don't bother doing the logic
to delete the docs, since they're irrelevant. 