#!/bin/bash

# google cloud speech to text implemented with processing front end
# (google cloud services account free 365-day trial)
# https://cloud.google.com/speech-to-text/docs/
# gc project earwitness-speech-to-text, gc bucket earwitness-speech-to-text
# authentication key as bash environment variable
#
# To get started make sure that ffmpeg is installed, and then follow this tutorial
# to set up a google speech-to-text environment:
# https://cloud.google.com/speech-to-text/docs/quickstart-protocol
#
# Replace this line with the link to your downloaded json auth credentials
# KEY=[YOUR KEY JSON HERE]

# Also in the same GCP project, set up a Cloud Storage bucket. Replace this line
# BUCKET=gs://[YOUR BUCKET HERE]
#
# Usage
# ./earwitness.sh -i path-to-file.mp3
#

KEY=/Users/eric/dev/kings-auth/kings-212617-06ed0601c807.json
#KEY=/Users/reinfurt/Documents/Projects/KINGS/software/google-cloud-platform/json/auth/kings-speech-to--1532733222205-b656714f6407.json
BUCKET=gs://kings-speech-to-text-2
#BUCKET=gs://kings-speech-to-text

IN=data/speech.wav

while [ "$1" != "" ]; do
    case $1 in
        -i | --in )		    shift
                                IN=$1;;
        -k | --key )		shift
                                KEY=$1;;
        -h | --help )           echo -e "\
Usage: earwitness [OPTION]... [FILE]...
Submit google cloud speech-to-text recognize request, returns .json. \
Run earwitness.pde using returned speech.wav & txt.json. \
Input audio files can be any format that ffmpeg can handle.

  -i, --in              input file [unused?]
  -k, --key		        path/to/ gcloud authentication .json
"
        exit;;
    esac
    shift
done

filename=$(basename -- "$IN")
extension="${filename##*.}"
filename="${filename%.*}"

# output files
OUT=data/$filename.wav
JSON=data/$filename.json

TMP=data/speech-16k.wav

#
#   0.  authenticate
#

echo "authenticate ..."

gcloud auth activate-service-account --key-file=$KEY
export GOOGLE_APPLICATION_CREDENTIALS=$KEY

#
#   1.  process audio (ffmpeg) to gcloud speech-to-text format
#       .wav (PCM linear16 encoding) mono 16k
#       .flac (format & encoding) mono 16k
#       output 16k for gcloud recognize ($TMP)
#       and 44.1k for processing ($OUT)
#

echo "process audio ..."

#   which method is more accurate, faster?
#   process each separate

ffmpeg -i $IN -acodec pcm_s16le -ac 1 -ar 16000 $TMP
ffmpeg -i $IN -acodec pcm_s16le -ac 1 -ar 44100 $OUT

# ffmpeg -i $IN -acodec pcm_s16le -ac 1 -ar 44100 $OUT
# ffmpeg -i $OUT -ar 16000 $TMP

#
#   2.  upload audio to gc bucket
#
#   include commandline flag for long-running

gsutil cp $TMP $BUCKET

rm $TMP

#
#   3.  gcloud speech recognize, return data/txt.json
#

echo "gcloud recognize ..."

# gcloud ml speech recognize $TMP --include-word-time-offsets --language-code='en-US' --hints=paced > $JSON
# gcloud ml speech recognize-long-running '$BUCKET/$TMP' --include-word-time-offsets --language-code='en-US' > $JSON
#gcloud ml speech recognize-long-running 'gs://kings-speech-to-text-2/speech-16k.wav' --include-word-time-offsets --language-code='en-US' > $JSON

# https://gist.github.com/cjus/1047794
function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

# submit job
# https://cloud.google.com/speech-to-text/docs/reference/rest/v1p1beta1/RecognitionConfig
NAME=$(curl -sS -H "Content-Type: application/json" \
    -H "Authorization: Bearer "$(gcloud auth print-access-token) \
    https://speech.googleapis.com/v1p1beta1/speech:longrunningrecognize \
    --data '{
  "config": {
    "languageCode": "en-US",
    "enableWordTimeOffsets": true,
    "enableAutomaticPunctuation": true,
    "useEnhanced": true,
    "model": "video",
    "speechContexts":{
        "phrases": [""]
    },
    "metadata": {
      "interactionType": "PRESENTATION",
      "audioTopic": ""
    }
  },
  "audio": {
    "uri":"'$BUCKET'/speech-16k.wav"
  }
}' | jsonValue name)

NAME=$(echo $NAME)

echo "submit job with id "$NAME" ..."

# keep polling every 2 seconds to see if job done
RESPONSE=""
OUTPUT=""
RESPONSELENGTH="$(echo $RESPONSE | wc -w | tr -d ' ')"
while [ $RESPONSELENGTH -lt 1 ]
do
  OUTPUT=$(curl -sS -H "Content-Type: application/json" \
      -H "Authorization: Bearer "$(gcloud auth print-access-token) \
    https://speech.googleapis.com/v1/operations/$NAME)
  RESPONSE=$(echo ${OUTPUT} | jsonValue response)
  RESPONSELENGTH="$(echo $RESPONSE | wc -w | tr -d ' ')"
  echo "wait ..."
  sleep 2
done

# get the output
echo 'received translation ...'
echo $OUTPUT > $JSON

#
# pre process the json!
#

echo 'preprocess translation ...'
python preprocess.py $JSON

#
#   4.  run .pde using data/txt.json and data/speech.wav
#       (processing wants data/speech.wav to be 44.1k)
#       ** unimplemented **
#

echo "launch processing ..."

pjava .

echo "** done **"
