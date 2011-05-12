# Run a "simple" build using GHC directly 
husk: hs-src/shell.hs hs-src/Language/Scheme/Core.hs hs-src/Language/Scheme/Macro.hs hs-src/Language/Scheme/Numerical.hs hs-src/Language/Scheme/Parser.hs hs-src/Language/Scheme/Types.hs hs-src/Language/Scheme/Variables.hs
	ghc -Wall --make -package parsec -fglasgow-exts -o huski hs-src/shell.hs hs-src/Language/Scheme/Core.hs hs-src/Language/Scheme/Macro.hs hs-src/Language/Scheme/Numerical.hs hs-src/Language/Scheme/Parser.hs hs-src/Language/Scheme/Types.hs hs-src/Language/Scheme/Variables.hs Paths_husk_scheme.hs

plugin-test:
	ghc -c hs-src/ffi-test.hs

# Create files for distribution
dist:
	runhaskell Setup.hs configure --prefix=$(HOME) --user && runhaskell Setup.hs build && runhaskell Setup.hs install && runhaskell Setup.hs sdist

# Create API documentation
doc:
	runhaskell Setup.hs haddock 

# Run all unit tests
test: husk stdlib.scm
	@echo "0" > scm-unit-tests/scm-unit.tmp
	@echo "0" >> scm-unit-tests/scm-unit.tmp
	@cd scm-unit-tests ; ../huski t-backquote.scm
	@cd scm-unit-tests ; ../huski t-case.scm
	@cd scm-unit-tests ; ../huski t-closure.scm
	@cd scm-unit-tests ; ../huski t-cond.scm
	@cd scm-unit-tests ; ../huski t-cont.scm
	@cd scm-unit-tests ; ../huski t-delay.scm
	@cd scm-unit-tests ; ../huski t-eval.scm
	@cd scm-unit-tests ; ../huski t-exec.scm
	@cd scm-unit-tests ; ../huski t-iteration.scm
	@cd scm-unit-tests ; ../huski t-macro.scm
	@cd scm-unit-tests ; ../huski t-numerical-ops.scm
	@cd scm-unit-tests ; ../huski t-hashtable.scm
	@cd scm-unit-tests ; ../huski t-special-forms.scm
	@cd scm-unit-tests ; ../huski t-standard-procedures.scm
	@cd scm-unit-tests ; ../huski t-stdlib.scm
	@cd scm-unit-tests ; ../huski t-string.scm
	@cd scm-unit-tests ; ../huski t-vector.scm
	@cd scm-unit-tests ; ../huski summarize.scm
	@rm -f scm-unit-tests/scm-unit.tmp

# Delete all temporary files generated by a build
clean:
	rm -f *.o
	rm -f hs-src/*.o
	rm -f hs-src/Language/*.o
	rm -f hs-src/Language/Scheme/*.o
	rm -f *.hi
	rm -f hs-src/*.hi
	rm -f hs-src/Language/*.hi
	rm -f hs-src/Language/Scheme/*.hi
	rm -f huski
	rm -rf dist
