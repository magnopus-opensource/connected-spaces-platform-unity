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
%template(ApplicationSettingsValueList) csp::common::List<csp::common::ApplicationSettings>;
%template(SpaceUserRoleValueArray) csp::common::Array<csp::systems::SpaceUserRole>;
%template(FeatureFlagValueArray) csp::common::Array<csp::FeatureFlag>;
%template(StringDict) csp::common::Map<csp::common::String, csp::common::String>;
%template(ReplicatedValueArray) csp::common::Array<csp::common::ReplicatedValue>;
%template(SettingsCollectionList) csp::common::List<csp::common::SettingsCollection>;
%template(StringArray) csp::common::Array<csp::common::String>;
%template(StringReplicatedValueDict) csp::common::Map<csp::common::String, csp::common::ReplicatedValue>;