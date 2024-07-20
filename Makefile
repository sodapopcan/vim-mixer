# Test and dist helpers

t?=t
test:
	prove-vspec -d $(PWD) $(t)

debug:
	DEBUG=1 prove-vspec -d $(PWD) $(t)

.PHONY: test debug
