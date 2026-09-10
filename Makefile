# One binary, one test runner, boot libraries only.
#
#   make            -> bin/ideonomy
#   make test       -> build and run the offline suite
#   make check      -> typecheck everything without generating code

GHC   ?= ghc
EXTS   = -XDuplicateRecordFields -XOverloadedRecordDot -XLambdaCase -XMultiWayIf
FLAGS  = -O0 -Wall -Wno-name-shadowing -Wno-unused-do-bind -threaded $(EXTS) -isrc -outputdir build
SRC    = $(shell find src app test -name '*.hs')

bin/ideonomy: $(SRC)
	@mkdir -p bin build
	$(GHC) $(FLAGS) --make app/Main.hs -o $@

build/test: $(SRC)
	@mkdir -p build
	$(GHC) $(FLAGS) -itest --make test/Main.hs -o $@

.PHONY: test check clean
test: build/test
	IDEONOMY_DATA=data build/test

check:
	$(GHC) $(FLAGS) -fno-code --make app/Main.hs
	$(GHC) $(FLAGS) -itest -fno-code --make test/Main.hs

clean:
	rm -rf build bin
