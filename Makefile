### modify these paths to local Boost and NLopt install directories
BOOST_INSTALL_DIR = /usr/share/boost-build
NLOPT_INSTALL_DIR = /usr/share/NLopt.v2.6.1

INTELROOT = /cygdrive/c/Program Files (x86)/IntelSWTools/compilers_and_libraries/windows
MKLROOT = ${INTELROOT}/mkl
ZLIB_STATIC_DIR = /usr/i686-pc-cygwin/sys-root/usr/include # probably unnecessary on most systems
LIBSTDCXX_STATIC_DIR = /lib/gcc/x86_64-pc-cygwin/7.4.0
GLIBC_STATIC_DIR = /home/pl88/glibc-static/usr/lib64

ifeq ($(strip ${linking}),)
	linking = dynamic
endif

# CC = g++
CC = g++

ifeq (${debug},true)
	CFLAGS += -g
else
	CFLAGS += -O2
endif

CFLAGS += -msse -msse2
CFLAGS += -DUSE_SSE -DMEASURE_DGEMM -DVERBOSE
CFLAGS += -Wall


# add Boost include and lib paths
ifneq ($(strip ${BOOST_INSTALL_DIR}),)
	CPATHS += -I${BOOST_INSTALL_DIR}/include
	LPATHS += -L${BOOST_INSTALL_DIR}/lib
	ifeq (${linking},dynamic)
		LPATHS += -Wl,-rpath,${BOOST_INSTALL_DIR}/lib
	endif
endif

# add NLopt include and lib paths
ifneq ($(strip ${NLOPT_INSTALL_DIR}),)
	CPATHS += -I${NLOPT_INSTALL_DIR}/api
	LPATHS += -L${NLOPT_INSTALL_DIR}/.libs
	ifeq (${linking},dynamic)
		LPATHS += -Wl,-rpath,${NLOPT_INSTALL_DIR}/.libs
	endif
endif

# add zlib.a path for static linking on Orchestra
ifneq ($(strip ${ZLIB_STATIC_DIR}),)
	ifneq (${linking},dynamic)
		LPATHS += -L${ZLIB_STATIC_DIR}
	endif
endif

# add MKL paths (if not compiling with g++, i.e., compiling with icpc)
ifneq (${CC},g++)
	CPATHS += -I${MKLROOT}/include
	ifeq (${linking},dynamic)
		LPATHS += -L${MKLROOT}/lib/intel64 -Wl,-rpath,${MKLROOT}/lib/intel64 # for libmkl*
		LPATHS += -Wl,-rpath,${INTELROOT}/lib/intel64 # for libiomp5.so
	endif
endif

# add flags for static linking; build LAPACK/MKL component of link line
ifeq (${CC},g++)
	CFLAGS += -fopenmp
	LFLAGS += -fopenmp
	LLAPACK = -llapack -lgfortran
	ifeq (${linking},static)
		LFLAGS += -static
		LPATHS += -L${GLIBC_STATIC_DIR} -L${ZLIB_STATIC_DIR}
	else ifeq (${linking},static-except-glibc)
		LFLAGS += -static-libgcc -static-libstdc++
		LPATHS += -L${ZLIB_STATIC_DIR}
	endif
else
	CFLAGS += -DUSE_MKL #-DUSE_MKL_MALLOC
	CFLAGS += -qopenmp
	LFLAGS += -qopenmp
	CFLAGS += -Wunused-variable -Wpointer-arith -Wuninitialized -Wreturn-type -Wcheck -Wshadow
	ifeq (${linking},static)
		LFLAGS += -static
		LPATHS += -L${GLIBC_STATIC_DIR} -L${ZLIB_STATIC_DIR}
		LLAPACK = -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_intel_thread.a -Wl,--end-group
	else ifeq (${linking},static-except-glibc)
		LFLAGS += -static-intel -static-libstdc++ -static-libgcc
		LPATHS += -L${ZLIB_STATIC_DIR}
		LLAPACK = -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_intel_thread.a -Wl,--end-group
	else
		LLAPACK = -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread
	endif
# Note: If MKL LAPACK routines are called with arrays of size >= 2^31,
#       interface layer ILP64 (64-bit integer) is required.
#       However, since BOLT-LMM makes linear algebra calls in blocks, LP64 (32-bit)
#       should be sufficient.
endif

# build link line (minus flags)
LLIBS = -lboost_program_options -lboost_iostreams -lz -lnlopt
ifeq (${linking},static-except-glibc)
	L = -L${LIBSTDCXX_STATIC_DIR} ${LPATHS} -Wl,--wrap=memcpy -Wl,-Bstatic ${LLIBS} ${LLAPACK} -Wl,-Bdynamic -lpthread -lm
else
	L = ${LPATHS} ${LLIBS} ${LLAPACK} -lpthread -lm
endif



T = bolt
O = Bolt.o BoltParams.o BoltParEstCV.o BoltReml.o CovariateBasis.o DataMatrix.o FileUtils.o Jackknife.o LDscoreCalibration.o MapInterpolater.o MatrixUtils.o MemoryUtils.o NonlinearOptMulti.o NumericUtils.o PhenoBuilder.o RestrictSnpSet.o SnpData.o SnpInfo.o SpectrumTools.o StatsUtils.o StringUtils.o Timer.o memcpy.o
OMAIN = BoltMain.o $O

.PHONY: clean

%.o: %.cpp
	${CC} ${CFLAGS} ${CPATHS} -o $@ -c $<

$T: ${OMAIN}
	${CC} ${LFLAGS} -o $T ${OMAIN} $L

clean:
	rm -f *.o
	rm -f $T
