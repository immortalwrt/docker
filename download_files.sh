#!/bin/bash
# Copyright (C) 2021 ImmortalWrt.org

DOWNLOAD_URL="https://downloads.immortalwrt.org"
if [ "$VERSION" == "snapshot" ]; then
	DOWNLOAD_PATH="snapshots"
else
	DOWNLOAD_PATH="releases/${VERSION#openwrt-}"
fi
DOWNLOAD_PATH+="/targets/$(echo "$TARGET" | tr "-" "/")"

function verify_shasum(){
	[ -n "$1" ] || exit 1
	curl -fsSL "$DOWNLOAD_URL/$DOWNLOAD_PATH/sha256sums" | grep "$1" > "$1.sha256sums"
	LOCAL_HASH="$(sha256sum $1 | awk '{print $1}')"
	REMOTE_HASH="$(awk '{print $1}' "$1.sha256sums")"
	if [ "$LOCAL_HASH" == "$REMOTE_HASH" ]; then
		echo -e "sha256sums checked."
		cat "$1.sha256sums"
	else
		echo -e "sha256sums mismatch!"
		echo -e "Expected: $REMOTE_HASH, got $LOCAL_HASH."
		rm -f "$1" "$1.sha256sums"
		exit 1
	fi
}

case "$1" in
"ib")
	IB_NAME="$(curl -fsSL "$DOWNLOAD_URL/$DOWNLOAD_PATH/sha256sums" | grep -E "imagebuilder-(.*)${TARGET%-*}" | cut -d "*" -f 2)"
	curl -fLO "$DOWNLOAD_URL/$DOWNLOAD_PATH/$IB_NAME"
	verify_shasum "$IB_NAME"
	mkdir -p "ib"
	tar -vxf "$IB_NAME" -C "ib"/ --strip-components 1
	;;
"rootfs")
	ROOTFS_NAME="$(curl -fsSL "$DOWNLOAD_URL/$DOWNLOAD_PATH/sha256sums" | grep "\-rootfs.tar.gz" | cut -d "*" -f 2)"
	curl -fLO "$DOWNLOAD_URL/$DOWNLOAD_PATH/$ROOTFS_NAME"
	verify_shasum "$ROOTFS_NAME"
	mkdir -p "rootfs"
	tar -vxf "$ROOTFS_NAME" -C "rootfs"/ --strip-components 1
	cp -fpR "rootfs_extra"/* "rootfs"/
	;;
"sdk")
	SDK_NAME="$(curl -fsSL "$DOWNLOAD_URL/$DOWNLOAD_PATH/sha256sums" | grep -E "sdk-(.*)${TARGET%-*}" | cut -d "*" -f 2)"
	curl -fLO "$DOWNLOAD_URL/$DOWNLOAD_PATH/$SDK_NAME"
	verify_shasum "$SDK_NAME"
	mkdir -p "sdk"
	tar -vxf "$SDK_NAME" -C "sdk"/ --strip-components 1
	;;
*)
	echo -e "Usage: $0 <ib|rootfs|sdk>"
	exit 2
esac
