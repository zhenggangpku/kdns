#/* Copyright (c) 2018 The TIGLabs Authors */

ifdef V
Q =
else
Q = @
endif

ifeq ($(machine),)
machine = native
endif

ifeq ($(JOBS),)
    JOBS := $(shell grep -c ^processor /proc/cpuinfo 2>/dev/null)
    ifeq ($(JOBS),)
        JOBS := 1
    endif
endif


RTE_SDK_TAR = $(CURDIR)/dpdk-19.08.tar.xz
RTE_SDK = $(CURDIR)/dpdk-19.08
export RTE_SDK

# Default target, can be overriden by command line or environment
RTE_TARGET ?= x86_64-$(machine)-linuxapp-gcc
export RTE_TARGET

bindir =  $(CURDIR)/bin


VERSION ?= 0.1

.PHONY: default
default: kdns

.PHONY: all
all: dpdk deps kdns bin

.PHONY: dpdk
dpdk:
	$(Q)rm -fr $(RTE_SDK)
	$(Q)tar -xvf $(RTE_SDK_TAR)
	$(Q)cd $(RTE_SDK) && $(MAKE) O=$(RTE_TARGET) T=$(RTE_TARGET) config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(RTE_MACHINE=).*,\1$(machine),' $(RTE_TARGET)/.config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(RTE_APP_TEST=).*,\1n,'         $(RTE_TARGET)/.config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(RTE_LIBRTE_PMD_PCAP=).*,\1y,'  $(RTE_TARGET)/.config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(RTE_KNI_KMOD_ETHTOOL=).*,\1n,' $(RTE_TARGET)/.config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(RTE_LIBRTE_PMD_AF_XDP=).*,\1y,' $(RTE_TARGET)/.config
	$(Q)cd $(RTE_SDK) && sed -ri 's,(CFG_VALUE_LEN ).*,\1(2048),'   $(RTE_SDK)/lib/librte_cfgfile/rte_cfgfile.h
	$(Q)cd $(RTE_SDK) && $(MAKE) O=$(RTE_TARGET) -j ${JOBS}

.PHONY: deps
deps:
	$(Q)cd deps && make

.PHONY: kdns
kdns:
	$(Q)cd core && $(MAKE) O=$(RTE_TARGET)
	$(Q)cd src && $(MAKE) O=$(RTE_TARGET)
	$(Q)test -d $(bindir)|| mkdir -p $(bindir)
	$(Q)cp -a $(CURDIR)/src/$(RTE_TARGET)/kdns $(bindir)/kdns

.PHONY: bin
bin:
	$(Q)test -d $(bindir)|| mkdir -p $(bindir)
	$(Q)cp -a $(RTE_SDK)/usertools/cpu_layout.py $(bindir)/cpu_layout.py
	$(Q)cp -a $(RTE_SDK)/usertools/dpdk-devbind.py $(bindir)/dpdk-devbind.py
	$(Q)cp -a $(RTE_SDK)/$(RTE_TARGET)/kmod/igb_uio.ko $(bindir)/igb_uio.ko
	$(Q)cp -a $(RTE_SDK)/$(RTE_TARGET)/kmod/rte_kni.ko $(bindir)/rte_kni.ko
	$(Q)cp -a $(CURDIR)/src/$(RTE_TARGET)/kdns $(bindir)/kdns
	
.PHONY: clean
clean:
	$(Q)cd core && $(MAKE) O=$(RTE_TARGET) clean
	$(Q)cd src && $(MAKE) O=$(RTE_TARGET) clean
	
.PHONY: distclean
distclean:
	$(Q)cd core && $(MAKE) O=$(RTE_TARGET) clean
	$(Q)cd src && $(MAKE) O=$(RTE_TARGET) clean
	$(Q)cd core && rm -rf $(RTE_TARGET)
	$(Q)cd src && rm -rf $(RTE_TARGET)
	
