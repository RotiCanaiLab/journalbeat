#
# COTA Journalbeat Debian Packaging Makefile
#

# uncomment this for verbose
# V := 1 # When V is set, print commands and build progress.

#####################
#       debian      #
#####################

CWD := $(shell pwd)

.PHONY: all
all:
	$Q make build

.PHONY: clean build setup_beat

setup_beat:
	$Q make clean
	$Q make clean_hellogopher
	$Q make setup_hellogopher
	$Q make build_hellogopher

build:
	$Q make setup_beat
	$Q chmod go-w etc/journalbeat.yml

# use by dh clean
clean:
	$Q rm -f .DS_STORE
	$Q rm -rf ${CWD}/bin
	$Q rm -rf vendor/github.com/wadey
	$Q rm -rf vendor/golang.org/x/tools
	$Q rm -f vendor/manifest
	$Q make clean_hellogopher
	$Q make clean_docker

##################### ORIGINAL ##########################
#                                                       #
#   Original Makefile in upstream                       #
#   Similar commands, but just add in *_docker          #
#                                                       #
##############################3##########################


# Journalbeats Makefile
#
# This Makefile contains a collection of targets to help with docker image
# maintenance and creation. Run `make docker-build` to build the docker
# image. Run `make docker-tag` to build the image and tag the docker image
# with the current git tag. Run `make docker-push` to push all tags to docker hub.
#
# Note: This Makefile can be modified to include any future non-docker build
# tasks as well.

IMAGE_NAME := mheese/journalbeat
IMAGE_BUILD_NAME := mheese-journalbeat-build
GIT_BRANCH_NAME := $(shell git rev-parse --abbrev-ref HEAD | sed "sX/X-Xg")
GIT_TAG_NAME := $(shell git describe --tags)

TAGS := $(GIT_BRANCH_NAME) $(GIT_TAG_NAME)

ifeq ($(GIT_BRANCH_NAME),master)
  TAGS += latest
endif

TAGS := $(foreach t,$(TAGS),$(IMAGE_NAME):$(t))

#
# Clean up the project
#
clean_docker:
	$Q rm -f Dockerfile
	$Q rm -rf build
.PHONY: clean

#
# Copy the Dockerfile for the build to the main project directory
#
Dockerfile:
	$Q cp docker/dockerfile.build Dockerfile

#
# Make the build directory
#
build_docker: Dockerfile build/journalbeat

#
# Build the journalbeat go image using docker
#
build/journalbeat:
	$Q mkdir -p build
	$Q docker build -t $(IMAGE_BUILD_NAME) .
	$Q docker run --name $(IMAGE_BUILD_NAME) $(IMAGE_BUILD_NAME)
	$Q docker cp $(IMAGE_BUILD_NAME):/go/src/github.com/mheese/journalbeat/journalbeat build/journalbeat
	$Q docker rm $(IMAGE_BUILD_NAME)
	$Q docker rmi $(IMAGE_BUILD_NAME)

#
# Copy the Dockerfile for release to the build directory
#
build/Dockerfile:
	$Q cp docker/dockerfile.release build/Dockerfile

#
# Copy the default journalbeat.yml for release to the build directory
#
build/journalbeat.yml:
	$Q cp docker/journalbeat.yml build/journalbeat.yml

#
# docker tag the image
#
docker-tag: docker-build
	$Q echo $(TAGS) | xargs -n 1 docker tag $(IMAGE_NAME)
.PHONY: docker-tag

#
# docker build the image
#
docker-build: build build/Dockerfile build/journalbeat.yml
	$Q cd build && docker build -t $(IMAGE_NAME) .
.PHONY: docker-build

#
# docker push all tags
#
docker-push: docker-tag
	$Q echo $(TAGS) | xargs -n 1 docker push
.PHONY: docker-push

#
#  show the current version and branch name, for quick reference.
#
version:
	@echo Version: $(GIT_TAG_NAME)
	@echo Branch: $(GIT_BRANCH_NAME)
.PHONY: version


##################### INTERNAL ##########################
#                                                       #
#   Don't change whatever below                         #
#   unless you know what you are doing                  #
#                                                       #
##############################3##########################

# The import path is where your repository can be found.
# To import subpackages, always prepend the full import path.
# If you change this, run `make clean_hellogopher`. Read more: https://git.io/vM7zV
IMPORT_PATH := github.com/mheese/journalbeat

# V := 1 # When V is set, print commands and build_hellogopher progress.

# Space separated patterns of packages to skip in list, test, format.
IGNORED_PACKAGES := /vendor/

.PHONY: build_hellogopher
build_hellogopher: .GOPATH/.ok
	$Q go install $(if $V,-v) $(VERSION_FLAGS) $(IMPORT_PATH)

### Code not in the repository root? Another binary? Add to the path like this.
# .PHONY: otherbin
# otherbin: .GOPATH/.ok
#   $Q go install $(if $V,-v) $(VERSION_FLAGS) $(IMPORT_PATH)/cmd/otherbin

##### ^^^^^^ EDIT ABOVE ^^^^^^ #####

##### =====> Utility targets <===== #####

