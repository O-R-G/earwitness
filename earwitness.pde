/**
 * Earwitness
 *
 * speech to text transcription using google cloud api
 * to visually animate the typesetting of spoken language
 * and translate the cadence into visual / dynamic form
 *
 * uses Minim sound processing library for audio analysis
 * and processing.pdf for output
 * uses Speech-to-text-normal as base
 *
 * typesets terms and definitions in alphabetical order, keeping track
 * of the current character, as well as displaying various visual cues.
 *
 * press space to begin playback. will also output pdfs of each page to the 'out'
 * folder. takes as input a .json and its corresponding .wav file in the 'data' folder.
 *
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import processing.pdf.*;

Minim minim;                      // Minim audio processing class
AudioPlayer sample;               // Audio player for playing the recording
FFT fft;                          // Class for FFT audio analysis

JSONObject json;                 // Reads in processed JSON from google cloud output
PFont mono;                      // Speech to text typeface

Word[] words;                    // Array of Word objects which comprise the recording

Boolean playing = false;         // If the recording is playing
Boolean bar = true;              // Display top bar showing amplitude
Boolean circle = false;          // Display center circle showing amplitude
Boolean spectrum = false;        // Display FFT spectrum analysis in bottom left
Boolean wave = false;            // Display a moving wave that shows amplitude in bottom
Boolean waveform = false;        // Displays waveform analysis in bottom left

Boolean PDFoutput = false;       // Should output PDF?
Boolean lastOutput = false;      // Flag for last page

// int seek = 1685000;
// int seek = 125000;
int seek = 0;                    // Starting time -- set to 0
int millis_start = 0;            // The absolute time (from unix time) when start playing
int current_time = 0;            // position of playhead in soundfile (millisec)
float playback_rate = 1.0;       // Speed of playback

int counter = 0;                 // Number of frames

int bands = 128;                 // FFT bands (multiple of sampling rate)
float[] sum_fft = new float[bands];   // smoothing vector
float smooth_factor = 0.175;          // smoothing factor
float r_width;                   // Width of rectangel
float sum_rms;                   // RMS Helper var
float scale = 5.0;               // Scale of waveform analysis

int granularity = 3;             // Granularity of waveform

int box_x, box_y, box_w, box_h;  // text box origin

float _space;                    // Width of a space
float _leading;                  // Leading
int current_page = 1;            // Current page
Boolean inParagraph = false;     // If currently typesetting in a paragraph
String currentCharacter = "A";   // The current character

float vScale = 1.0;              // Scale the type

// Initialize variables and load in data from data/..
void setup() {
    size(450,800);         // 9 x 16
    // size(1920, 1080);
    // size(400,400);         // 9 x 16

    // Uncomment for video recording, but keep commented for pdf output
    // pixelDensity(displayDensity());

    smooth();
    frameRate(60);
    mono = createFont("fonts/Speech-to-text-normal.ttf", 16*vScale);
    // mono = createFont("fonts/Speech-to-text-normal.ttf", 16*1.4*vScale);

    textFont(mono);
    _space = textWidth(" ");    // [], + 10
    _leading = 22*vScale;  // [24]
    // _leading = 22*1.4*vScale;  // [24]
    box_x = (int) (40*vScale);     // [20]
    box_y = (int) (60*vScale);     // [40]

    box_w = width - box_x * 2;
    box_h = height - box_y * 2;
    r_width = 1;
    String[] srcs = getDataFiles(sketchPath("data"));

    minim = new Minim(this);
    sample = minim.loadFile(srcs[0]);
    fft = new FFT(sample.bufferSize(), sample.sampleRate());
    fft.linAverages(bands);

    load_gc_json(srcs[1]);
    println("READY ...");
    println("sample.duration() : " + sample.length() + " seconds");
}

// Drawing loop
void draw() {

    // Output last page
    if (words[words.length-1].spoken() && !lastOutput) {
      PDFoutput = true;
      lastOutput = true;
    }

    // begin output current page to pdf
    if (PDFoutput) {
        beginRecord(PDF, "out/out" + current_page + ".pdf");
        mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
        // mono = createFont("fonts/Speech-to-text-normal.ttf", 16*1.4*vScale);
        textFont(mono);
    }

    background(0);
    fill(255);
    noStroke();

    int _x = 0;
    int _y = 0;

    inParagraph = true;

    if (playing) {

        current_time = millis() - millis_start + seek;

        // at end, stop playing
        if (playing && ((current_time) >= sample.length() * 1000)) {
            stop_sample();
        }

        // analyze amplitude
        sum_rms += (sample.mix.level() - sum_rms) * smooth_factor;
        float rms_scaled = sum_rms * (height/2) * scale;

        // typesetting
        for (Word w : words) {

            // only typeset current page and check beyond..
            if (w.spoken() && (w.page == -1 || w.page == current_page)) {
                if (w.opacity == 0.0)
                    w.opacity(sample.mix.level());

                // new line
                if (_x + w.width > box_w) {
                    _x = 0;
                    _y += _leading;
                }

                // new page
                if (_y + box_y + box_y > height) {
                    _y = 0;
                    current_page++;

                    // finish writing new page
                    if (PDFoutput) {
                      endRecord();
                      PDFoutput = false;
                    }
                    if (inParagraph) {
                      w.newPageStart();
                    }
                }

                // display word
                w.display(255, _x + box_x, _y + box_y);
                w.page = current_page;
                inParagraph = true;

                _x += (w.width + _space);

                // paragraph break
                if (w.paragraph) {
                    _x = 0;
                    _y += _leading;
                    inParagraph = false;
                }

                if (w.term && w.spoken()) {
                  currentCharacter = w.txt.substring(0,1);
                }

                // end of page
                if (_y + box_y + box_y + _leading > height) {
                  PDFoutput = true;
                }
            }
        }

        if (words[words.length-1].spoken() && PDFoutput) {
            endRecord();
            PDFoutput = false;
        }

        // current character
        fill(255);
        text(currentCharacter, width-20*vScale-textWidth(currentCharacter), height-20*vScale);

        // output various visualization
        if (bar)
            rect(0, 0, rms_scaled, 10*vScale);
        if (circle)
            ellipse(width/2, height/2, rms_scaled, rms_scaled);
        if (wave)
            rect(counter*granularity%width, height-rms_scaled, granularity, rms_scaled);
        if (spectrum) {
          fft.forward(sample.mix);
          stroke(255);
          noFill();
          beginShape();
          for (int i = 0; i < fft.avgSize(); i++) {
              sum_fft[i] += (fft.getAvg(i) - sum_fft[i]) * smooth_factor;
              vertex( i*r_width, height-40.0-sum_fft[i]*height*0.05);
          }
          endShape();
        }
        if (waveform) {
          stroke(255);
          noFill();
          beginShape();
          int numFrames = sample.mix.size();
          for(int i = 0; i < numFrames; i++) {
            float x = map(i, 0, numFrames-1, width-r_width*128, width);
            float y = map(sample.mix.get(i), 1, -1, 0, 100);
            vertex(x, height-y);
          }
          endShape();
        }

    }

    counter++;
}

/*

    sound control

*/

