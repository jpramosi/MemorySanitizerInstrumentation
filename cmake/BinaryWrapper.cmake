function (package_scripts FILE_NAME ABORT_ERROR)
    if (ABORT_ERROR)
        set(PS_VAL_ABORT "|| exit $?")
    endif()
    set(ps_val "#!/bin/bash\n")
    set(ARG_NUM 2)
    while(ARG_NUM LESS ARGC)
        set(ps_val "${ps_val}echo \"Run ${ARGV${ARG_NUM}}\"\n./${ARGV${ARG_NUM}} ${PS_VAL_ABORT}\nsleep 1\n")
        math(EXPR ARG_NUM "${ARG_NUM}+1")
    endwhile()
    file(WRITE ${CMAKE_BINARY_DIR}/${FILE_NAME}.sh ${ps_val})
endfunction()




function (create_script_coverage BINARY SCOPE)
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        create_script_llvm_coverage(${BINARY} "${SCOPE}")
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        create_script_gcc_coverage(${BINARY} "${SCOPE}")
	endif()
endfunction()




function (create_script_llvm_coverage BINARY SCOPE)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}_cover.sh
"#!/bin/bash
NAME=\"${BINARY}\"
COVERAGE_DIR=\"Coverage/$NAME\"
COVERAGE_FILE=\"cov_$NAME\"
LLVM_COV=\"\"
for file in $(find /usr/lib/llvm* -name 'llvm-cov')
do
    LLVM_COV=\"$file\"
done
LLVM_DIR=\${LLVM_COV//\"/llvm-cov\"}

# Create coverage data
export LLVM_PROFILE_FILE=\"$COVERAGE_DIR/$COVERAGE_FILE.profraw\"
./$NAME

# Parse data
$LLVM_DIR/llvm-profdata merge -sparse $COVERAGE_DIR/$COVERAGE_FILE.profraw -o $COVERAGE_DIR/$COVERAGE_FILE.profdata

# Create html coverage file
$LLVM_DIR/llvm-cov show \
-output-dir=$COVERAGE_DIR \
-show-line-counts-or-regions \
-Xdemangler c++filt \
-format=\"html\" \
-instr-profile=$COVERAGE_DIR/$COVERAGE_FILE.profdata ${BINARY} ${SCOPE}")
endfunction()




function (create_script_gcc_coverage BINARY SCOPE)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}_cover.sh
"#!/bin/bash
NAME=\"${BINARY}\"
COVERAGE_DIR=\"Coverage/$NAME\"
COVERAGE_FILE=\"cov_$NAME\"
export GCOV_PREFIX=\"$COVERAGE_DIR\"
export GCOV_PREFIX_STRIP=30

if gcovr --version | grep -q 'Copyright'; then
    echo \"gcovr found\"
else
    echo \"gcovr not found, please install it with:\nsudo apt-get install gcovr\"
    exit 1
fi

# Execute binary to get the call traces
./${BINARY}

