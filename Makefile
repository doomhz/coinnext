
REPORTER = nyan
INTEGRATIONAL_TESTS = $(shell find tests/integrational -name "*.coffee")
UNIT_TESTS = $(shell find tests/unit -name "*.coffee")

test: test-integrational test-unit

test-integrational:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--timeout 30000 \
		$(INTEGRATIONAL_TESTS)

test-unit:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--timeout 30000 \
		$(UNIT_TESTS)

test-w:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd -b \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--watch \
		--growl \
		$(INTEGRATIONAL_TESTS)

.PHONY: test-integrational test-w test-unit