.PHONY: clean_hellogopher test_hellogopher list_hellogopher cover_hellogopher format_hellogopher

clean_hellogopher:
	$Q rm -rf bin .GOPATH

test_hellogopher: .GOPATH/.ok
	$Q go test $(if $V,-v) -i -race $(allpackages) # install -race libs to speed up next run
ifndef CI
	$Q go vet $(allpackages)
	$Q GODEBUG=cgocheck=2 go test -race $(allpackages)
else
	$Q ( go vet $(allpackages); echo $$? ) | \
		tee .GOPATH/test/vet.txt | sed '$$ d'; exit $$(tail -1 .GOPATH/test/vet.txt)
	$Q ( GODEBUG=cgocheck=2 go test -v -race $(allpackages); echo $$? ) | \
		tee .GOPATH/test/output.txt | sed '$$ d'; exit $$(tail -1 .GOPATH/test/output.txt)
endif

list_hellogopher: .GOPATH/.ok
	@echo $(allpackages)

cover_hellogopher: bin/gocovmerge .GOPATH/.ok
	@echo "NOTE: make cover does not exit 1 on failure, don't use it to check for tests success!"
	$Q rm -f .GOPATH/cover/*.out .GOPATH/cover/all.merged
	$(if $V,@echo "-- go test -coverpkg=./... -coverprofile=.GOPATH/cover/... ./...")
	@for MOD in $(allpackages); do \
		go test -coverpkg=`echo $(allpackages)|tr " " ","` \
			-coverprofile=.GOPATH/cover/unit-`echo $$MOD|tr "/" "_"`.out \
			$$MOD 2>&1 | grep -v "no packages being tested depend on"; \
	done
	$Q ./bin/gocovmerge .GOPATH/cover/*.out > .GOPATH/cover/all.merged
ifndef CI
	$Q go tool cover -html .GOPATH/cover/all.merged
else
	$Q go tool cover -html .GOPATH/cover/all.merged -o .GOPATH/cover/all.html
endif
	@echo ""
	@echo "=====> Total test coverage: <====="
	@echo ""
	$Q go tool cover -func .GOPATH/cover/all.merged

format_hellogopher: bin/goimports .GOPATH/.ok
	$Q find .GOPATH/src/$(IMPORT_PATH)/ -iname \*.go | grep -v \
		-e "^$$" $(addprefix -e ,$(IGNORED_PACKAGES)) | xargs ./bin/goimports -w

##### =====> Internals <===== #####

.PHONY: setup_hellogopher
setup_hellogopher: clean_hellogopher .GOPATH/.ok
	go get -u github.com/FiloSottile/gvt
	- ./bin/gvt fetch golang.org/x/tools/cmd/goimports
	- ./bin/gvt fetch github.com/wadey/gocovmerge

VERSION          := $(shell git describe --tags --always --dirty="-dev")
DATE             := $(shell date -u '+%Y-%m-%d-%H%M UTC')
VERSION_FLAGS    := -ldflags='-X "main.Version=$(VERSION)" -X "main.BuildTime=$(DATE)"'

# cd into the GOPATH to workaround ./... not following symlinks
_allpackages = $(shell ( cd $(CURDIR)/.GOPATH/src/$(IMPORT_PATH) && \
	GOPATH=$(CURDIR)/.GOPATH go list ./... 2>&1 1>&3 | \
	grep -v -e "^$$" $(addprefix -e ,$(IGNORED_PACKAGES)) 1>&2 ) 3>&1 | \
	grep -v -e "^$$" $(addprefix -e ,$(IGNORED_PACKAGES)))

# memoize allpackages, so that it's executed only once and only if used
allpackages = $(if $(__allpackages),,$(eval __allpackages := $$(_allpackages)))$(__allpackages)

export GOPATH := $(CURDIR)/.GOPATH
unexport GOBIN

Q := $(if $V,,@)

.GOPATH/.ok:
	$Q mkdir -p "$(dir .GOPATH/src/$(IMPORT_PATH))"
	$Q ln -s ../../../.. ".GOPATH/src/$(IMPORT_PATH)"
	$Q mkdir -p .GOPATH/test .GOPATH/cover
	$Q mkdir -p bin
	$Q ln -s ../bin .GOPATH/bin
	$Q touch $@

.PHONY: bin/gocovmerge bin/goimports
bin/gocovmerge: .GOPATH/.ok
	@test -d ./vendor/github.com/wadey/gocovmerge || \
		{ echo "Vendored gocovmerge not found, try running 'make setup'..."; exit 1; }
	$Q go install $(IMPORT_PATH)/vendor/github.com/wadey/gocovmerge
bin/goimports: .GOPATH/.ok
	@test -d ./vendor/golang.org/x/tools/cmd/goimports || \
		{ echo "Vendored goimports not found, try running 'make setup'..."; exit 1; }
	$Q go install $(IMPORT_PATH)/vendor/golang.org/x/tools/cmd/goimports

# Based on https://github.com/cloudflare/hellogopher - v1.1 - MIT License
#
# Copyright (c) 2017 Cloudflare
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
