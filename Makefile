.PHONY: test

MOCHA = ./node_modules/.bin/mocha

test-coverage:
	$(MOCHA) -R html-cov test > coverage.html

test-coveralls:
	$(MOCHA) test --reporter mocha-lcov-reporter | ./node_modules/coveralls/bin/coveralls.js
