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
%template(ApplicationSettingsList) csp::common::List<csp::common::ApplicationSettings>;
%template(SettingsCollectionList) csp::common::List<csp::common::SettingsCollection>;
%template(StringList) csp::common::List<csp::common::String>;
%template(SpaceEntityPtrList) csp::common::List<csp::multiplayer::SpaceEntity*>;
%template(Vector3List) csp::common::List<csp::common::Vector3>;

// ========== Arrays ==========
%template(SpaceUserRoleArray) csp::common::Array<csp::systems::SpaceUserRole>;
%template(FeatureFlagArray) csp::common::Array<csp::FeatureFlag>;
%template(ReplicatedValueArray) csp::common::Array<csp::common::ReplicatedValue>;
%template(StringArray) csp::common::Array<csp::common::String>;
%template(UserRoleInfoArray) csp::common::Array<csp::systems::UserRoleInfo>;
%template(InviteUserRoleInfoArray) csp::common::Array<csp::systems::InviteUserRoleInfo>;
%template(NetworkEventRegistrationArray) csp::common::Array<csp::multiplayer::NetworkEventRegistration>;
%template(ComponentUpdateInfoArray) csp::common::Array<csp::multiplayer::ComponentUpdateInfo>;
%template(MessageInfoArray) csp::common::Array<csp::multiplayer::MessageInfo>;
%template(MaintenanceInfoArray) csp::common::Array<csp::systems::MaintenanceInfo>;
%template(AnchorArray) csp::common::Array<csp::systems::Anchor>;
%template(AnchorResolutionArray) csp::common::Array<csp::systems::AnchorResolution>;
%template(AssetArray) csp::common::Array<csp::systems::Asset>;
%template(AssetCollectionArray) csp::common::Array<csp::systems::AssetCollection>;
%template(BasicProfileArray) csp::common::Array<csp::systems::BasicProfile>;
%template(BasicSpaceArray) csp::common::Array<csp::systems::BasicSpace>;
%template(CartLineArray) csp::common::Array<csp::systems::CartLine>;
%template(EAssetPlatformArray) csp::common::Array<csp::systems::EAssetPlatform>;
%template(EThirdPartyAuthenticationProvidersArray) csp::common::Array<csp::systems::EThirdPartyAuthenticationProviders>;
%template(FeatureLimitInfoArray) csp::common::Array<csp::systems::FeatureLimitInfo>;
%template(FeatureQuotaInfoArray) csp::common::Array<csp::systems::FeatureQuotaInfo>;
%template(GeoLocationArray) csp::common::Array<csp::systems::GeoLocation>;
%template(HotspotGroupArray) csp::common::Array<csp::systems::HotspotGroup>;
%template(LODAssetArray) csp::common::Array<csp::systems::LODAsset>;
%template(MaterialPtrArray) csp::common::Array<csp::systems::Material*>;
%template(PointOfInterestArray) csp::common::Array<csp::systems::PointOfInterest>;
%template(ProductInfoArray) csp::common::Array<csp::systems::ProductInfo>;
%template(ProductMediaInfoArray) csp::common::Array<csp::systems::ProductMediaInfo>;
%template(ProductVariantInfoArray) csp::common::Array<csp::systems::ProductVariantInfo>;
%template(SequenceArray) csp::common::Array<csp::systems::Sequence>;
%template(ServiceStatusArray) csp::common::Array<csp::systems::ServiceStatus>;
%template(ShopifyStoreInfoArray) csp::common::Array<csp::systems::ShopifyStoreInfo>;
%template(SiteArray) csp::common::Array<csp::systems::Site>;
%template(SpaceArray) csp::common::Array<csp::systems::Space>;
%template(TicketedEventArray) csp::common::Array<csp::systems::TicketedEvent>;
%template(TierFeaturesArray) csp::common::Array<csp::systems::TierFeatures>;
%template(VariantOptionInfoArray) csp::common::Array<csp::systems::VariantOptionInfo>;
%template(VersionMetadataArray) csp::common::Array<csp::systems::VersionMetadata>;

// ========== Maps ==========
%template(StringDict) csp::common::Map<csp::common::String, csp::common::String>;
%template(StringReplicatedValueDict) csp::common::Map<csp::common::String, csp::common::ReplicatedValue>;
%template(UInt32ReplicatedValueDict) csp::common::Map<uint32_t, csp::common::ReplicatedValue>;
%template(UInt16ComponentBasePtrDict) csp::common::Map<uint16_t, csp::multiplayer::ComponentBase*>;
%template(StringAssetDict) csp::common::Map<csp::common::String, csp::systems::Asset>;
%template(StringStringArrayDict) csp::common::Map<csp::common::String, csp::common::Array<csp::common::String>>;
%template(StringStringDictDict) csp::common::Map<csp::common::String, csp::common::Map<csp::common::String, csp::common::String>>;
