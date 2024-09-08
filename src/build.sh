#!/bin/bash

# E.g.: ./build.sh -d --sqlite

cc="g++"
options="-I. -m32 -fPIC -Wall -fvisibility=hidden"

separator="---------------------"

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -d | --debug)
            debug="-g -ggdb -O0" # debug build without optimization
            ;;
        -s | --sqlite)
            sqlite=true
            ;;
        -l | --libcurl)
            libcurl=true
            ;;
        --evp)
            evp=true
            ;;
        -u | --unsafe)
            unsafe=true
            ;;
        *)
            unrecognized_arg=$arg
            break
            ;;
    esac
    shift
done

if [ -v unrecognized_arg ]; then
    echo "Unrecognized argument \"$unrecognized_arg\", aborting."
    exit 1
fi

echo $separator

echo -n "Debug:   "
if [ -v debug ]; then
    echo "ON"
else
    echo "OFF"
    debug=""
fi

echo -n "EVP HASH: "
if [ -v evp ]; then
    echo " ON"
    constants+=" -D COMPILE_EVPHASH=1"
else
    echo " OFF"
    constants+=" -D COMPILE_EVPHASH=0"
fi

echo -n "Unsafe:  "
if [ -v unsafe ]; then
    echo "ON"
    constants+=" -D ENABLE_UNSAFE=1"
else
    echo "OFF"
    constants+=" -D ENABLE_UNSAFE=0"
fi

sqlite_found=0
sqlite_link=""
sqlite_libpath="/usr/lib32/libsqlite3.so"
sqlite_libpath2="/usr/lib/i386-linux-gnu/libsqlite3.so"
sqlite_libpath3="/usr/lib/libsqlite3.so"
echo -n "SQLite:  "
if [ -v sqlite ]; then
    if [ -e "$sqlite_libpath" ] || [ -e "$sqlite_libpath2" ] || [ -e "$sqlite_libpath3" ]; then
        sqlite_found=1
        sqlite_link="-lsqlite3"
        constants+=" -D COMPILE_SQLITE=1"
        echo "ON"
    else
        echo "requested but lib not found, aborting."
        exit 1
    fi
else
    echo "OFF"
    constants+=" -D COMPILE_SQLITE=0"
fi

libcurl_found=0
libcurl_link=""
libcurl_libpath="/usr/lib/i386-linux-gnu/libcurl.so.4"
echo -n "libcurl: "
if [ -v libcurl ]; then
    if [ -e "$libcurl_libpath" ]; then
        libcurl_found=1
        libcurl_link="-lcurl"
        constants+=" -D COMPILE_LIBCURL=1"
        echo "ON"
    else
        echo "requested but lib not found, aborting."
        exit 1
    fi
else
    echo "OFF"
    constants+=" -D COMPILE_LIBCURL=0"
fi

echo $separator

mkdir -p ../bin
mkdir -p objects

echo "##### COMPILE CRACKING.CPP    #####"
$cc $debug $options $constants -c cracking.cpp -o objects/cracking.opp

echo "##### COMPILE GSC.CPP         #####"
$cc $debug $options $constants -c gsc.cpp -o objects/gsc.opp

echo "##### COMPILE GSC_ENTITY.CPP  #####"
$cc $debug $options $constants -c gsc_entity.cpp -o objects/gsc_entity.opp

echo "##### COMPILE GSC_EXEC.CPP    #####"
$cc $debug $options $constants -c gsc_exec.cpp -o objects/gsc_exec.opp

if [ $sqlite_found == 1 ]; then
    echo "##### COMPILE GSC_SQLITE.CPP #####"
    $cc $debug $options $constants -c gsc_sqlite.cpp -o objects/gsc_sqlite.opp
fi

echo "##### COMPILE GSC_PLAYER.CPP  #####"
$cc $debug $options $constants -c gsc_player.cpp -o objects/gsc_player.opp

echo "##### COMPILE GSC_UTILS.CPP   #####"
$cc $debug $options $constants -c gsc_utils.cpp -o objects/gsc_utils.opp

echo "##### COMPILE JUMP.CPP        #####"
$cc $debug $options $constants -c jump.cpp -o objects/jump.opp

echo "##### COMPILE GSC_WEAPONS.CPP #####"
$cc $debug $options $constants -c gsc_weapons.cpp -o objects/gsc_weapons.opp

echo "##### COMPILE LIBCOD.CPP      #####"
$cc $debug $options $constants -c libcod.cpp -o objects/libcod.opp

echo "##### COMPILE QVSNPRINTF.C    #####"
$cc $debug $options $constants -c vendor/qvsnprintf.c -o objects/qvsnprintf.opp

if [ $libcurl_found == 1 ]; then
    echo "##### COMPILE GSC_CURL.CPP #####"
    $cc $debug $options $constants -c gsc_curl.cpp -o objects/gsc_curl.opp
fi

echo "##### LINK    libcod1.so      #####"
objects="$(ls objects/*.opp)"
$cc -m32 -shared -L/lib32 -o ../bin/libcod1.so -ldl $objects -lpthread $sqlite_link $libcurl_link
rm objects -r
