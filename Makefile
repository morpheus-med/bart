# Copyright 2013-2015. The Regents of the University of California.
# Copyright 2015. Martin Uecker.
# All rights reserved. Use of this source code is governed by
# a BSD-style license which can be found in the LICENSE file.

# we have a two stage Makefile
MAKESTAGE ?= 1

# silent make
#MAKEFLAGS += --silent

# clear out all implicit rules and variables
MAKEFLAGS += -R

# use for parallel make
AR=./ar_lock.sh

CUDA?=0
ACML?=0
OMP?=1
SLINK?=0
DEBUG?=0

DESTDIR ?= /

BUILDTYPE = Linux
UNAME = $(shell uname -s)
NNAME = $(shell uname -n)

MYLINK=ln

ifeq ($(UNAME),Darwin)
	BUILDTYPE = MacOSX
	ACML = 0
	MYLINK = ln -s
endif

ARFLAGS = r


# Paths

here  = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
root := $(here)

srcdir = $(root)/src
libdir = $(root)/lib
bindir = $(root)/bin

export TOOLBOX_PATH=$(root)


# Automatic dependency generation

DEPFILE = $(*D)/.$(*F).d
DEPFLAG = -MMD -MF $(DEPFILE)
ALLDEPS = $(shell find $(srcdir) -name ".*.d")
#ALLDEPS = $(shell find $(root) -name ".*.d")


# Compilation flags

OPT = -O3 -ffast-math
CPPFLAGS ?= -Wall -Wextra
CFLAGS ?= $(OPT) -Wmissing-prototypes
CXXFLAGS ?= $(OPT)
CC ?= gcc
CXX ?= g++


ifeq ($(BUILDTYPE), MacOSX)
	CC = gcc-mp-4.7
endif


# cuda

cuda.top ?= /usr/


# BLAS/LAPACK

acml.top ?= /usr/local/acml/acml4.4.0/gfortran64_mp/

# fftw

fftw.top ?= /usr/

# Matlab

matlab.top ?= /usr/local/matlab/

# ISMRM

ismrm.top ?= /usr/local/ismrmrd/





# Main build targets

TBASE=show slice crop resize join transpose zeros ones flip circshift extract repmat bitmask reshape version
TFLP=scale conj fmac saxpy sdot spow cpyphs creal normalize cdf97 pattern nrmse mip
TNUM=fft fftmod fftshift noise bench threshold conv rss filter
TRECO=pics pocsense rsense bpsense itsense nlinv nufft rof sake wave lrmatrix estdims
TCALIB=ecalib ecaltwo caldir walsh cc calmat svd estvar
TMRI=homodyne poisson twixread fakeksp
TSIM=phantom traj
TIO=toimg
BTARGETS = $(TBASE) $(TFLP) $(TNUM) $(TIO)
XTARGETS = $(TRECO) $(TCALIB) $(TMRI) $(TSIM)
YTARGETS = $(BTARGETS) $(XTARGETS)
ZTARGETS = bbox bart $(XTARGETS)
TARGETS = bart $(BTARGETS) $(XTARGETS)





MODULES = -lnum -lmisc -lnum -lmisc

MODULES_pics = -lsense -lwavelet2 -liter -llinops -lwavelet3 -llowrank -lnoncart
MODULES_pocsense = -lsense -lwavelet2 -liter -llinops
MODULES_nlinv = -lnoir -liter
MODULES_rsense = -lgrecon -lsense -lnoir -lwavelet2 -lcalib -liter -llinops
MODULES_bpsense = -lsense -lwavelet2 -lnoncart -liter -llinops
MODULES_itsense = -liter -llinops
MODULES_ecalib = -lcalib
MODULES_ecaltwo = -lcalib
MODULES_caldir = -lcalib
MODULES_walsh = -lcalib
MODULES_calmat = -lcalib
MODULES_cc = -lcalib
MODULES_estvar = -lcalib
MODULES_nufft = -lnoncart -liter -llinops
MODULES_rof = -liter -llinops
MODULES_bench = -lwavelet2 -lwavelet3 -llinops
MODULES_phantom = -lsimu
MODULES_bbox += -lbox -lwavelet2 -lwavelet3 -llinops -liter -llinops -llowrank -ldfwavelet
MODULES_bart += -lbox -lbox2 -lgrecon -lsense -lnoir -lwavelet2 -liter -llinops -lwavelet3 -llowrank -lnoncart -lcalib -lsimu -lsake -ldfwavelet
MODULES_sake += -lsake
MODULES_wave += -liter -lwavelet2 -llinops -lsense
MODULES_threshold += -llowrank -llinops -lwavelet2 -liter -ldfwavelet
MODULES_fakeksp += -lsense -llinops
MODULES_lrmatrix = -llowrank -liter -llinops
MODULES_estdims = -lnoncart -llinops

