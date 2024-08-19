# Test and dist helpers

test:
	@cd test && vim --clean -Nu vimrc -S test.vim && echo 'Success!' || cat fails

testn:
	@cd test && nvim --clean -Nu vimrc -S test.vim && echo 'Success!' || cat fails

.PHONY: test testn
