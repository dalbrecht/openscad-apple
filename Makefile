.PHONY: ci test build lint
build:
	./script/build_and_run.sh --build-only

test:
	OPENSCAD_TEST_WORKER="$(CURDIR)/work/openscad-core/build-native/openscad-preview-worker" ./script/swift.sh test --enable-code-coverage
	python3 work/openscad-core/native/tests/test_preview.py work/openscad-core/build-native/openscad-preview-worker

lint:
	for script in script/*.sh; do bash -n "$$script"; done
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift

ci: build test lint
	./script/check_linkage.sh
