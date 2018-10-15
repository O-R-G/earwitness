import sys
import json

with open(sys.argv[1]) as f:
    data = json.load(f)

results = data["response"]["results"]

for result in results:
    words = result["alternatives"][0]["words"]
    for word in words:

        # is the beginning of a term?
        word["term"] = False

        # is part of a term? (including beginning and end of a term)
        word["term-component"] = False

        #is end of a line (paragraph break)
        word["paragraph"] = False

with open(sys.argv[1], 'w') as outfile:
    json.dump(data, outfile, sort_keys = True, indent = 4, ensure_ascii = False)
