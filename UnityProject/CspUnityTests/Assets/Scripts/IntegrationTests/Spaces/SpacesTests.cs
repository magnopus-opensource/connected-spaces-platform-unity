// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using csp.common;
using csp.systems;
using Magnopus.Foundation.Unity.Tests.Integration;
using Magnopus.Foundation.Unity.Tests.Integration.Extensions;
using NUnit.Framework;
using SpaceInfo = csp.systems.Space;

namespace IntegrationTests.Spaces
{
    public class SpacesTests : FoundationFixture
    {
        private SpaceSystem spacesService;
        private IRealtimeEngine currentlyUsedRealtimeEngine;

        #region TestHelpers

        private const string SpaceSiteKey = "site";
        private const string SpaceMultiplayerVersionKey = "multiplayerVersion";
        private const string DefaultSpaceSite = "Void";
        public const string OwnedSpaceName = "IntegrationTestSpaceOwned";
        private const int MultiplayerVersion = 2;

        public static string[] defaultTags = { "test" };

        public static Dictionary<string, string> defaultSpaceMetadata = new Dictionary<string, string>
        {
            { SpaceSiteKey, DefaultSpaceSite },
            { SpaceMultiplayerVersionKey, MultiplayerVersion.ToString() }
        };

        /// <summary>
        /// Create a new space to be used for self-managed testing, with the currently logged-in user.
        /// The space uses a randomly generated name from the specified base name.
        /// </summary>
        /// <param name="spacesService">A valid space service api to use to create the new space.</param>
        /// <param name="baseName">Base name to use for the randomly generated space name.</param>
        /// <param name="spaceMetadata">Metadata to use for the space.</param>
        /// <param name="tags">Tags to use when creating the space.</param>
        /// <param name="attributes">Attributes for the new space</param>
        /// <returns>The space info of the newly created space.</returns>
        public static async Task<SpaceInfo> CreateNewSpace(SpaceSystem spacesService, string baseName, 
            Dictionary<string, string> spaceMetadata, string[] tags, SpaceAttributes attributes)
        {
            if (spacesService == null)
            {
                Assert.Fail($"{nameof(CreateNewSpace)} failed: {nameof(spacesService)} is null!");
            }
            string randomSpaceName = baseName + Guid.NewGuid().ToString().Substring(0, 5);
            
            // Note: could be improved via swig extend
            var spaceMetadataDict = new StringDict();
            foreach (var kv in spaceMetadata)
            {
                spaceMetadataDict[kv.Key] = kv.Value;
            }
            
            var generatedNotOwnedSpaceResult = await TestHelper.WrapEndpoint(() =>
                spacesService.CreateSpaceAsync(randomSpaceName, string.Empty,
                    SpaceAttributes.Public, null, spaceMetadataDict, 
                    null, new StringArray(tags)));
            Assert.AreEqual((ushort)HttpStatusCode.OK, generatedNotOwnedSpaceResult.ReturnCode);
            Assert.IsNotNull(generatedNotOwnedSpaceResult.ReturnData);
            return generatedNotOwnedSpaceResult.ReturnData.GetSpace();
        }
        #endregion
    }
}