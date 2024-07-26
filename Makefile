###################################################################
################### Things for the alpine image ###################
###################################################################

IMAGE_NAME := kkeekk/cosign
WORK_DIR := -v $(shell pwd):/host -w /host
UID := $(shell id -u)
GID := $(shell id -g)
USER := $(UID):$(GID)
DOCKER_GROUP := $(shell getent group docker | cut -d: -f3)
DOCKER_SOCK := -v "/var/run/docker.sock:/var/run/docker.sock"

# Build the alpine image, used as a sandbox
# Exec into alpine container, with docker capabilities
alpine:
	docker build -t $(IMAGE_NAME) \
	-f Containerfile.alpine \
	--build-arg UID=$(UID) \
	--build-arg GID=$(GID) \
	--build-arg DOCKER_GROUP=$(DOCKER_GROUP) \
	. && \
	docker run --rm -it $(DOCKER_SOCK) $(WORK_DIR) $(IMAGE_NAME)	

###################################################################
############## To be ran inside the alpine container ##############
###################################################################

# Source image to copy for dummy image
SRC_IMAGE_NAME := lscr.io/linuxserver/swag
SRC_IMAGE_TAG := latest
SRC_IMAGE := $(SRC_IMAGE_NAME):$(SRC_IMAGE_TAG)

# Name for dummy image, using generated uuid
DUMMY_NAME := $(shell if [ ! -f uuid.txt ]; then uuidgen > uuid.txt; fi; cat uuid.txt)
DUMMY_TAG := 1hr

# Final dummy image name
DUMMY := ttl.sh/$(DUMMY_NAME):$(DUMMY_TAG)

# Cleanup stuff, technically could be ran outside the container as well
clean:
	rm -rf cosign.* uuid.txt

# Generate cosign keypair
--cosign.key:
	cosign generate-key-pair

# Push dummy image
push:
	cosign copy $(SRC_IMAGE) $(DUMMY) && echo "Pushed image: $(DUMMY)"

# Sign dummy image
sign: --cosign.key push
	cosign sign -y --key cosign.key $(shell cosign triangulate --type=digest $(DUMMY))

# Add annotations to image
annotate: cosign.key push
	cosign sign -y --key cosign.key -a name=$(DUMMY_NAME) -a tag=$(DUMMY_TAG) -a date=$(shell date -u -Iseconds) $(shell cosign triangulate --type=digest $(DUMMY))

# Verify dummy image
verify:
	cosign verify --key cosign.pub $(DUMMY)

# Verify annotation on dummy image
verify_annotate:
	cosign verify --key cosign.pub -a name=$(DUMMY_NAME) $(DUMMY)