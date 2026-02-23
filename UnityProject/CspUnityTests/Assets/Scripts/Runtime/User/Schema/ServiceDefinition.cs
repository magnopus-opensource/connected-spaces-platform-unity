// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Extra.Exceptions;
using CspServiceDefinition = csp.ServiceDefinition;

namespace Magnopus.Foundation.Unity.Runtime.User.Schema
{
    /// <summary>
    /// Data transfer object for service definition data.  This represents <see cref="CspServiceDefinition"/>
    /// </summary>
    public struct ServiceDefinition
    {
        public string URI { get; set; }
        public int Version { get; set; }
        
        internal ServiceDefinition(CspServiceDefinition serviceDefinition)
        {
            if (serviceDefinition == null)
            {
                throw new CspResultException($"Argument: {nameof(serviceDefinition)} was null. Could not create the {nameof(ServiceDefinition)}");
            }

            URI = serviceDefinition.GetURI();
            Version = serviceDefinition.GetVersion();
        }
              
        internal CspServiceDefinition ToFoundationAsset()
        {
            var serviceDefinition = new CspServiceDefinition();
            serviceDefinition.SetURI(URI);
            // Note: SetVersion is not exposed.
            return serviceDefinition;
        }
    }
}