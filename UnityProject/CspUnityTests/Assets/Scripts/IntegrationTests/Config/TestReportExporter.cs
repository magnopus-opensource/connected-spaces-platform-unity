// ---------------------------------------------
// Copyright (c) Magnopus LLC. All Rights Reserved.
// ---------------------------------------------

using Magnopus.Foundation.Unity.Tests.Integration.Config;
using NUnit.Framework.Interfaces;
using System;
using System.IO;
using System.Xml;
using UnityEngine;
using UnityEngine.TestRunner;

[assembly: TestRunCallback(typeof(TestReportExporter))]

namespace Magnopus.Foundation.Unity.Tests.Integration.Config
{
    // Based off https://docs.unity3d.com/Packages/com.unity.test-framework@1.1/manual/reference-attribute-testruncallback.html
    public class TestReportExporter : ITestRunCallback
    {
        // https://forum.unity.com/threads/generating-nunit-compatible-xml-output.769757/
        private const string NUnitVersionXmlKey = "3.5.0.0";
        private const string TestRunNodeXmlKey = "test-run";
        private const string IdXmlKey = "id";
        private const string TestCaseCountXmlKey = "testcasecount";
        private const string ResultXmlKey = "result";
        private const string TotalXmlKey = "total";
        private const string PassedXmlKey = "passed";
        private const string FailedXmlKey = "failed";
        private const string InconclusiveXmlKey = "inconclusive";
        private const string SkippedXmlKey = "skipped";
        private const string AssertsXmlKey = "asserts";
        private const string EngineVersionXmlKey = "engine-version";
        private const string ClrVersionXmlKey = "clr-version";
        private const string StartTimeXmlKey = "start-time";
        private const string EndTimeXmlKey = "end-time";
        private const string DurationXmlKey = "duration";
        private const string TimeFormatXmlKey = "u";

        public void RunStarted(ITest testsToRun)
        {

        }

        public void RunFinished(ITestResult testResults)
        {
            try
            {
                WriteResultsToFile(testResults);
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to log test results to file: {ex.Message} | Stack: {ex.StackTrace}");
            }

            if (!Application.isEditor)
            {
                // The test player won't quit on its own when it finishes (we need to quit so that TeamCity doesn't hang)
                Application.Quit(testResults.ResultState.Status == TestStatus.Passed ? 0 : 1);
            }
        }

        public void TestStarted(ITest test)
        {

        }

        public void TestFinished(ITestResult result)
        {
            if (!result.Test.IsSuite)
            {
                Debug.Log($"Result of {result.Name}: {result.ResultState.Status}");
            }
        }

        private void WriteResultsToFile(ITestResult testResults)
        {
            Debug.Log($"Tests Passed: {testResults.PassCount} | Failed: {testResults.FailCount} | Skipped: {testResults.SkipCount} | Duration: {testResults.Duration}");

            string fullPath = ConfigSettings.Environment.TestResultsFilePath;
            if (string.IsNullOrWhiteSpace(fullPath))
            {
                Debug.Log($"{nameof(ConfigSettings.Environment.TestResultsFilePath)} was null or empty. Did not write out test results.");
                return;
            }

            string directory = Path.GetDirectoryName(fullPath);

            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }

            var settings = new XmlWriterSettings()
            {
                Indent = true,
            };

            using (var writer = XmlWriter.Create(fullPath, settings))
            {
                WriteResultsToXml(testResults, writer);
            }
        }

        // https://forum.unity.com/threads/generating-nunit-compatible-xml-output.769757/
        private void WriteResultsToXml(ITestResult result, XmlWriter xmlWriter)
        {
            // XML format as specified at https://github.com/nunit/docs/wiki/Test-Result-XML-Format

            var testRunNode = new TNode(TestRunNodeXmlKey);

            testRunNode.AddAttribute(IdXmlKey, "2");
            testRunNode.AddAttribute(TestCaseCountXmlKey, (result.PassCount + result.FailCount + result.SkipCount + result.InconclusiveCount).ToString());
            testRunNode.AddAttribute(ResultXmlKey, result.ResultState.ToString());
            testRunNode.AddAttribute(TotalXmlKey, (result.PassCount + result.FailCount + result.SkipCount + result.InconclusiveCount).ToString());
            testRunNode.AddAttribute(PassedXmlKey, result.PassCount.ToString());
            testRunNode.AddAttribute(FailedXmlKey, result.FailCount.ToString());
            testRunNode.AddAttribute(InconclusiveXmlKey, result.InconclusiveCount.ToString());
            testRunNode.AddAttribute(SkippedXmlKey, result.SkipCount.ToString());
            testRunNode.AddAttribute(AssertsXmlKey, result.AssertCount.ToString());
            testRunNode.AddAttribute(EngineVersionXmlKey, NUnitVersionXmlKey);
            testRunNode.AddAttribute(ClrVersionXmlKey, Environment.Version.ToString());
            testRunNode.AddAttribute(StartTimeXmlKey, result.StartTime.ToString(TimeFormatXmlKey));
            testRunNode.AddAttribute(EndTimeXmlKey, result.EndTime.ToString(TimeFormatXmlKey));
            testRunNode.AddAttribute(DurationXmlKey, result.Duration.ToString());

            var resultNode = result.ToXml(true);
            testRunNode.ChildNodes.Add(resultNode);

            testRunNode.WriteTo(xmlWriter);
        }
    }
}