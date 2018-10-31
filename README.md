Earwitness
===

This repository contains the code for [Earwitness Theatre](https://chisenhale.org.uk/exhibition/lawrence-abu-hamdan/), 
created for Lawrence Abu Hamdan by O-R-G.

The code contains a shell script `earwitness.sh`, which uploads audio files to Google Cloud Platform (GCP) and receives 
transcriptions back, some helper python scripts `preprocess.py` and `pjava` which run some JSON postprocessing and
Processing set up respectively, and finally `earwitness.pde` and `Word.pde` which form the Processing script which
run the animation.

To get set up, first follow the GCP tutorial for Speech-to-text [here](https://cloud.google.com/speech-to-text/docs/quickstart-protocol).
Once you have an authorized key (.json output), as well as a GCP bucket set up, you're ready to go. Make sure to change the
values in `earwitness.sh`. It's a good idea to test with a small audio snippet (< 10 seconds) before moving on to 
larger transcriptions.

Requirements
---
You will need to install [ffmpeg](https://www.ffmpeg.org/), [gcloud](https://cloud.google.com/sdk/docs/), and [Processing](https://processing.org/).
You will also need to install the Minim library from the Processing package manager.

Basic Usage
---
1. Place a recording in the `data` folder. It should be in the .mp3, .wav, or other format and have no spaces.
2. Run the shell script `./earwitness.sh`. Depending on the recording length, this will take anywhere from a half a minute to
15-20 minutes to run. The script will convert the recording to .wav, upload to GCP, send a request for transcription, 
download the transcription, preprocess the JSON, and finally open the aimation in Processing.
3. At this point, the animation will not work the way we want to. It will also likely have a bunch of spelling and
transcription errors. Open up the `.json` file in the `data` folder. Each word contains several fields 
```
 {
   "endTime": "1.900s", <- When the word stops being spoken in the recording
   "paragraph": false, <- If the word is the end of a paragraph and needs break
   "startTime": "1s", <- When the word beings to be spoken in the recording
   "term": false, <- If the word is the beginning of a term
   "term-component": false, <- If the word is part of a term (incl beginning or end)
   "word": "Therefore" <- The word itself
 }
```
The `data/earwitness full` and `data/earwitness short` folders offer good examples of processed files. To try these out, place `.wav` and `.json` files in the `data` folder. 
4. After you finish post processing, run `pjava .` in the root folder. This will open the Processing animation. 

Repeat steps 3 and 4 until you get to the desired output.

Processing Animation
---
The processing sketch can be run by calling `pjava .` in the root folder. Its behavior is heavily customizable and all the code
has been documented in quite some detail. To create a recording of the screen, use Quicktime or a similar screen recording
software. To optimize for the screen, it's best to uncomment  `pixelDensity(displayDensity());` to get a better resolution
output, but this will likely mess up PDF output. The sketch will automatically generate PDFs of each individual page in `out`.

Contact
---
Contact [eric [at] o-r-g.com](mailto:eric@o-r-g.com) for questions.

