NAME = kenntwasde/raspi_baseimage-docker
#DEBIAN_VER = jessie
DEBIAN_VER = wheezy
VERSION = $(DEBIAN_VER)_0.9.17
IMAGE = image.$(DEBIAN_VER)

.PHONY: all build test tag_latest release ssh

all: build

build:
	docker build -t $(NAME):$(VERSION) --rm --no-cache $(IMAGE)

test:
	env NAME=$(NAME) VERSION=$(VERSION) IMAGE=$(IMAGE) ./test/runner.sh

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rpi-$(VERSION) && git push origin rpi-$(VERSION)"

ssh:
	chmod 600 $(IMAGE)/insecure_key
	@ID=$$(docker ps | grep -F "$(NAME):$(VERSION)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		IP=$$(docker inspect $$ID | grep IPAddr | sed 's/.*: "//; s/".*//') && \
		echo "SSHing into $$IP" && \
		ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(IMAGE)/insecure_key root@$$IP
