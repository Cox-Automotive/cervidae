SHELL := /bin/bash
LC=$(shell /usr/bin/wc -l cervidae.sh | /usr/bin/awk '{print $$1}')
DONTTOUCH=15

all: noop

noop:
	@echo "The default is a no-op function. Pick one: "
	@echo "  * funcs: copy the cervidae functions into it's own _funcs file for testing"
	@echo "  * test: runs the full test suite (run 'make funcs' before running this)"
	@echo "  * clean: cleans up installation (leaves packages directory)"

funcs: cervidae.sh
	@echo Moving $(LC) lines
	@HC=$$(( $(LC) - $(DONTTOUCH) )); head -$$HC cervidae.sh > cervidae_funcs.sh

backup: cervidae.sh Makefile tests
	rm -rf tests/__pycache__
	rm -rf tests/*.pyc
	cp -R {cervidae.sh,Makefile,tests} /vagrant/cervidae/

test: tests
	@./bin/python -m unittest discover -s tests

clean:
	rm cervidae_funcs.sh
	rm -rf bin
	rm -rf etc
	rm -rf Gemfile*
	rm -rf include
	rm -rf lib
	rm -rf logs
	rm -rf node
	rm -rf share
	rm -rf src
	rm -rf tmp
	rm -rf var
	rm -rf vendor
