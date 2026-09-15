CONFIG ?= project.conf

.PHONY: validate generate test verify clean-dist

validate:
	bash tooling/validate-config.sh "$(CONFIG)"

generate:
	bash tooling/generate.sh "$(CONFIG)"

test:
	bash tests/generation/test-generate.sh

verify: test
	bash -n tooling/lib.sh tooling/validate-config.sh tooling/generate.sh tests/generation/test-generate.sh
	git diff --check

clean-dist:
	rm -rf dist
