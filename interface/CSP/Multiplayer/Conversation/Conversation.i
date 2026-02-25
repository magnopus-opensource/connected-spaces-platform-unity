%{
#include "CSP/Multiplayer/Conversation/Conversation.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::MessageInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::MessageUpdateParams)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AnnotationUpdateParams)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AnnotationData)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::MessageResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::MessageCollectionResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::ConversationResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::NumberOfRepliesResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AnnotationResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::multiplayer::AnnotationThumbnailCollectionResult)

%include "CSP/Multiplayer/Conversation/Conversation.h"
