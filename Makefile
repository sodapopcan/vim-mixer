# Test and dist helpers

test:
	cd test && vim -Nu vimrc -S test.vim && echo 'Success!' || echo 'Failure!'

.PHONY: test
