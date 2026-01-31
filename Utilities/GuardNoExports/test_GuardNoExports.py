from pathlib import Path
import subprocess
import filecmp
import pytest

# A test that just diffs two directories
# The data here is just taken from some CSP files that I happened to have lying around
# It's not overly targeted, just for a smattering of confidence.
def test_directory_diff():
    input_dir = Path("./TestDataInput/")
    expected_dir = Path("./TestDataExpected/")
    output_dir = Path("./TestOutput/")
    
    # Run your script across the test data 
    subprocess.run(
        ["python", "./GuardNoExports.py", str(input_dir), str(output_dir)],
        check=True,
    )

    dcmp = filecmp.dircmp(output_dir, expected_dir)

    def recurse_diff(dcmp):
        diffs = []
        if dcmp.left_only or dcmp.right_only or dcmp.diff_files:
            diffs.append({
                "left": str(dcmp.left),
                "right": str(dcmp.right),
                "left_only": dcmp.left_only,
                "right_only": dcmp.right_only,
                "diff_files": dcmp.diff_files,
            })
        for sub in dcmp.subdirs.values():
            diffs.extend(recurse_diff(sub))
        return diffs

    differences = recurse_diff(dcmp)
    if differences:
        pytest.fail(f"Directory trees differ:\n{differences}")