-include Makefile.$(NNAME)
-include Makefile.local


ifeq ($(DEBUG),1)
CPPFLAGS += -g
CFLAGS += -g
endif


ifeq ($(PARALLEL),1)
MAKEFLAGS += -j
endif


ifeq ($(MAKESTAGE),1)
.PHONY: doc/commands.txt $(TARGETS) ismrmrd
default all clean allclean distclean doc/commands.txt $(TARGETS) ismrmrd:
	make MAKESTAGE=2 $(MAKECMDGOALS)
else


CPPFLAGS += $(DEPFLAG) -I$(srcdir)/
CFLAGS += -std=c99 -I$(srcdir)/
CXXFLAGS += -I$(srcdir)/




default: bart doc/commands.txt .gitignore


-include $(ALLDEPS)




# cuda

NVCC = $(cuda.top)/bin/nvcc


ifeq ($(CUDA),1)
CUDA_H := -I$(cuda.top)/include
CPPFLAGS += -DUSE_CUDA $(CUDA_H)
ifeq ($(BUILDTYPE), MacOSX)
CUDA_L := -L$(cuda.top)/lib -lcufft -lcudart -lcublas -m64 -lstdc++
else
CUDA_L := -L$(cuda.top)/lib64 -lcufft -lcudart -lcublas -lstdc++ -Wl,-rpath $(cuda.top)/lib64
endif 
else
CUDA_H :=
CUDA_L :=  
endif

NVCCFLAGS = -DUSE_CUDA -Xcompiler -fPIC -Xcompiler -fopenmp -O3 -arch=sm_20 -I$(srcdir)/ -m64 -ccbin $(CC)
#NVCCFLAGS = -Xcompiler -fPIC -Xcompiler -fopenmp -O3  -I$(srcdir)/


%.o: %.cu
	$(NVCC) $(NVCCFLAGS) -c $^ -o $@
	$(NVCC) $(NVCCFLAGS) -M $^ -o $(DEPFILE)


# OpenMP

ifeq ($(OMP),1)
CFLAGS += -fopenmp
CXXFLAGS += -fopenmp
else
CFLAGS += -Wno-unknown-pragmas
CXXFLAGS += -Wno-unknown-pragmas
endif



# BLAS/LAPACK

BLAS_H :=
BLAS_L :=

ifeq ($(ACML),1)
BLAS_H := -I$(acml.top)/include
BLAS_L := -L$(acml.top)/lib -lgfortran -lacml_mp -Wl,-rpath $(acml.top)/lib
CPPFLAGS += -DUSE_ACML
else
ifeq ($(BUILDTYPE), MacOSX)
BLAS_L := -lblas -framework Accelerate
else
BLAS_L := -llapack -lblas #-lgfortran
endif
endif




CPPFLAGS += $(FFTW_H)



# png
PNG_L := -lpng

ifeq ($(SLINK),1)
	PNG_L += -lz
endif



# fftw

FFTW_H := -I$(fftw.top)/include/
FFTW_L := -L$(fftw.top)/lib -lfftw3f_threads -lfftw3f


# Matlab

MATLAB_H := -I$(matlab.top)/extern/include
MATLAB_L := -Wl,-rpath $(matlab.top)/bin/glnxa64 -L$(matlab.top)/bin/glnxa64 -lmat -lmx -lm -lstdc++

# ISMRM

ISMRM_H := -I$(ismrm.top)/include -I$(ismrm.top)/schema #-DISMRMRD_OLD
ISMRM_L := /usr/local/ismrmrd/schema/ismrmrd.cxx -Wl,-R$(ismrm.top)/lib -L$(ismrm.top)/lib -lismrmrd -Lhd5 -lxerces-c -lboost_system
#ISMRM_L := -Wl,-R$(ismrm.top)/lib -L$(ismrm.top)/lib -lismrmrd -lismrmrd_xsd -Lhd5 



