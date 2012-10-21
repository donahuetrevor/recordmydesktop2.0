#!/bin/bash -e

usage() {
cat $(readlink -f $(dirname $0))/README.md
}

codec="utvideo"
verbose="-loglevel quiet"
while getopts "o:d:vhu:c:" o
do
	case "$o" in
	(u) dest="$OPTARG";;
	(d) duration="-t $OPTARG";;
	(v) verbose="";;
	(\?) echo "Invalid option: -$OPTARG" >&2 ;;
	(h) usage; exit;;
	(*) break;;
	esac
done
shift $((OPTIND - 1))
today=$(date --iso-8601=date)
mkdir $today || true
out=$today/${1:-out.webm}
if test "${out##*.}" != "webm"; then out=$out.webm; fi

temp=$(mktemp -u "/tmp/$0.XXXX.mkv")
temp2=$(mktemp  -u "/tmp/$0.XXXX.mkv")
echo Temp files: $temp $temp2
trap "rm -f $temp $temp2; exit" EXIT

res=$(xdpyinfo | grep 'dimensions:'|awk '{print $2}')
echo $0: Capturing $res to $out.

ffmpeg $duration -f x11grab -s $res -r 30 -i :0.0 -f alsa -i hw:0,0 -acodec flac -vcodec ffvhuff $temp
ffmpeg -i $temp -acodec libvorbis $temp2
ffmpeg -i $temp2 -acodec copy -vcodec libvpx $out

# Generate HTML source
echo "<video controls src=$out></video>" > $out.html

if test "$dest"
then
	rsync -r --progress --remove-source-files $today $dest
	echo -e "\n\n\tSHARE: http://$(basename $dest)/$out.html\n"
fi
