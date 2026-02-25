%{
#include "CSP/Multiplayer/OnlineRealtimeEngine.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::OnlineRealtimeEngine)

//This type inherits from a type in another namespace (common, IRealtimeEngine), so we need the using directive
%typemap(csimports) csp::multiplayer::OnlineRealtimeEngine %{
using csp.common;
%}

%include "CSP/Multiplayer/OnlineRealtimeEngine.h"
