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

/* Use a macro for this because we want all these interop types to have a pin slot,
 * same as everything else. */
%define DEFINE_TEMPLATE(CSHARP_CONTAINER_NAME, FULLY_NAMESPACED_CLASST)
    %template(CSHARP_CONTAINER_NAME) FULLY_NAMESPACED_CLASST;
    ADD_OUTER_OBJECT_PIN_SLOT(%arg(FULLY_NAMESPACED_CLASST))
%enddef

// ========== Lists ==========
DEFINE_TEMPLATE(ApplicationSettingsList, csp::common::List<csp::common::ApplicationSettings>)
DEFINE_TEMPLATE(SettingsCollectionList, csp::common::List<csp::common::SettingsCollection>)
DEFINE_TEMPLATE(StringList, csp::common::List<csp::common::String>)
DEFINE_TEMPLATE(SpaceEntityPtrList, csp::common::List<csp::multiplayer::SpaceEntity*>)
DEFINE_TEMPLATE(Vector3List, csp::common::List<csp::common::Vector3>)

// ========== Arrays ==========
DEFINE_TEMPLATE(SpaceUserRoleArray, csp::common::Array<csp::systems::SpaceUserRole>)
DEFINE_TEMPLATE(FeatureFlagArray, csp::common::Array<csp::FeatureFlag>)
DEFINE_TEMPLATE(ReplicatedValueArray, csp::common::Array<csp::common::ReplicatedValue>)
DEFINE_TEMPLATE(StringArray, csp::common::Array<csp::common::String>)
DEFINE_TEMPLATE(UserRoleInfoArray, csp::common::Array<csp::systems::UserRoleInfo>)
DEFINE_TEMPLATE(InviteUserRoleInfoArray, csp::common::Array<csp::systems::InviteUserRoleInfo>)
DEFINE_TEMPLATE(NetworkEventRegistrationArray, csp::common::Array<csp::multiplayer::NetworkEventRegistration>)
DEFINE_TEMPLATE(ComponentUpdateInfoArray, csp::common::Array<csp::multiplayer::ComponentUpdateInfo>)
DEFINE_TEMPLATE(MessageInfoArray, csp::common::Array<csp::multiplayer::MessageInfo>)
DEFINE_TEMPLATE(MaintenanceInfoArray, csp::common::Array<csp::systems::MaintenanceInfo>)
DEFINE_TEMPLATE(AnchorArray, csp::common::Array<csp::systems::Anchor>)
DEFINE_TEMPLATE(AnchorResolutionArray, csp::common::Array<csp::systems::AnchorResolution>)
DEFINE_TEMPLATE(AssetArray, csp::common::Array<csp::systems::Asset>)
DEFINE_TEMPLATE(AssetCollectionArray, csp::common::Array<csp::systems::AssetCollection>)
DEFINE_TEMPLATE(BasicProfileArray, csp::common::Array<csp::systems::BasicProfile>)
DEFINE_TEMPLATE(BasicSpaceArray, csp::common::Array<csp::systems::BasicSpace>)
DEFINE_TEMPLATE(CartLineArray, csp::common::Array<csp::systems::CartLine>)
DEFINE_TEMPLATE(EAssetPlatformArray, csp::common::Array<csp::systems::EAssetPlatform>)
DEFINE_TEMPLATE(EThirdPartyAuthenticationProvidersArray, csp::common::Array<csp::systems::EThirdPartyAuthenticationProviders>)
DEFINE_TEMPLATE(FeatureLimitInfoArray, csp::common::Array<csp::systems::FeatureLimitInfo>)
DEFINE_TEMPLATE(FeatureQuotaInfoArray, csp::common::Array<csp::systems::FeatureQuotaInfo>)
DEFINE_TEMPLATE(GeoLocationArray, csp::common::Array<csp::systems::GeoLocation>)
DEFINE_TEMPLATE(HotspotGroupArray, csp::common::Array<csp::systems::HotspotGroup>)
DEFINE_TEMPLATE(LODAssetArray, csp::common::Array<csp::systems::LODAsset>)
DEFINE_TEMPLATE(MaterialPtrArray, csp::common::Array<csp::systems::Material*>)
DEFINE_TEMPLATE(PointOfInterestArray, csp::common::Array<csp::systems::PointOfInterest>)
DEFINE_TEMPLATE(ProductInfoArray, csp::common::Array<csp::systems::ProductInfo>)
DEFINE_TEMPLATE(ProductMediaInfoArray, csp::common::Array<csp::systems::ProductMediaInfo>)
DEFINE_TEMPLATE(ProductVariantInfoArray, csp::common::Array<csp::systems::ProductVariantInfo>)
DEFINE_TEMPLATE(SequenceArray, csp::common::Array<csp::systems::Sequence>)
DEFINE_TEMPLATE(ServiceStatusArray, csp::common::Array<csp::systems::ServiceStatus>)
DEFINE_TEMPLATE(ShopifyStoreInfoArray, csp::common::Array<csp::systems::ShopifyStoreInfo>)
DEFINE_TEMPLATE(SiteArray, csp::common::Array<csp::systems::Site>)
DEFINE_TEMPLATE(SpaceArray, csp::common::Array<csp::systems::Space>)
DEFINE_TEMPLATE(TicketedEventArray, csp::common::Array<csp::systems::TicketedEvent>)
DEFINE_TEMPLATE(TierFeaturesArray, csp::common::Array<csp::systems::TierFeatures>)
DEFINE_TEMPLATE(VariantOptionInfoArray, csp::common::Array<csp::systems::VariantOptionInfo>)
DEFINE_TEMPLATE(VersionMetadataArray, csp::common::Array<csp::systems::VersionMetadata>)
DEFINE_TEMPLATE(EAssetTypeArray, csp::common::Array<csp::systems::EAssetType>)
DEFINE_TEMPLATE(EAssetCollectionTypeArray, csp::common::Array<csp::systems::EAssetCollectionType>)
// Not exposed yet due to linking issue in CSP 6.44.0 for Windows
//DEFINE_TEMPLATE(ComponentPropertyTypeArray, csp::common::Array<csp::multiplayer::ComponentProperty>)
//DEFINE_TEMPLATE(ComponentSchemaTypeArray, csp::common::Array<csp::multiplayer::ComponentSchema>)

// ========== Maps ==========
DEFINE_TEMPLATE(StringDict, %arg(csp::common::Map<csp::common::String, csp::common::String>))
DEFINE_TEMPLATE(StringReplicatedValueDict, %arg(csp::common::Map<csp::common::String, csp::common::ReplicatedValue>))
DEFINE_TEMPLATE(UInt32ReplicatedValueDict, %arg(csp::common::Map<uint32_t, csp::common::ReplicatedValue>))
DEFINE_TEMPLATE(UInt16ComponentBasePtrDict, %arg(csp::common::Map<uint16_t, csp::multiplayer::ComponentBase*>))
DEFINE_TEMPLATE(StringAssetDict, %arg(csp::common::Map<csp::common::String, csp::systems::Asset>))
DEFINE_TEMPLATE(StringStringArrayDict, %arg(csp::common::Map<csp::common::String, csp::common::Array<csp::common::String>>))
DEFINE_TEMPLATE(StringStringDictDict, %arg(csp::common::Map<csp::common::String, csp::common::Map<csp::common::String, csp::common::String>>))