# Replace _ with -
rep=\"${BINARY}\"
NEW_BIN=\$\{rep//[_]/-\}

# Find gcno file
find $PWD -type f -name $NEW_BIN*.gcno -exec cp {} $COVERAGE_DIR 2>/dev/null \;
if [[ -z $(find $COVERAGE_DIR -type f -name $NEW_BIN*.gcno) ]]
then
    echo \"Could not find file with pattern '$NEW_BIN*.gcno'\"
    exit 1
fi

# Generate report
if [ -z \"${SCOPE}\" ]
then
    cd $COVERAGE_DIR && \
    gcovr -r ${PROJECT_SOURCE_DIR}/ \
    --html --html-details \
    -o ${BINARY}_coverage.html
else
    cd $COVERAGE_DIR && \
    gcovr -r ${PROJECT_SOURCE_DIR}/ \
    --html --html-details \
    -f ${SCOPE} \
    -o ${BINARY}_coverage.html
fi
")
endfunction()




function (create_script_valgrind BINARY REPORT_FOLDER)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}_valgrind.sh
"#!/bin/bash
VALGRIND_ARGS=\
\"--error-limit=no \
--quiet \
--leak-check=full \
--track-origins=yes \
--fair-sched=yes \
--track-origins=yes \
--vgdb=no\"

if [ -z \"${REPORT_FOLDER}\" ]
then
    valgrind ${VALGRIND_ARGS} ./${BINARY}
else
    FILE_OUT=\"$(date +%d-%m-%Y[%Hh%Mm%Ss]).txt\"
    mkdir -p \"${REPORT_FOLDER}\"
    valgrind ${VALGRIND_ARGS} ./${BINARY} 2>${REPORT_FOLDER}/$FILE_OUT
fi
")
endfunction()




function (create_script_asan BINARY REPORT_FOLDER)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}.sh
"#!/bin/bash
ASAN_OPTIONS=\"symbolize=1\"
ASAN_OPTIONS+=\":detect_leaks=1\"
ASAN_OPTIONS+=\":abort_on_error=1\"
export ASAN_OPTIONS

LSAN_OPTIONS=\"report_objects=1\"
export LSAN_OPTIONS

symbolizer_path=\"\"
for file in $(find /usr/lib/llvm* -name 'llvm-symbolizer')
do
    symbolizer_path=\"$file\"
done
export ASAN_SYMBOLIZER_PATH=\"$symbolizer_path\"

if [ -z \"${REPORT_FOLDER}\" ]
then
    ./${BINARY}
else
    FILE_OUT=\"$(date +%d-%m-%Y[%Hh%Mm%Ss]).txt\"
    mkdir -p \"${REPORT_FOLDER}\"
    ./${BINARY} 2>${REPORT_FOLDER}/$FILE_OUT
fi
")
endfunction()




function (create_script_tsan BINARY REPORT_FOLDER)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}.sh
"#!/bin/bash

symbolizer_path=\"\"
for file in $(find /usr/lib/llvm* -name 'llvm-symbolizer')
do
    symbolizer_path=\"$file\"
done

TSAN_OPTIONS=\"external_symbolizer_path=$symbolizer_path\"
TSAN_OPTIONS+=\":report_signal_unsafe=0\"
export TSAN_OPTIONS

if [ -z \"${REPORT_FOLDER}\" ]
then
    ./${BINARY}
else
    FILE_OUT=\"$(date +%d-%m-%Y[%Hh%Mm%Ss]).txt\"
    mkdir -p \"${REPORT_FOLDER}\"
    ./${BINARY} 2>${REPORT_FOLDER}/$FILE_OUT
fi
")
endfunction()




function (create_script_ubsan BINARY REPORT_FOLDER)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}.sh
"#!/bin/bash

UBSAN_OPTIONS=\"print_stacktrace=1\"
export UBSAN_OPTIONS

symbolizer_path=\"\"
for file in $(find /usr/lib/llvm* -name 'llvm-symbolizer')
do
    symbolizer_path=\"$file\"
done
symbolizer_dir=\${symbolizer_path//\"/llvm-symbolizer\"}
export PATH=$PATH:$symbolizer_dir

if [ -z \"${REPORT_FOLDER}\" ]
then
    ./${BINARY}
else
    FILE_OUT=\"$(date +%d-%m-%Y[%Hh%Mm%Ss]).txt\"
    mkdir -p \"${REPORT_FOLDER}\"
    ./${BINARY} 2>${REPORT_FOLDER}/$FILE_OUT
fi
")
endfunction()




function (create_script_msan BINARY REPORT_FOLDER)
    file(WRITE ${CMAKE_BINARY_DIR}/s_${BINARY}.sh
"#!/bin/bash

symbolizer_path=\"\"
for file in $(find /usr/lib/llvm* -name 'llvm-symbolizer')
do
    symbolizer_path=\"$file\"
done
export MSAN_SYMBOLIZER_PATH=\"$symbolizer_path\"

if [ -z \"${REPORT_FOLDER}\" ]
then
    ./${BINARY}
else
    FILE_OUT=\"$(date +%d-%m-%Y[%Hh%Mm%Ss]).txt\"
    mkdir -p \"${REPORT_FOLDER}\"
    ./${BINARY} 2>${REPORT_FOLDER}/$FILE_OUT
fi
")
endfunction()