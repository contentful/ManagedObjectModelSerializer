.PHONY: test

test:
	set -o pipefail && xcodebuild -scheme ManagedObjectModelSerializer clean build | xcpretty -c
	set -o pipefail && xcodebuild -scheme MOMSerializer clean test | xcpretty -t
