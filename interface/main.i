/* Important to enable directors for anything that has callbacks, as that's the special 
 * SWIG magic that lets client code be called from inside C++.
 * The module name here should match the standard base name of the .dll */
%module(directors="1") ConnectedSpacesPlatform

/* Enable namespaces flags to try and keep original namespaces hierarchy */
%feature("nspace", 1);

/* Undefine all the CSP annotation macros so we have a chance of parsing the api naturally */
%include "swigutils/MacroZapper.i"

/* Enable void* mapping. See "Void pointers" section : https://www.swig.org/Doc4.1/CSharp.html */
%apply void *VOID_INT_PTR { void * }

%include "typemaps.i"
%include "stdint.i"
%include "enums.swg"
%include "std_except.i"
%include "swiginterface.i"
%include "swigutils/typemaps/Csp_String.i"
%include "swigutils/typemaps/Csp_Map.i"
%include "swigutils/typemaps/Csp_List.i"
%include "swigutils/typemaps/Csp_Array.i"

/* Optionals need a bit of config, as we need to setup the project to allow C# nullability */
#define SWIG_STD_OPTIONAL_USE_NULLABLE_REFERENCE_TYPES // Allow optional reference types (>C#8.0)
%include "swigutils/typemaps/Csp_Optional.i"
%include "swigutils/OptionalDeclarations.i"

%include "swigutils/CallbackAdapters.i"
%include "swigutils/CallbackLifetime.i"
%include "swigutils/AsyncAdapters.i"
%include "swigutils/Operators.i"
%include "swigutils/Equatable.i"

/* CSP non-exported symbols. Special exclusions that are too hard to fix upstream right this second.
   Anything here is a CSP mistake. They have types in their public interface that cannot be
   used downstream because they reference internal types/implementations. Not to mention that they
   don't export free function symbols as a rule. */
%ignore ToJson;
%ignore FromJson;
%ignore TierNameEnumToString;
%ignore TierFeatureEnumToString;
%ignore StringToTierNameEnum;
%ignore StringToTierFeatureEnum;
%ignore ConvertDTOAssetDetailType;
%ignore ConvertStringToAssetPlatform;
%ignore ConvertAssetPlatformToString;
%ignore AssetDetailDtoToAsset;
%ignore PrototypeDtoToAssetCollection;
%ignore SequenceDtoToSequence;
%ignore AnchorDtoToAnchor;
%ignore SortMaintenanceInfos;

/* Declare the api */

/* CSP */
%include "CSP/CSPFoundation.i"

////////// COMMON /////////////////////////////////////////////////////////////

/* CSP/Common */
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

/* CSP/Common/Interfaces */
/* Note: Interfaces tend to be defined with %interface_impl such that they
 * are generated as true C# interfaces. See the individual .i files. */
%include "CSP/Common/Interfaces/IAuthContext.i"
%include "CSP/Common/Interfaces/IJSScriptRunner.i"
%include "CSP/Common/Interfaces/InvalidInterfaceUserError.i"
%include "CSP/Common/Interfaces/IRealtimeEngine.i"
%include "CSP/Common/Interfaces/IScriptBinding.i"

/* CSP/Common/Systems/Log */
%include "CSP/Common/Systems/Log/LogSystem.i"
%include "CSP/Common/Systems/Log/LogLevels.i"

////////// SYSTEMS ////////////////////////////////////////////////////////////

/* CSP/Systems/Spaces */
%include "CSP/Systems/Spaces/UserRoles.i"

/* CSP/Systems*/
%include "CSP/Systems/SystemBase.i"
%include "CSP/Systems/WebService.i"
%include "CSP/Systems/SystemsResult.i"

/* CSP/systems/Assets*/
%include "CSP/Systems/Assets/Asset.h"

/* CSP/Common/Systems/Quota */
%include "CSP/Systems/Quota/Quota.i"
%include "CSP/Systems/Quota/QuotaSystem.i"

/* CSP/Systems/ECommerce */
%include "CSP/Systems/ECommerce/ECommerce.i"
%include "CSP/Systems/ECommerce/ECommerceSystem.i"

////////// MULTIPLAYER  ///////////////////////////////////////////////////////

/* CSP/Multiplayer/Script*/
// Put these first, CSP doesn't fully qualify the EntityScript typename in SpaceEntity,
// so if these aren't already declared, it won't be fully qualified in the output.
// Could alternatively forward declare if you were precious about the include ordering.
// You can move these if you don't get a build error, probably CSP has changed under you to make this fine.
%include "CSP/Multiplayer/Script/EntityScript.i"
%include "CSP/Multiplayer/Script/EntityScriptMessages.i"

