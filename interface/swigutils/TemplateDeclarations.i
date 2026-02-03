/*
 * Template Declarations
 * C++ templates can never be properly supported in other languages, you always need to
 * provide some form of explicit instantiation and give concrete type names. This is that.
 * Note. This "ValueList/ValueArray" standard is sort of temporary during the migration,
 * we need to take an evaluation once we've got the fullness of the ratios between value/non-value arrays,
 * and decide on a strategy.
 *
 * You should include this after general api declaration
 */

// ========== Lists ==========
%template(ApplicationSettingsValueList) csp::common::List<csp::common::ApplicationSettings>;
%template(SettingsCollectionList) csp::common::List<csp::common::SettingsCollection>;
%template(StringList) csp::common::List<csp::common::String>;
%template(SpaceEntityPtrList) csp::common::List<csp::multiplayer::SpaceEntity*>;
%template(Vector3List) csp::common::List<csp::common::Vector3>;

// ========== Arrays ==========
%template(SpaceUserRoleValueArray) csp::common::Array<csp::systems::SpaceUserRole>;
%template(FeatureFlagValueArray) csp::common::Array<csp::FeatureFlag>;
%template(ReplicatedValueArray) csp::common::Array<csp::common::ReplicatedValue>;
%template(StringArray) csp::common::Array<csp::common::String>;

%template(UserRoleInfoArray) csp::common::Array<csp::systems::UserRoleInfo>;
%template(InviteUserRoleInfoArray) csp::common::Array<csp::systems::InviteUserRoleInfo>;

%template(NetworkEventRegistrationArray) csp::common::Array<csp::multiplayer::NetworkEventRegistration>;
%template(ComponentUpdateInfoArray) csp::common::Array<csp::multiplayer::ComponentUpdateInfo>;
%template(MessageInfoArray) csp::common::Array<csp::multiplayer::MessageInfo>;

// ========== Maps ==========
%template(StringDict) csp::common::Map<csp::common::String, csp::common::String>;
%template(StringReplicatedValueDict) csp::common::Map<csp::common::String, csp::common::ReplicatedValue>;
%template(UInt32ReplicatedValueDict) csp::common::Map<uint32_t, csp::common::ReplicatedValue>;
%template(UInt16ComponentBasePtrDict) csp::common::Map<uint16_t, csp::multiplayer::ComponentBase*>;
