#!/usr/bin/env bash
# Runs a book build with its remote images served from localhost.
#
# mdbook-epub downloads remote images itself: one request, a generic User-Agent,
# no retry, and any error fails the whole book. Image hosts such as Wikimedia
# answer CI runners with 429. So fetch the images here first (identified, with
# retries), serve them from 127.0.0.1 for the duration of the build, and point
# the chapters there. mdbook-epub still embeds them through its usual remote
# image path, which already handles {{#include}}d files and nested chapters.
# An image that still can't be fetched becomes a plain link: a book without one
# picture beats no book.
#
# Usage: with-cached-images.sh <book src dir> <command> [args...]
set -euo pipefail

src_dir=$1
shift
user_agent="rust-ebooks/1.0 (https://github.com/Artur-Sulej/rust-ebooks)"

# Same image syntax mdbook-epub collects: Markdown ![alt](url) and HTML <img src="url">.
# Mode "list" prints remote image URLs. Mode "rewrite" reads "url<TAB>new url"
# lines (empty new url: download failed) and edits the file in place.
# Fenced code blocks are left alone, they are not images.
images_pl='
use strict; use warnings;
my ($mode, $file, $map_file) = @ARGV;
my %map;
if ($mode eq "rewrite") {
  open my $m, "<", $map_file or die "$map_file: $!";
  while (<$m>) { chomp; my ($url, $new) = split /\t/, $_, 2; $map{$url} = $new // "" }
}
# Markdown URLs may hold one level of balanced parentheses, e.g. Wikimedia "File_(1).png".
my $md_url = qr{https?://(?:[^\s()<>]|\([^\s()<>]*\))+};
my $html_url = qr{https?://[^\s"\x27<>]+};

sub fix_img {
  my ($tag) = @_;
  return $tag unless $tag =~ /\bsrc\s*=\s*(["\x27])($html_url)\1/ && exists $map{$2};
  my $url = $2;
  if ($map{$url} ne "") { $tag =~ s/\Q$url\E/$map{$url}/; return $tag }
  my ($alt) = $tag =~ /\balt\s*=\s*(["\x27])(.*?)\1/ ? ($2) : ("image");
  return qq{<a href="$url">$alt</a>};
}

sub process {
  my ($chunk) = @_;
  if ($mode eq "list") {
    print "$1\n" while $chunk =~ /!\[[^\]]*\]\(\s*<?($md_url)/g;
    print "$1\n" while $chunk =~ /<img\b[^>]*?\bsrc\s*=\s*["\x27]($html_url)/gi;
    return $chunk;
  }
  $chunk =~ s{!(\[[^\]]*\]\(\s*<?)($md_url)}{
    !exists $map{$2} ? "!$1$2" : $map{$2} ne "" ? "!$1$map{$2}" : "$1$2"
  }ge;
  $chunk =~ s{(<img\b[^>]*>)}{fix_img($1)}gie;
  return $chunk;
}

open my $in, "<", $file or die "$file: $!";
my ($out, $chunk, $fence) = ("", "", undef);
while (my $line = <$in>) {
  if (defined $fence) {
    $out .= $line;
    undef $fence if $line =~ /^\s*(`{3,}|~{3,})\s*$/
      && substr($1, 0, 1) eq substr($fence, 0, 1) && length $1 >= length $fence;
  } elsif ($line =~ /^\s*(`{3,}|~{3,})/) {
    $fence = $1;
    $out .= process($chunk) . $line;
    $chunk = "";
  } else {
    $chunk .= $line;
  }
}
$out .= process($chunk);
close $in;
if ($mode eq "rewrite") { open my $o, ">", $file or die "$file: $!"; print $o $out }
'

# Picks a file extension from the URL, or from the Content-Type for URLs without
# one. mdbook-epub needs it: it names cached images after the URL's extension.
image_extension() {
  local url_path=${1%%[?#]*} content_type=$2
  shopt -s nocasematch
  if [[ $url_path =~ \.(png|jpe?g|gif|svg|webp|bmp)$ ]]; then
    echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]'
  else
    case $content_type in
      image/png*) echo png ;;
      image/jpeg*) echo jpg ;;
      image/gif*) echo gif ;;
      image/svg+xml*) echo svg ;;
      image/webp*) echo webp ;;
      image/bmp*) echo bmp ;;
      *) return 1 ;;
    esac
  fi
}

cache_dir=$(mktemp -d)
server_pid=""
cleanup() {
  [ -n "$server_pid" ] && kill "$server_pid" 2> /dev/null
  rm -rf "$cache_dir"
}
trap cleanup EXIT

mapfile -d '' md_files < <(find "$src_dir" -type f -name '*.md' -print0)
urls=$(for md in "${md_files[@]}"; do perl -e "$images_pl" list "$md"; done | sort -u)

if [ -n "$urls" ]; then
  # Port 0 lets the OS pick a free port; the server prints which one.
  mkdir -p "$cache_dir/files"
  python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$cache_dir/files" \
    > "$cache_dir/server.out" 2> /dev/null &
  server_pid=$!
  port=""
  for _ in $(seq 50); do
    port=$(sed -n 's/^Serving HTTP on .* port \([0-9]*\) .*/\1/p' "$cache_dir/server.out")
    [ -n "$port" ] && break
    sleep 0.1
  done
  [ -n "$port" ] || { echo "Local image server did not start" >&2; exit 1; }

  map_file="$cache_dir/map.tsv"
  while IFS= read -r url; do
    new_url=""
    tmp="$cache_dir/download.tmp"
    if content_type=$(curl -fsSL --retry 6 --retry-max-time 180 --connect-timeout 20 --max-time 60 \
          -A "$user_agent" -o "$tmp" -w '%{content_type}' "$url") \
        && [[ $content_type == image/* ]] \
        && ext=$(image_extension "$url" "$content_type"); then
      name="$(printf '%s' "$url" | shasum | cut -c1-12).$ext"
      mv "$tmp" "$cache_dir/files/$name"
      new_url="http://127.0.0.1:$port/$name"
      echo "Cached image $url"
    else
      rm -f "$tmp"
      echo "Could not fetch image $url (content type: ${content_type:-none}), linking to it instead"
    fi
    printf '%s\t%s\n' "$url" "$new_url" >> "$map_file"
  done <<< "$urls"

  for md in "${md_files[@]}"; do
    perl -e "$images_pl" rewrite "$md" "$map_file"
  done
fi

"$@"
