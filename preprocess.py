# This script preprocesses raw JSON input from the Google Speech-To-Text API:
# https://cloud.google.com/speech-to-text/docs/reference/rest/v1p1beta1/speech/recognize
#
# The output is a prettified JSON with additional fields required by the
# Earwitness speech to text software.
#
# After preprocessing, a word entry will look like:
# {
#   "endTime": "1.900s", <- When the word stops being spoken in the recording
#   "paragraph": false, <- If the word is the end of a paragraph and needs break
#   "startTime": "1s", <- When the word beings to be spoken in the recording
#   "term": false, <- If the word is the beginning of a term
#   "term-component": false, <- If the word is part of a term (incl beginning or end)
#   "word": "Therefore" <- The word itself
# }
#
# A term is defined as a vocabulary term. If a term is only a single word, then
# "term", "term-component", and "paragraph" are all true for that entry. Any word
# of a term must have "term-component" be true, while the beginning word of the
# term must have "term" be true and the last word must have "paragraph" be true.
#
# A few more examples:
#
# "Cricket Bat"
#   Cricket
#       term: true
#       term-component: true
#       paragraph: false
#
#   Bat
#       term: false
#       term-component: true
#       paragraph: true
#
# "Banana"
#   Banana
#       term: true
#       term-component: true
#       paragraph: true
#
# Usage:
# python preprocess.py $PATH-TO-JSON

import sys
import json

# load in JSON
with open(sys.argv[1]) as f:
    data = json.load(f)

results = data["response"]["results"]

# iterate through words and add fields
for result in results:
    words = result["alternatives"][0]["words"]
    for word in words:

        # is the beginning of a term?
        word["term"] = False

        # is part of a term? (including beginning and end of a term)
        word["term-component"] = False

        #is end of a line (paragraph break)
        word["paragraph"] = False

# output and overwrite same file
with open(sys.argv[1], 'w') as outfile:
    json.dump(data, outfile, sort_keys = True, indent = 4, ensure_ascii = False)