Boolean play_sample() {
    if (!playing) {
        counter = 0;
        millis_start = millis();
        sample.play(seek);

        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean stop_sample() {
    playing = false;
    sample.pause();
    return true;
}

/*

    utility

*/

Boolean load_gc_json(String filename) {

    // parse json endpoint from google cloud speech-to-text api

    json = loadJSONObject(filename);
    JSONObject jsonResponse = json.getJSONObject("response");
    JSONArray json_results = jsonResponse.getJSONArray("results");

    words = new Word[0];

    for (int i = 0; i < json_results.size(); i++) {

        JSONObject r = json_results.getJSONObject(i);
        JSONArray json_alternatives = r.getJSONArray("alternatives");

        for (int j = 0; j < json_alternatives.size(); j++) {

            JSONObject a = json_alternatives.getJSONObject(j);
            float confidence = a.getFloat("confidence");
            String transcript = a.getString("transcript");
            JSONArray json_words = a.getJSONArray("words");

            Word[] words_a;
            words_a = new Word[json_words.size()];

            for (int k = 0; k < json_words.size(); k++) {

                JSONObject w = json_words.getJSONObject(k);
                float in = float(w.getString("startTime").replace("s",""));
                float out = float(w.getString("endTime").replace("s",""));
                String txt = w.getString("word");
                Boolean paragraph = false;
                Boolean term = false;
                Boolean term_component = false;

                if (w.hasKey("paragraph") == true) {
                    paragraph = w.getBoolean("paragraph");
                }

                if (w.hasKey("term") == true) {
                    term = w.getBoolean("term");
                }
                if (w.hasKey("term-component") == true) {
                    term_component = w.getBoolean("term-component");
                }
                // new word object to array
                // words[k] = new Word(in, out, txt);
                words_a[k] = new Word(in, out, txt, paragraph, term, term_component);

                /*
                println(words[k].in);
                println(words[k].out);
                println(words[k].txt);
                */
            }

            // populate words[]
            for (Word w_a : words_a) {
                words = (Word[])append(words, w_a);
            }
        }
    }
    return true;
}

String[] getDataFiles(String dir) {
  File file = new File(dir);
  String txt_src = "";
  String wav_src = "";

  if (file.isDirectory()) {
    String[] names = file.list();
    for(String fn : names) {
      if (fn.contains(".wav")) {
        wav_src = fn;
      } else if (fn.contains(".json")) {
        txt_src = fn;
      }
    }
    return new String[]{wav_src, txt_src};
  }
  return null;
}

/*

    interaction

*/

void keyPressed() {
    switch(key) {
        case 'b':
            play_sample();
            bar = !bar;
            break;
        case 'c':
            play_sample();
            circle = !circle;
            break;
        case 'w':
            play_sample();
            wave = !wave;
            break;
        case 's':
            play_sample();
            spectrum = !spectrum;
            break;
        case ' ':
            if (!playing)
                play_sample();
            else
                stop_sample();
            break;
        case '.':
            stop_sample();
            break;
        case 'x':
            println("** exit **");
            exit();
            break;
        default:
            break;
    }
}
