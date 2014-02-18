all: fattable.min.js fattable.js fattable.css example.js

closure/compiler.jar:
	rm -fr closure
	mkdir closure
	cd closure && wget http://dl.google.com/closure-compiler/compiler-latest.zip && unzip compiler-latest.zip

%.js: src/%.coffee
	coffee  -o . -c $^

%.css: src/%.less
	lessc $^ > $@

fattable.min.js: fattable.js closure/compiler.jar
	java -jar closure/compiler.jar --js fattable.js --js_output_file fattable.min.js --compilation_level ADVANCED_OPTIMIZATIONS
