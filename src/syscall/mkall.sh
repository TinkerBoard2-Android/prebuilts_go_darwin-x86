#!/usr/bin/env bash
# Copyright 2009 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# The syscall package provides access to the raw system call
# interface of the underlying operating system.  Porting Go to
# a new architecture/operating system combination requires
# some manual effort, though there are tools that automate
# much of the process.  The auto-generated files have names
# beginning with z.
#
# This script runs or (given -n) prints suggested commands to generate z files
# for the current system.  Running those commands is not automatic.
# This script is documentation more than anything else.
#
# * asm_${GOOS}_${GOARCH}.s
#
# This hand-written assembly file implements system call dispatch.
# There are three entry points:
#
# 	func Syscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr);
# 	func Syscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr);
# 	func RawSyscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr);
#
# The first and second are the standard ones; they differ only in
# how many arguments can be passed to the kernel.
# The third is for low-level use by the ForkExec wrapper;
# unlike the first two, it does not call into the scheduler to
# let it know that a system call is running.
#
# * syscall_${GOOS}.go
#
# This hand-written Go file implements system calls that need
# special handling and lists "//sys" comments giving prototypes
# for ones that can be auto-generated.  Mksyscall reads those
# comments to generate the stubs.
#
# * syscall_${GOOS}_${GOARCH}.go
#
# Same as syscall_${GOOS}.go except that it contains code specific
# to ${GOOS} on one particular architecture.
#
# * types_${GOOS}.c
#
# This hand-written C file includes standard C headers and then
# creates typedef or enum names beginning with a dollar sign
# (use of $ in variable names is a gcc extension).  The hardest
# part about preparing this file is figuring out which headers to
# include and which symbols need to be #defined to get the
# actual data structures that pass through to the kernel system calls.
# Some C libraries present alternate versions for binary compatibility
# and translate them on the way in and out of system calls, but
# there is almost always a #define that can get the real ones.
# See types_darwin.c and types_linux.c for examples.
#
# * zerror_${GOOS}_${GOARCH}.go
#
# This machine-generated file defines the system's error numbers,
# error strings, and signal numbers.  The generator is "mkerrors.sh".
# Usually no arguments are needed, but mkerrors.sh will pass its
# arguments on to godefs.
#
# * zsyscall_${GOOS}_${GOARCH}.go
#
# Generated by mksyscall.pl; see syscall_${GOOS}.go above.
#
# * zsysnum_${GOOS}_${GOARCH}.go
#
# Generated by mksysnum_${GOOS}.
#
# * ztypes_${GOOS}_${GOARCH}.go
#
# Generated by godefs; see types_${GOOS}.c above.

GOOSARCH="${GOOS}_${GOARCH}"

# defaults
mksyscall="./mksyscall.pl"
mkerrors="./mkerrors.sh"
zerrors="zerrors_$GOOSARCH.go"
mksysctl=""
zsysctl="zsysctl_$GOOSARCH.go"
mksysnum=
mktypes=
mkasm=
run="sh"

case "$1" in
-syscalls)
	for i in zsyscall*go
	do
		# Run the command line that appears in the first line
		# of the generated file to regenerate it.
		sed 1q $i | sed 's;^// ;;' | sh > _$i && gofmt < _$i > $i
		rm _$i
	done
	exit 0
	;;
-n)
	run="cat"
	shift
esac

case "$#" in
0)
	;;
*)
	echo 'usage: mkall.sh [-n]' 1>&2
	exit 2
esac

GOOSARCH_in=syscall_$GOOSARCH.go
case "$GOOSARCH" in
_* | *_ | _)
	echo 'undefined $GOOS_$GOARCH:' "$GOOSARCH" 1>&2
	exit 1
	;;
aix_ppc64)
	mkerrors="$mkerrors -maix64"
	mksyscall="./mksyscall_libc.pl -aix"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
darwin_386)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32 -darwin"
	mksysnum="./mksysnum_darwin.pl /usr/include/sys/syscall.h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	mkasm="go run mkasm_darwin.go"
	;;
darwin_amd64)
	mkerrors="$mkerrors -m64"
	mksyscall="./mksyscall.pl -darwin"
	mksysnum="./mksysnum_darwin.pl /usr/include/sys/syscall.h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	mkasm="go run mkasm_darwin.go"
	;;