/* CSP/Multiplayer*/
%include "CSP/Multiplayer/ComponentBase.i"
%include "CSP/Multiplayer/CSPSceneDescription.i"
%include "CSP/Multiplayer/MultiplayerConnection.i"
%include "CSP/Multiplayer/NetworkEventBus.i"
%include "CSP/Multiplayer/OfflineRealtimeEngine.i"
%include "CSP/Multiplayer/OnlineRealtimeEngine.i"
%include "CSP/Multiplayer/PatchTypes.i"
%include "CSP/Multiplayer/SpaceEntity.i"
%include "CSP/Multiplayer/SpaceTransform.i"

/* CSP/Multiplayer/Conversation*/
%include "CSP/Multiplayer/Conversation/Conversation.i"

/* CSP/Multiplayer/Components/Interfaces*/
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

/* CSP/Multiplayer/Components*/
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

/* CSP/Systems */

%include "CSP/Systems/CSPSceneData.i"
%include "CSP/Systems/ServiceStatus.i"
%include "CSP/Systems/SystemBase.i"
%include "CSP/Systems/SystemsManager.i"
%include "CSP/Systems/SystemsResult.i"
%include "CSP/Systems/WebService.i"
%include "CSP/Systems/Analytics/AnalyticsSystem.i"
%include "CSP/Systems/Assets/TextureInfo.i"
%include "CSP/Systems/Assets/Material.i"
%include "CSP/Systems/Assets/AlphaVideoMaterial.i"
%include "CSP/Systems/Assets/Asset.i"
%include "CSP/Systems/Assets/AssetCollection.i"
%include "CSP/Systems/Assets/LOD.i"
%include "CSP/Systems/Assets/AssetSystem.i"
%include "CSP/Systems/Assets/GLTFMaterial.i"
%include "CSP/Systems/ECommerce/ECommerce.i"
%include "CSP/Systems/ECommerce/ECommerceSystem.i"
%include "CSP/Systems/EventTicketing/EventTicketing.i"
%include "CSP/Systems/EventTicketing/EventTicketingSystem.i"
%include "CSP/Systems/ExternalServices/ExternalServiceInvocation.i"
%include "CSP/Systems/ExternalServices/ExternalServiceProxySystem.i"
%include "CSP/Systems/GraphQL/GraphQL.i"
%include "CSP/Systems/GraphQL/GraphQLSystem.i"
%include "CSP/Systems/HotspotSequence/HotspotGroup.i"
%include "CSP/Systems/HotspotSequence/HotspotSequenceSystem.i"
%include "CSP/Systems/Maintenance/Maintenance.i"
%include "CSP/Systems/Maintenance/MaintenanceSystem.i"
%include "CSP/Systems/Quota/Quota.i"
%include "CSP/Systems/Quota/QuotaSystem.i"
%include "CSP/Systems/Script/ScriptSystem.i"
%include "CSP/Systems/Sequence/Sequence.i"
%include "CSP/Systems/Sequence/SequenceSystem.i"
%include "CSP/Systems/Settings/ApplicationSettings.i"
%include "CSP/Systems/Settings/ApplicationSettingsSystem.i"
%include "CSP/Systems/Settings/SettingsCollection.i"
%include "CSP/Systems/Settings/SettingsSystem.i"
%include "CSP/Systems/Spatial/SpatialDataTypes.i"
%include "CSP/Systems/Spaces/Site.i"
%include "CSP/Systems/Spaces/Space.i"
%include "CSP/Systems/Spaces/SpaceSystem.i"
%include "CSP/Systems/Spaces/UserRoles.i"
%include "CSP/Systems/Spatial/Anchor.i"
%include "CSP/Systems/Spatial/AnchorSystem.i"
%include "CSP/Systems/Spatial/PointOfInterest.i"
%include "CSP/Systems/Spatial/PointOfInterestSystem.i"
%include "CSP/Systems/Users/Authentication.i"
%include "CSP/Systems/Users/Profile.i"
%include "CSP/Systems/Users/ThirdPartyAuthentication.i"
%include "CSP/Systems/Users/UserSystem.i"
%include "CSP/Systems/Voip/VoipSystem.i"


%include "swigutils/TemplateDeclarations.i"