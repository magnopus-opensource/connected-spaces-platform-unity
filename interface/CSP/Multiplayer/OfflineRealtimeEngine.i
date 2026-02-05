%{
#include "CSP/Multiplayer/OfflineRealtimeEngine.h"
%}

//This type inherits from a type in another namespace (common, IRealtimeEngine), so we need the using directive
%typemap(csimports) csp::multiplayer::OfflineRealtimeEngine %{
using csp.common;
%}

%include "CSP/Multiplayer/OfflineRealtimeEngine.h"
