%{
#include "CSP/Multiplayer/OnlineRealtimeEngine.h"
%}

//This type inherits from a type in another namespace (common, IRealtimeEngine), so we need the using directive
%typemap(csimports) csp::multiplayer::OnlineRealtimeEngine %{
using csp.common;
%}

%include "CSP/Multiplayer/OnlineRealtimeEngine.h"
