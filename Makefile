# Test and dist helpers

# make test             Runs the test suite
# make t/simple.vim     Runs the test "t/simple.vim"
# make dist             Creates the zip archive for distribution on vim.org
# make vimball          Creates a Vimball archive
# make clean            Removes all archives

test:
	vim-flavor test

.PHONY: test
