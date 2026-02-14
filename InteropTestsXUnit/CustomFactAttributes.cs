using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InteropTestsXUnit
{
    /* Only runs a test if a certain environment variable is set
     * Added to avoid running tests that require hitting live services by default */
    public class EnvironmentFactAttribute : FactAttribute
    {
        public EnvironmentFactAttribute(string envVar)
        {
            if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(envVar)))
                Skip = $"Skipped: environment variable '{envVar}' is not set.";
        }
    }

}
