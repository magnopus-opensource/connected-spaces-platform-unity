
/* CSP */
%include "CSP/CSPFoundation.i"

////////// COMMON /////////////////////////////////////////////////////////////

/* Common Types */
%include "CSP/Common/CancellationToken.i"
%include "CSP/Common/Hash.i"
%include "CSP/Common/LoginState.i"
%include "CSP/Common/MimeTypeHelper.i"
%include "CSP/Common/NetworkEventData.i"
%include "CSP/Common/ReplicatedValue.i"
%include "CSP/Common/Settings.i"
%include "CSP/Common/SharedConstants.i"
%include "CSP/Common/SharedEnums.i"
%include "CSP/Common/Vector.i"

/* Cross Module Interfaces */
/* Note: Interfaces tend to be defined with %interface_impl such that they
 * are generated as true C# interfaces. See the individual .i files. */
%include "CSP/Common/Interfaces/IAuthContext.i"
%include "CSP/Common/Interfaces/IJSScriptRunner.i"
%include "CSP/Common/Interfaces/InvalidInterfaceUserError.i"
%include "CSP/Common/Interfaces/IRealtimeEngine.i"
%include "CSP/Common/Interfaces/IScriptBinding.i"

/* Logging */
%include "CSP/Common/Systems/Log/LogSystem.i"
%include "CSP/Common/Systems/Log/LogLevels.i"


////////// MULTIPLAYER  ///////////////////////////////////////////////////////

// Put these first, CSP doesn't fully qualify the EntityScript typename in SpaceEntity,
// so if these aren't already declared, it won't be fully qualified in the output.
// Could alternatively forward declare if you were precious about the include ordering.
// You can move these if you don't get a build error, probably CSP has changed under you to make this fine.
%include "CSP/Multiplayer/Script/EntityScript.i"
%include "CSP/Multiplayer/Script/EntityScriptMessages.i"

/* Multiplayer Top Level */
%include "CSP/Multiplayer/ComponentBase.i"
%include "CSP/Multiplayer/ComponentProperty.i"
%include "CSP/Multiplayer/ComponentSchema.i"
%include "CSP/Multiplayer/CSPSceneDescription.i"
%include "CSP/Multiplayer/IComponentSchemaRegistry.i"
%include "CSP/Multiplayer/MultiplayerConnection.i"
%include "CSP/Multiplayer/NetworkEventBus.i"
%include "CSP/Multiplayer/OfflineRealtimeEngine.i"
%include "CSP/Multiplayer/OnlineRealtimeEngine.i"
%include "CSP/Multiplayer/PatchTypes.i"
%include "CSP/Multiplayer/SpaceEntity.i"
%include "CSP/Multiplayer/SpaceTransform.i"

/* Conversations '*/
%include "CSP/Multiplayer/Conversation/Conversation.i"

/* Component Interfaces */
%include "CSP/Multiplayer/Components/Interfaces/IAudioControlComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IEnableableComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IExternalResourceComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IPositionComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IRenderBehaviourComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IRotationComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IScaleComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IShadowCasterComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IThirdPartyComponentRef.i"
%include "CSP/Multiplayer/Components/Interfaces/ITransformComponent.i"
%include "CSP/Multiplayer/Components/Interfaces/IVisibleComponent.i"

/* Components */
%include "CSP/Multiplayer/Components/AIChatbotComponent.i"
%include "CSP/Multiplayer/Components/AnimatedModelSpaceComponent.i"
%include "CSP/Multiplayer/Components/AudioSpaceComponent.i"
%include "CSP/Multiplayer/Components/AvatarSpaceComponent.i"
%include "CSP/Multiplayer/Components/BillBoardModeEnum.i"
%include "CSP/Multiplayer/Components/ButtonSpaceComponent.i"
%include "CSP/Multiplayer/Components/CinematicCameraSpaceComponent.i"
%include "CSP/Multiplayer/Components/CollisionSpaceComponent.i"
%include "CSP/Multiplayer/Components/ConversationSpaceComponent.i"
%include "CSP/Multiplayer/Components/CustomSpaceComponent.i"
%include "CSP/Multiplayer/Components/ECommerceSpaceComponent.i"
%include "CSP/Multiplayer/Components/ExternalLinkSpaceComponent.i"
%include "CSP/Multiplayer/Components/FiducialMarkerSpaceComponent.i"
%include "CSP/Multiplayer/Components/FogSpaceComponent.i"
%include "CSP/Multiplayer/Components/GaussianSplatSpaceComponent.i"
%include "CSP/Multiplayer/Components/HotspotSpaceComponent.i"
%include "CSP/Multiplayer/Components/ImageSpaceComponent.i"
%include "CSP/Multiplayer/Components/LightSpaceComponent.i"
%include "CSP/Multiplayer/Components/PortalSpaceComponent.i"
%include "CSP/Multiplayer/Components/ReflectionSpaceComponent.i"
%include "CSP/Multiplayer/Components/ScreenSharingSpaceComponent.i"
%include "CSP/Multiplayer/Components/ScriptSpaceComponent.i"
%include "CSP/Multiplayer/Components/SplineSpaceComponent.i"
%include "CSP/Multiplayer/Components/StaticModelSpaceComponent.i"
%include "CSP/Multiplayer/Components/TextSpaceComponent.i"
%include "CSP/Multiplayer/Components/VideoPlayerSpaceComponent.i"

