default: all

SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(SRC:src/%.ls=lib/%.js)

LS = node_modules/LiveScript
LSC = node_modules/.bin/lsc
BROWSERIFY = node_modules/.bin/browserify
MOCHA = node_modules/.bin/mocha
MOCHA2 = node_modules/.bin/_mocha
ISTANBUL = node_modules/.bin/istanbul

package.json: package.json.ls
	$(LSC) --compile package.json.ls

lib:
	mkdir -p lib/

lib/%.js: src/%.ls lib
	$(LSC) --compile --output lib "$<"

browser:
	mkdir -p browser/

browser/type-check.js: $(LIB) browser
	{ ./preroll ; $(BROWSERIFY) -r ./lib/index.js:type-check ; } > browser/type-check.js

.PHONY: build build-browser test coverage dev-install loc clean

all: build

build: $(LIB) package.json

build-browser: browser/type-check.js

test: build
	$(MOCHA) --reporter dot --ui tdd --compilers ls:$(LS)

coverage: build
	$(ISTANBUL) cover $(MOCHA2) -- --reporter dot --ui tdd --compilers ls:$(LS)

dev-install: package.json
	npm install .

loc:
	wc -l $(SRC)

clean:
	rm -f package.json
	rm -rf lib
	rm -rf browser
	rm -rf coverage
