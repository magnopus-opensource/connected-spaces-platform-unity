%module(directors="1") CspCommonVectors

%include "typemaps.i"
%include "carrays.i"

%{
#include "CSP/Common/Vector.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::common::Vector2)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::Vector3)
ADD_OUTER_OBJECT_PIN_SLOT(csp::common::Vector4)

%include "CSP/Common/Vector.h"
