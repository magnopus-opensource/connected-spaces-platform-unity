// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using FoundationSystem = csp.systems;

namespace Magnopus.Foundation.Unity.Runtime.GeographicLocation.Schema
{
    public static class GeoLocationExtensions
    {
        internal static FoundationSystem.GeoLocation ToFoundationGeoLocation(this GeoLocation location)
        {
            return new FoundationSystem.GeoLocation(location.Longitude, location.Latitude);
        }
            
        public static GeoLocation ToUnityGeoLocation(this FoundationSystem.GeoLocation location)
        {
            return new GeoLocation(location.Latitude, location.Longitude);
        }
    }
    
    public struct GeoLocation : IEquatable<GeoLocation>
    {
        // C# 10: Allows for default initializers for struct
        // C# 9: This member is to help consumers of the library initialize to a default, unset value
        // NaN is used to distinguish between out-of-range and uninitialized scenarios
        public static GeoLocation Undefined = new GeoLocation(double.NaN, double.NaN);
        public static bool operator ==(GeoLocation left, GeoLocation right)
        {
            return left.Equals(right);
        }
        
        public static bool operator !=(GeoLocation left, GeoLocation right)
        {
            return !left.Equals(right);
        }
        
        public double Latitude;
        public double Longitude;

        public GeoLocation(double Latitude, double Longitude)
        {
            this.Latitude = Latitude;
            this.Longitude = Longitude;
        }

        public bool Equals(GeoLocation other)
        {
            return double.Equals(other.Longitude, Longitude) && double.Equals(other.Latitude,Latitude);
        }
        
        public override bool Equals(object obj)
        {
            return obj is GeoLocation other && Equals(other);
        }

        public override int GetHashCode()
        {
            return Longitude.GetHashCode() ^ Latitude.GetHashCode();
        }
    }
}