darwin_arm64)
	mkerrors="$mkerrors -m64"
	mksyscall="./mksyscall.pl -darwin"
	mksysnum="./mksysnum_darwin.pl /usr/include/sys/syscall.h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	mkasm="go run mkasm_darwin.go"
	;;
darwin_arm)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32 -darwin"
	mksysnum="./mksysnum_darwin.pl /usr/include/sys/syscall.h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	mkasm="go run mkasm_darwin.go"
	;;
dragonfly_amd64)
	mkerrors="$mkerrors -m64"
	mksyscall="./mksyscall.pl -dragonfly"
	mksysnum="curl -s 'http://gitweb.dragonflybsd.org/dragonfly.git/blob_plain/HEAD:/sys/kern/syscalls.master' | ./mksysnum_dragonfly.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
freebsd_386)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32"
	mksysnum="curl -s 'http://svn.freebsd.org/base/stable/10/sys/kern/syscalls.master' | ./mksysnum_freebsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
freebsd_amd64)
	mkerrors="$mkerrors -m64"
	mksysnum="curl -s 'http://svn.freebsd.org/base/stable/10/sys/kern/syscalls.master' | ./mksysnum_freebsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
freebsd_arm)
	mkerrors="$mkerrors"
	mksyscall="./mksyscall.pl -l32 -arm"
	mksysnum="curl -s 'http://svn.freebsd.org/base/stable/10/sys/kern/syscalls.master' | ./mksysnum_freebsd.pl"
	# Let the type of C char be signed to make the bare syscall
	# API consistent between platforms.
	mktypes="GOARCH=$GOARCH go tool cgo -godefs -- -fsigned-char"
	;;
linux_386)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32"
	mksysnum="./mksysnum_linux.pl /usr/include/asm/unistd_32.h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_amd64)
	unistd_h=$(ls -1 /usr/include/asm/unistd_64.h /usr/include/x86_64-linux-gnu/asm/unistd_64.h 2>/dev/null | head -1)
	if [ "$unistd_h" = "" ]; then
		echo >&2 cannot find unistd_64.h
		exit 1
	fi
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_arm)
	mkerrors="$mkerrors"
	mksyscall="./mksyscall.pl -l32 -arm"
	mksysnum="curl -s 'http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/arch/arm/include/uapi/asm/unistd.h' | ./mksysnum_linux.pl -"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_arm64)
	unistd_h=$(ls -1 /usr/include/asm/unistd.h /usr/include/asm-generic/unistd.h 2>/dev/null | head -1)
	if [ "$unistd_h" = "" ]; then
		echo >&2 cannot find unistd_64.h
		exit 1
	fi
	mksysnum="./mksysnum_linux.pl $unistd_h"
	# Let the type of C char be signed to make the bare syscall
	# API consistent between platforms.
	mktypes="GOARCH=$GOARCH go tool cgo -godefs -- -fsigned-char"
	;;
linux_mips)
	GOOSARCH_in=syscall_linux_mipsx.go
	unistd_h=/usr/include/asm/unistd.h
	mksyscall="./mksyscall.pl -b32 -arm"
	mkerrors="$mkerrors"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_mipsle)
	GOOSARCH_in=syscall_linux_mipsx.go
	unistd_h=/usr/include/asm/unistd.h
	mksyscall="./mksyscall.pl -l32 -arm"
	mkerrors="$mkerrors"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_mips64)
	GOOSARCH_in=syscall_linux_mips64x.go
	unistd_h=/usr/include/asm/unistd.h
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_mips64le)
	GOOSARCH_in=syscall_linux_mips64x.go
	unistd_h=/usr/include/asm/unistd.h
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_ppc64)
	GOOSARCH_in=syscall_linux_ppc64x.go
	unistd_h=/usr/include/asm/unistd.h
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_ppc64le)
	GOOSARCH_in=syscall_linux_ppc64x.go
	unistd_h=/usr/include/powerpc64le-linux-gnu/asm/unistd.h
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
linux_s390x)
	GOOSARCH_in=syscall_linux_s390x.go
	unistd_h=/usr/include/asm/unistd.h
	mkerrors="$mkerrors -m64"
	mksysnum="./mksysnum_linux.pl $unistd_h"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