////////// SYSTEMS ////////////////////////////////////////////////////////////
/* Base System Functionality */
%include "CSP/Systems/SystemBase.i"
%include "CSP/Systems/WebService.i"
%include "CSP/Systems/SystemsResult.i"
%include "CSP/Systems/CSPSceneData.i"
%include "CSP/Systems/ServiceStatus.i"
%include "CSP/Systems/SystemsManager.i"

/* Analytics */
%include "CSP/Systems/Analytics/AnalyticsSystem.i"

/* Assets */
%include "CSP/Systems/Assets/TextureInfo.i"
%include "CSP/Systems/Assets/Material.i"
%include "CSP/Systems/Assets/AlphaVideoMaterial.i"
%include "CSP/Systems/Assets/Asset.i"
%include "CSP/Systems/Assets/AssetCollection.i"
%include "CSP/Systems/Assets/LOD.i"
%include "CSP/Systems/Assets/AssetSystem.i"
%include "CSP/Systems/Assets/GLTFMaterial.i"

/* ECommerce */
%include "CSP/Systems/ECommerce/ECommerce.i"
%include "CSP/Systems/ECommerce/ECommerceSystem.i"

/* Ticketing */
%include "CSP/Systems/EventTicketing/EventTicketing.i"
%include "CSP/Systems/EventTicketing/EventTicketingSystem.i"

/* ExternalServices */
%include "CSP/Systems/ExternalServices/ExternalServiceInvocation.i"
%include "CSP/Systems/ExternalServices/ExternalServiceProxySystem.i"

/* GraphQL */
%include "CSP/Systems/GraphQL/GraphQL.i"
%include "CSP/Systems/GraphQL/GraphQLSystem.i"

/* Maintenance */
%include "CSP/Systems/Maintenance/Maintenance.i"
%include "CSP/Systems/Maintenance/MaintenanceSystem.i"

/* Quota */
%include "CSP/Systems/Quota/Quota.i"
%include "CSP/Systems/Quota/QuotaSystem.i"

/* Analytics */
%include "CSP/Systems/Script/ScriptSystem.i"

/* Sequences */
%include "CSP/Systems/Sequence/Sequence.i"
%include "CSP/Systems/Sequence/SequenceSystem.i"
%include "CSP/Systems/HotspotSequence/HotspotGroup.i"
%include "CSP/Systems/HotspotSequence/HotspotSequenceSystem.i"

/* Settings */
%include "CSP/Systems/Settings/ApplicationSettings.i"
%include "CSP/Systems/Settings/ApplicationSettingsSystem.i"
%include "CSP/Systems/Settings/SettingsCollection.i"
%include "CSP/Systems/Settings/SettingsSystem.i"

// Unfortunately Spaces have a transient dependency on this so gets included first. CSP should fix.
%include "CSP/Systems/Spatial/SpatialDataTypes.i"

/* Spaces */
%include "CSP/Systems/Spaces/UserRoles.i"
%include "CSP/Systems/Spaces/Site.i"
%include "CSP/Systems/Spaces/Space.i"
%include "CSP/Systems/Spaces/SpaceSystem.i"

/* Spatial */
%include "CSP/Systems/Spatial/Anchor.i"
%include "CSP/Systems/Spatial/AnchorSystem.i"
%include "CSP/Systems/Spatial/PointOfInterest.i"
%include "CSP/Systems/Spatial/PointOfInterestSystem.i"

/* Users */
%include "CSP/Systems/Users/Authentication.i"
%include "CSP/Systems/Users/Profile.i"
%include "CSP/Systems/Users/ThirdPartyAuthentication.i"
%include "CSP/Systems/Users/UserSystem.i"

/* Voip */
%include "CSP/Systems/Voip/VoipSystem.i"
