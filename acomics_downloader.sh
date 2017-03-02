#!/bin/sh
# CONFIGURATION SECTION:
AGE="17" # Age for accessing age-restricted pages
ACOMICS="https://acomics.ru" # Base domain of acomics.ru - use http if https is not supported on your system
# END OF CONFIGURATION SECTION

usage() {
	echo "Acomics downloader - grab web comics from Acomics.ru"
	echo "Usage: $0 {comics_name} [page_number] [page_number]..."
	echo "comics_name: Name of the comics (for example, if comics page is https://acomics.ru/~erma - you should pass 'erma' as comics_name"
	echo "page_number: Download specified pages (in case broken pages is present after full series download)"
	echo
	echo "If comics_name/ directory is already present - script will try to resume download from the last downloaded page"
	echo "This is useful for downloading recently uploaded files to keep your collection up-to-date"
	exit
}

# Download single comics_name page page_number to current directory
download_single_page() {
	comics_name="$1"
	page_number="$2"
	image_url="$(curl --cookie ageRestrict="$AGE" --location "$ACOMICS/~$comics_name/$page_number" 2>/dev/null |tr '\"' '\n'|grep 'upload/!c/'|head -n 1)"
	# Workaround for acomics.ru: it returns last page if requested page is not exist, so we need to track image URLs to catch this and handle it
	if [ q"$image_url" != q"$last_image_url" ]; then
		last_image_url="$image_url"
		filename="$(printf "%06d" "$page_number")_$(basename "$image_url")"
		echo "Downloading page $page_number from '$image_url' to '$filename'"
		# This wget call is async to make things faster. But may be sync too, so try to remove & in case of issues
		wget "$ACOMICS/$image_url" -c -O "$filename"&
	else
		echo "All pages downloaded"
		exit
	fi
}

if [ $# -lt 1 ]; then
	usage
fi

name="$1"
mkdir -p "$name"
cd "$name" || exit 1
[ -f "$name.url" ] && last_image_url=$(cat "$name.url")

# Pages loop
if [ q"$2" != q ]; then
	while [ q"$2" != q ]; do
		# Iterate all page_numbers from cmdline
		download_single_page "$name" "$2"
		shift
	done
	exit
fi

# Get last downloaded page and fallback to 1st page if unknown
[ -f "$name.page" ] && page=$(cat "$name.page")
if [ q"$page" = q ]; then
	page="1"
fi

# Main loop
while true; do
	download_single_page "$name" "$page"
	echo "$page" > "$name.page"
	echo "$image_url" > "$name.url"
	page="$((page+1))"
done
