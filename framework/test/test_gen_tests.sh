#!/usr/bin/env bash
################################################################################
#
# This script runs test generation for all available generators.
#
################################################################################
# Import helper subroutines and variables, and init Defects4J
source test.include
init

################################################################################
_run_tool() {
    local tool="$1"
    printf "=%.0s" {1..80}
    printf "\nTesting: $tool\n"
    printf "=%.0s" {1..80}
    printf "\n"
    # Directory for generated test suites
    tool_dir="$TMP_DIR/$tool"
    # Generate tests for Lang-2
    pid=Lang
    bid=6
    # Test suite source and number
    suite_src="$tool"
    suite_num=1
    suite_dir="$tool_dir/$pid/$suite_src/$suite_num"

    target_classes="$BASE_DIR/framework/projects/$pid/modified_classes/$bid.src"

    for type in f b; do
        vid=${bid}$type

        # Run generator and the fix script on the generated test suite
        gen_tests.pl -g "$tool" -p $pid -v $vid -n 1 -o "$tool_dir" -b 30 -c "$target_classes" || die "run $tool (regression) on $pid-$vid"
        fix_test_suite.pl -p $pid -d "$suite_dir" || die "fix test suite"

        # Run test suite and determine bug detection
        test_bug_detection $pid "$suite_dir"

        # Run test suite and determine mutation score
        test_mutation $pid "$suite_dir"

        # Run test suite and determine code coverage
        test_coverage $pid "$suite_dir" 0

        rm -rf $tool_dir
    done
}
################################################################################
# Iterate over all supported generators and generate regression tests
for tool in $(../bin/gen_tests.pl -g help | grep \- | tr -d '-'); do
    _run_tool $tool
done

# Run Randoop and generate error-revealing tests
pid=Lang
bid=6
tool_dir="$TMP_DIR/randoop"
target_classes="$BASE_DIR/framework/projects/$pid/modified_classes/$bid.src"
gen_tests.pl -g randoop -p $pid -v ${bid}b -n 1 -o "$tool_dir" -b 30 -c "$target_classes" -E || die "run $tool (error-revealing) on $pid-$vid"