nacl_386)
	mkerrors=""
	mksyscall="./mksyscall.pl -l32 -nacl"
	mksysnum=""
	mktypes=""
	;;
nacl_amd64p32)
	mkerrors=""
	mksyscall="./mksyscall.pl -nacl"
	mksysnum=""
	mktypes=""
	;;
netbsd_386)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32 -netbsd"
	mksysnum="curl -s 'http://cvsweb.netbsd.org/bsdweb.cgi/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_netbsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
netbsd_amd64)
	mkerrors="$mkerrors -m64"
	mksyscall="./mksyscall.pl -netbsd"
	mksysnum="curl -s 'http://cvsweb.netbsd.org/bsdweb.cgi/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_netbsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
netbsd_arm)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32 -netbsd -arm"
	mksysnum="curl -s 'http://cvsweb.netbsd.org/bsdweb.cgi/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_netbsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
openbsd_386)
	mkerrors="$mkerrors -m32"
	mksyscall="./mksyscall.pl -l32 -openbsd"
	mksysctl="./mksysctl_openbsd.pl"
	zsysctl="zsysctl_openbsd.go"
	mksysnum="curl -s 'http://cvsweb.openbsd.org/cgi-bin/cvsweb/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_openbsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
openbsd_amd64)
	mkerrors="$mkerrors -m64"
	mksyscall="./mksyscall.pl -openbsd"
	mksysctl="./mksysctl_openbsd.pl"
	zsysctl="zsysctl_openbsd.go"
	mksysnum="curl -s 'http://cvsweb.openbsd.org/cgi-bin/cvsweb/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_openbsd.pl"
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
openbsd_arm)
	mkerrors="$mkerrors"
	mksyscall="./mksyscall.pl -l32 -openbsd -arm"
	mksysctl="./mksysctl_openbsd.pl"
	zsysctl="zsysctl_openbsd.go"
	mksysnum="curl -s 'http://cvsweb.openbsd.org/cgi-bin/cvsweb/~checkout~/src/sys/kern/syscalls.master' | ./mksysnum_openbsd.pl"
	# Let the type of C char be signed to make the bare syscall
	# API consistent between platforms.
	mktypes="GOARCH=$GOARCH go tool cgo -godefs -- -fsigned-char"
	;;
plan9_386)
	mkerrors=
	mksyscall="./mksyscall.pl -l32 -plan9"
	mksysnum="./mksysnum_plan9.sh /n/sources/plan9/sys/src/libc/9syscall/sys.h"
	mktypes="XXX"
	;;
solaris_amd64)
	mksyscall="./mksyscall_libc.pl -solaris"
	mkerrors="$mkerrors -m64"
	mksysnum=
	mktypes="GOARCH=$GOARCH go tool cgo -godefs"
	;;
windows_*)
	echo 'run "go generate" instead' 1>&2
	exit 1
	;;
*)
	echo 'unrecognized $GOOS_$GOARCH: ' "$GOOSARCH" 1>&2
	exit 1
	;;
esac

(
	if [ -n "$mkerrors" ]; then echo "$mkerrors |gofmt >$zerrors"; fi
	syscall_goos="syscall_$GOOS.go"
 	case "$GOOS" in
	darwin | dragonfly | freebsd | netbsd | openbsd)
		syscall_goos="syscall_bsd.go $syscall_goos"
 		;;
 	esac
	if [ -n "$mksyscall" ]; then echo "$mksyscall -tags $GOOS,$GOARCH $syscall_goos $GOOSARCH_in |gofmt >zsyscall_$GOOSARCH.go"; fi
	if [ -n "$mksysctl" ]; then echo "$mksysctl |gofmt >$zsysctl"; fi
	if [ -n "$mksysnum" ]; then echo "$mksysnum |gofmt >zsysnum_$GOOSARCH.go"; fi
	if [ -n "$mktypes" ]; then
		# ztypes_$GOOSARCH.go could be erased before "go run mkpost.go" is called.
		# Therefore, "go run" tries to recompile syscall package but ztypes is empty and it fails.
		echo "$mktypes types_$GOOS.go |go run mkpost.go >ztypes_$GOOSARCH.go.NEW && mv ztypes_$GOOSARCH.go.NEW ztypes_$GOOSARCH.go";
	fi
	if [ -n "$mkasm" ]; then echo "$mkasm $GOARCH"; fi
) | $run
