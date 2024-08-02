# Test and dist helpers

test:
	cd test && vim -Nu vimrc -S test.vim && echo 'Success!' || echo 'Fail!'

testn:
	cd test && nvim -Nu vimrc -S test.vim && echo 'Success!' || echo 'Fail!'

.PHONY: test
