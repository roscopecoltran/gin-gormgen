.PHONY: all

# local machine
OS          			?= $(shell go env GOOS)
ARCH        			?= $(shell go env GOARCH)
ENV_FILE 				?= .env
BASH 					?= $(shell which bash 2>/dev/null)
BINARY_DIR   			?= $(CURDIR)/bin

# app
APP_BINARY_NAME  		?= gin-gormgen
ifeq ($(OS),windows)
	APP_BINARY_NAME 	:= $(APP_BINARY_NAME).exe
endif

# build
BUILD_FLAGS  			?= -v
BUILD_TIME				:= $(shell date +%Y%m%d%H%M%S)
BUILD_LDFLAGS      		?= -X main.version=$(VERSION) -w -s

# git info
GIT_USER_INFO 			:= $(shell git config user.name)
GIT_USER_FULLNAME 		:= $(shell git config user.name)
GIT_BRANCH 				:= $(subst heads/,,$(shell git rev-parse --abbrev-ref HEAD 2>/dev/null))
GIT_REMOTE_URL 			:= $(shell git config --local remote.origin.url)
GIT_BUILD_TAG 			:= $(BUILD_TIME)
GIT_BUILD_SHA 			:= $(shell git rev-parse --short=$(GIT_SHA_LEN) --verify HEAD)
GIT_BUILD_REPO			:= $(shell git remote show -n origin | grep '^ *Push *' | awk {'print $$NF'})
GIT_BUILD_ORG 			:= $(shell echo $(GIT_BUILD_REPO) | sed -e 's!.*[:/]\([^/]\+\)/.*!\1!')
GIT_COMMIT 				:= $(shell git rev-parse --short HEAD)
# GIT_TAG 				:= $(shell git describe --tags | grep -oP "v[0-9]+(\.[0-9]+)*") # 2>/dev/null
# GIT_BUILD_VERSION 	:= $(shell git describe --tags | grep -oP "v[0-9]+(\.[0-9]+)*" | sed 's/v//') # 2>/dev/null

# golang
GO_SOURCES      		= $(shell find . -name '*.go')
GO_TEMPLATES    		= $(shell find templates -type f -name '*.gotmpl')
GO_PKGS 				= $(foreach pkg, $(shell go list ./...), $(if $(findstring /vendor/, $(pkg)), , $(pkg)))
GO_TOOLS 				= 	github.com/tcnksm/ghr \
							github.com/mitchellh/gox \
							github.com/Masterminds/glide \
							github.com/jteeuwen/go-bindata/go-bindata

install:
	go install $(GO_PKGS)

generate: bindata.go ## embed assets (templates *.gotmpl) required by `aor-gin-swagger` generator

tools:
	go get -u -v $(GO_TOOLS)

bindata.go: $(TEMPLATES)
	go generate .

$(APP_BINARY_NAME): bindata.go $(GO_SOURCES)
	CGO_ENABLED=0 go build -o $(BINARY_DIR)/$(APP_BINARY_NAME) $(BUILD_FLAGS) -ldflags "$(LDFLAGS)"

build: $(APP_BINARY_NAME)  ## (step 0) build the `gin-gormgen` generator from sources

vet:
	go vet $(GO_PKGS)

test: install generate
	go test -v

