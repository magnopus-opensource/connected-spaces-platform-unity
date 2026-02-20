// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Runtime.GeographicLocation.Schema;
using Magnopus.Foundation.Unity.Runtime.User.Exceptions;
using Magnopus.Foundation.Unity.Runtime.User.Extensions;
using UnityEngine;
using FoundationSystems = csp.systems;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Data object for Site info
    /// </summary>
    public struct Site
    {
        public string Id { get; set; }

        public string Name { get; set; }

        public string SpaceId { get; set; }
        
        public GeoLocation Location { get; set; }

        public Quaternion Rotation { get; set; }

        internal Site(FoundationSystems.Site value)
        {
            if (value == null)
            {
                throw new FoundationException($"Argument: {nameof(value)} was null. Could not create the {nameof(Site)}");
            }

            Id = value.Id;
            Name = value.Name;
            SpaceId = value.SpaceId;
            using var location = value.Location;
            Location = location.ToUnityGeoLocation();
            using var rotation = value.Rotation;
            Rotation = ((Quaternion)rotation).ToUnityRotationFromGLTF();
        }
        
        internal FoundationSystems.Site ToFoundationSite()
        {
            var site = new FoundationSystems.Site();

            site.Id = Id;
            site.Name = Name;
            site.SpaceId = SpaceId;
            site.Location = Location.ToFoundationGeoLocation();
            site.Rotation = Rotation.ToGLTFRotationFromUnity();

            return site;
        }
    }
}