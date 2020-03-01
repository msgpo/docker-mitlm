all: download/mitlm-0.4.2-long.tar.gz
	bash build-with-docker.sh

download/mitlm-0.4.2-long.tar.gz:
	mkdir -p download
	wget -O "$@" 'https://github.com/rhasspy/mitlm/archive/v0.4.2.tar.gz'