# change for static linking

ifeq ($(SLINK),1)
# work around fortran problems with static linking
LDFLAGS += -static -Wl,--whole-archive -lpthread -Wl,--no-whole-archive -Wl,--allow-multiple-definition
ifneq ($(BUILDTYPE), MacOSX)
BLAS_L += -lgfortran
endif
endif



# Modules

.LIBPATTERNS := lib%.a


vpath %.a lib

DIRS = $(root)/rules/*.mk

include $(DIRS)

# sort BTARGETS after everything is included
BTARGETS:=$(sort $(BTARGETS))
YTARGETS:=$(sort $(YTARGETS))



.gitignore: .gitignore.main Makefile*
	@echo '# AUTOGENERATED. DO NOT EDIT. (are you looking for .gitignore.main ?)' > .gitignore
	cat .gitignore.main >> .gitignore
	@echo $(patsubst %, /%, $(TARGETS)) | tr ' ' '\n' >> .gitignore


doc/commands.txt: bart
	@echo AUTOGENERATED. DO NOT EDIT. > doc/commands.new
	for cmd in $(YTARGETS) ; do 		\
		printf "\n\n--%s--\n\n" $$cmd ;	\
		 ./bart $$cmd -h ;		\
	done >> doc/commands.new
	$(root)/rules/update-if-changed.sh doc/commands.new doc/commands.txt


all: .gitignore $(TARGETS)





# special targets


$(XTARGETS): CPPFLAGS += -DMAIN_LIST="$(XTARGETS:%=%,) ()" -include src/main.h


bbox: CPPFLAGS += -DMAIN_LIST="$(BTARGETS:%=%,) ()" -include src/main.h

bart: CPPFLAGS += -DMAIN_LIST="$(YTARGETS:%=%,) ()" -include src/main.h


ismrmrd: $(srcdir)/ismrmrd.c -lismrm -lnum -lmisc
	$(CC) $(CXXFLAGS) -o ismrmrd $+ $(CUDA_L) $(ISMRM_L) -lstdc++ -lm

mat2cfl: $(srcdir)/mat2cfl.c -lnum -lmisc
	$(CC) $(CFLAGS) $(MATLAB_H) -omat2cfl  $+ $(MATLAB_L) $(CUDA_L)




$(BTARGETS): bbox
	rm -f $@ && $(MYLINK) bbox $@


# implicit rules

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

%.o: %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

ifeq ($(PARALLEL),1)
(%): %
	$(AR) r $@ $%
else
(%): %
	$(AR) r $@ $%
	rm $%
endif


# we add the rm because intermediate files are not deleted
# automatically for some reason
# (but it produces errors for parallel builds for make all)



.SECONDEXPANSION:
$(ZTARGETS): % : src/main.c $(srcdir)/%.o $$(MODULES_%) $(MODULES)
	$(CC) $(LDFLAGS) $(CFLAGS) -Dmain_real=main_$@ -o $@ $+ $(FFTW_L) $(CUDA_L) $(BLAS_L) $(PNG_L) -lm
#	rm $(srcdir)/$@.o


clean:
	rm -f `find $(srcdir) -name "*.o"`
	rm -f $(root)/lib/.*.lock

allclean: clean
	rm -f $(libdir)/*.a ismrmrd $(ALLDEPS)
	rm -f bbox $(patsubst %, %, $(TARGETS))
	rm -f $(srcdir)/misc/version.inc

distclean: allclean


endif	# MAKESTAGE


install: bart $(root)/doc/commands.txt
	install -d $(DESTDIR)/usr/bin/
	install bart $(DESTDIR)/usr/bin/
	install -d $(DESTDIR)/usr/share/doc/bart/
	install $(root)/doc/*.txt $(root)/README $(DESTDIR)/usr/share/doc/bart/
	install -d $(DESTDIR)/usr/lib/bart/commands/


# generate release tar balls (identical to github)
%.tar.gz:
	git archive --prefix=bart-$(patsubst bart-%.tar.gz,%,$@)/ -o $@ v$(patsubst bart-%.tar.gz,%,$@)


