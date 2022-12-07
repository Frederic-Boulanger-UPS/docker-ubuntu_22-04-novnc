.PHONY: build manifest buildfat check run debug push save clean clobber

# Default values for variables
REPO  ?= fredblgr/
NAME  ?= ubuntu-novnc
TAG   ?= 22.04
ARCH  := $$(arch=$$(uname -m); if [[ $$arch == "x86_64" ]]; then echo amd64; else echo $$arch; fi)
RESOL   = 1440x900
ARCHS = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)

# These files will be generated from teh Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

# Rebuild the container image and remove intermediary images
build: $(templates)
	docker build --tag $(REPO)$(NAME):$(TAG)-$(ARCH) .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

from-scratch: $(templates)
	docker build --no-cache --pull --tag $(REPO)$(NAME):$(TAG)-$(ARCH) .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

# yarnpkg_pubkey.gpg :
# 	wget --output-document=yarnpkg_pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg

# Safe way to build multiarchitecture images:
# - build each image on the matching hardware, with the -$(ARCH) tag
# - push the architecture specific images to Dockerhub
# - build a manifest list referencing those images
# - push the manifest list so that the multiarchitecture image exist
manifest:
	docker manifest create $(REPO)$(NAME):$(TAG) $(IMAGES)
	@for arch in $(ARCHS); \
	 do \
	   echo docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	   docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	 done
	docker manifest push $(REPO)$(NAME):$(TAG)

rmmanifest:
	docker manifest rm $(REPO)$(NAME):$(TAG)

# Test run the container
#  the local dir will be mounted under /src
check:
	echo "http://localhost:6080"
	docker run --rm \
		--publish 6080:80 \
		--volume ${PWD}:/workspace:rw \
		--env USER=student --env PASSWORD=CS3ASL \
		--env "RESOLUTION=$(RESOL)" \
		--name $(NAME)-test \
		$(REPO)$(NAME):$(TAG)-$(ARCH)

run:
	echo "http://localhost:6080"
	docker run --rm --detach \
		--publish 6080:80 \
		--volume "${PWD}":/workspace:rw \
		--env USERNAME=`id -n -u` --env USERID=`id -u` \
		--name $(NAME)-test \
		$(REPO)$(NAME):$(TAG)-$(ARCH)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

#		--env "RESOLUTION=$(RESOL)" \

runasroot:
	echo "http://localhost:6080"
	docker run --rm --detach \
		--publish 6080:80 \
		--volume "${PWD}":/workspace:rw \
		--env "RESOLUTION=$(RESOL)" \
		--name $(NAME)-test \
		$(REPO)$(NAME):$(TAG)-$(ARCH)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

debug:
	echo "http://localhost:6080"
	docker run --rm --tty --interactive \
		--publish 6080:80 \
		--volume "${PWD}":/workspace:rw \
		--env USERNAME=`id -n -u` --env USERID=`id -u` \
		--env "RESOLUTION=$(RESOL)" \
		--name $(NAME)-test \
		--entrypoint "bash" \
		$(REPO)$(NAME):$(TAG)-$(ARCH)
# Add option -e HTTP_PASSWORD=CS3ASL to control the access to the web page.
#  -p 6081:443

push:
	docker push $(REPO)$(NAME):$(TAG)-$(ARCH)

save:
	docker save $(REPO)$(NAME):$(TAG)-$(ARCH) | gzip > $(NAME)-$(TAG)-$(ARCH).tar.gz

clean:
	docker image prune -f

clobber:
	docker rmi $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$(ARCH)
	docker builder prune --all
