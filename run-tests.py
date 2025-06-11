#!/usr/bin/env python3

# pylint: disable=line-too-long, broad-except, too-many-nested-blocks, too-many-branches, duplicate-code, too-many-locals
"""
Run helm chart tests
"""
import argparse
import difflib
import glob
import os
import re
import sys
import subprocess
import yaml

def findfiles(path, pattern):
    """Function find files."""
    current = os.getcwd()
    os.chdir(path)
    result = glob.glob(pattern, recursive=True)
    os.chdir(current)
    return result

def cmd(command):
    """Function to call shell command."""
    process = subprocess.run([command],capture_output=True,shell=True)
    return process.stdout, process.stderr

def run_test(chart, test):
    """Function to run a single test."""
    chart_path = f"charts/{chart}"
    values_file = f"tests/{chart}/{test}.values.yaml"
    result_file = f"tests/{chart}/{test}.result.yaml"
    result = True
    output = ""
    with open(result_file, "r", encoding="utf-8") as stream:
        try:
            result_loaded = stream.readlines()
        except OSError as exc:
            output = f"Error loading result file {result_file}: {exc}"
            result = False
            return (result, output)

    command = f"helm template -f {values_file} {chart_path}"
    out, err = cmd(command)
    if not(err):
      output_template = out.decode('utf-8')
    else:
      output = f"Error running command {command}: {err.decode('utf-8')}"
      result = False
      return (result, output)

    diff = difflib.unified_diff(
        result_loaded,
        output_template.splitlines(keepends=True),
        fromfile=result_file,
        tofile="helm output",
        lineterm='',
    )

    output_diff = ''.join(diff)
    if output_diff != "":
        output = f"{output_diff}"
        result = False
    return (result, output)

def main():
    """Function main."""
    description = "Run helm chart tests"
    parser = argparse.ArgumentParser(description=description, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument(
        "--charts",
        dest="charts",
        required=False,
        help="List of helm charts to test",
    )
    parser.add_argument(
        "--tests",
        dest="tests",
        required=False,
        help="List of tests to run",
    )
    args = parser.parse_args()

    if args.charts:
      charts = args.charts.split(",")
    else:
      charts = ["all"]
    if args.tests:
      tests = args.tests.split(",")
    else:
      tests = ["all"]

    all_defined_tests = findfiles("tests", "**/*.values.yaml")
    print("Found test files:", all_defined_tests)
    final_exit= 0

    for test_to_run in all_defined_tests:
        chart_to_test = test_to_run.split("/")[0].strip()
        test_name = os.path.basename(test_to_run).replace(".yaml", "").replace(".values", "").replace(".result", "").strip()

        if not(chart_to_test in charts) and charts != ["all"]:
            print(f"Skipping chart [{chart_to_test}] as it is not in the specified charts...")
            continue
        if not(test_name in tests) and tests != ["all"]:
            print(f"Skipping test [{test_name}] for chart [{chart_to_test}] it is not in the specified tests...")
            continue
        print(f"Running test [{test_name}] for chart [{chart_to_test}]...", end='')
        result_test, error_test = run_test(chart_to_test, test_name)
        if result_test:
            print("passed")
        else:
            print("failed")
            print(f"Error: \n{error_test}")
            final_exit = 1

    print("...done")
    sys.exit(final_exit)
if __name__ == "__main__":
    main()
