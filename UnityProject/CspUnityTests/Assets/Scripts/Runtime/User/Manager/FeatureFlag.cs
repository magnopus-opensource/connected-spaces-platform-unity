// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using csp;

namespace Magnopus.Foundation.Unity.Runtime.User.Manager
{
    /// <summary>
    /// Data object for CSP Feature Flag
    /// </summary>
    public struct FeatureFlag
    {
        private EFeatureFlag Type { get; set; }
        
        private bool Enabled { get; set; }
        
        /// <summary>
        /// Public constructor to allow consumers to create FeatureFlag instances
        /// </summary>
        public FeatureFlag(EFeatureFlag type, bool enabled)
        {
            Type = type;
            Enabled = enabled;
        }
        
        internal FeatureFlag(FeatureFlag featureFlag)
        {
            Type = featureFlag.Type;
            Enabled = featureFlag.Enabled;
        }
        
        /// <summary>
        /// Helper function for converting an array of CSP feature flags to an array of Unity feature flags
        /// </summary>
        internal static FeatureFlag ConvertUnityFeatureFlag(FeatureFlag value)
        {
            return new FeatureFlag(value.Type, value.Enabled);
        }
    }
}