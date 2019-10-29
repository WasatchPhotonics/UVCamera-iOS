.PHONY: docs doc

doc: docs

docs:
	@rsync --archive --verbose --progress help/ ${USER}@mco.wasatchphotonics.com:/var/www/mco/public_html/uv/
