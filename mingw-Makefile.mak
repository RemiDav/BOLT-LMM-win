### modify these paths to local Boost and NLopt install directories
BOOST_INSTALL_DIR = D:/Dev/cygwin-projects/boost_1_70_0
NLOPT_INSTALL_DIR = D:/Dev/cygwin-projects/nlopt-2.6.1/build
LAPACK_DIR = D:/Dev/cygwin-projects/OpenBLAS-develop

ifeq ($(strip ${linking}),)
	linking = dynamic
endif

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
	CPATHS += -I${BOOST_INSTALL_DIR}
	LPATHS += -L${BOOST_INSTALL_DIR}/lib
endif

# add NLopt include and lib paths
ifneq ($(strip ${NLOPT_INSTALL_DIR}),)
	CPATHS += -I${NLOPT_INSTALL_DIR}/src/api
	LPATHS += -L${NLOPT_INSTALL_DIR}
endif

# add zlib.a path for static linking on Orchestra
ifneq ($(strip ${ZLIB_STATIC_DIR}),)
	ifneq (${linking},dynamic)
		LPATHS += -L${ZLIB_STATIC_DIR}
	endif
endif

#add lapack path
LPATHS += -L"${LAPACK_DIR}/lib"

# add flags for static linking; build LAPACK/MKL component of link line
CFLAGS += -fopenmp
LFLAGS += -fopenmp
# LLAPACK = -llapack -lgfortran -lblas
LLAPACK = -lopenblas.dll
ifeq (${linking},static)
	LFLAGS += -static
	LPATHS += -L${GLIBC_STATIC_DIR} -L${ZLIB_STATIC_DIR}
else ifeq (${linking},static-except-glibc)
	LFLAGS += -static-libgcc -static-libstdc++
	LPATHS += -L${ZLIB_STATIC_DIR}
endif

# build link line (minus flags)
LLIBS = -lboost_program_options-mgw91-mt-x64-1_70 -lboost_iostreams-mgw91-mt-x64-1_70 -lz -lnlopt.dll
L = ${LPATHS} ${LLIBS} ${LLAPACK} -lpthread -lm




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
