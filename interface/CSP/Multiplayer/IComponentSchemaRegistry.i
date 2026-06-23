%{
#include "CSP/Multiplayer/IComponentSchemaRegistry.h"
%}

// You might expect this to be an interface, but we never intend to implement it in C#, so we don't need to mark it as 
// an interface. This is to be treated as a concrete class, and should probably be renamed in CSP as well.
//%interface_impl(csp::multiplayer::IComponentSchemaRegistry);

%include "CSP/Multiplayer/IComponentSchemaRegistry.h"
