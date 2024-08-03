# Test and dist helpers

test:
	cd test && vim -Nu vimrc -S test.vim && echo 'Success!' || cat fails

testn:
	cd test && nvim -Nu vimrc -S test.vim && echo 'Success!' || cat fails

.PHONY: test
