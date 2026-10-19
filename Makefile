CORE := $(if $(OPENSCAD_CORE_PATH),$(OPENSCAD_CORE_PATH),$(CURDIR)/work/openscad-core)
.PHONY: ci test build lint
build:
	./script/build_and_run.sh --build-only
	./script/swift.sh build --product OpenSCADEditor

test:
	python3 -m unittest discover -s script/tests
	OPENSCAD_TEST_WORKER="$(CORE)/build-native/openscad-preview-worker" ./script/swift.sh test --enable-code-coverage
	python3 "$(CORE)/native/tests/test_preview.py" "$(CORE)/build-native/openscad-preview-worker"

lint:
	for script in script/*.sh; do bash -n "$$script"; done
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift

ci: build test lint
	./script/check_linkage.sh
