config ?= release
arch ?=
static ?= false
linker ?=

BUILD_DIR ?= build/$(config)
SRC_DIR ?= velle
binary := $(BUILD_DIR)/velle
tests_binary := $(BUILD_DIR)/test

ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

PONYC ?= ponyc

ifeq ($(config),release)
	PONYC := $(PONYC)
else
	PONYC := $(PONYC) --debug
endif

ifneq ($(arch),)
  arch_arg := --cpu $(arch)
endif

ifdef static
  ifeq (,$(filter $(static),true false))
  	$(error "static must be true or false)
  endif
endif

ifeq ($(static),true)
  LINKER += --static
endif

ifneq ($(linker),)
  LINKER += --link-ldcmd=$(linker)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name \*.pony)
TEST_FILES := $(shell find test -name \*.pony -o -name helper.sh)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

%.pony: %.pony.in VERSION
	sed s/%%VERSION%%/$(version)/ $< > $@

$(binary): $(GEN_FILES) $(SOURCE_FILES) corral.json | $(BUILD_DIR)
	corral fetch
	corral run -- ${PONYC} $(arch_arg) $(LINKER) $(SRC_DIR) -o ${BUILD_DIR}

$(tests_binary): $(GEN_FILES) $(SOURCE_FILES) $(TEST_FILES) corral.json | $(BUILD_DIR)
	corral fetch
	corral run -- ${PONYC} $(arch_arg) $(LINKER) --debug -o ${BUILD_DIR} test

test: $(tests_binary)
	$^

clean:
	rm -rf $(BUILD_DIR)

all: test $(binary)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all clean
