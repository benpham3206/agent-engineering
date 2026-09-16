CONFIG ?= project.conf

.PHONY: validate generate test verify clean-dist

validate:
	bash tooling/validate-config.sh "$(CONFIG)"

generate:
	bash tooling/generate.sh "$(CONFIG)"

test:
	bash tests/generation/test-generate.sh

verify:
	bash tooling/verify-self.sh

clean-dist:
	rm -rf dist
