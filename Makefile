
REPORTER = nyan
INTEGRATIONAL_TESTS = $(shell find tests/integrational -name "*.coffee")
UNIT_TESTS = $(shell find tests/unit -name "*.coffee")

test: test-integrational test-unit

test-integrational:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--timeout 10000 \
		$(INTEGRATIONAL_TESTS)

test-unit:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--timeout 10000 \
		$(UNIT_TESTS)

test-w:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd -b \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--watch \
		--growl \
		$(INTEGRATIONAL_TESTS)

test-one:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd -b \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--timeout 3000 \
		$f

test-one-w:
	@NODE_ENV=test ./node_modules/.bin/mocha -u bdd -b \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script/register \
		--watch \
		--growl \
		$f

.PHONY: test-integrational test-w test-unit test-one