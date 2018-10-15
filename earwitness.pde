/**
 * kings
 *
 * speech to text transcription using google cloud api
 * to visually animate the typesetting of spoken language
 * and translate the cadence into visual / dynamic form
 *
 * uses processing.sound for Amplitude analysis
 * and processing.pdf for output
 * uses Speech-to-text-normal as base
 *
 * developed for Coretta Scott and Martin Luther King
 * memorial, Boston Common w/ Adam Pendleton & David Adjaye
 *
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import processing.pdf.*;

Minim minim;
AudioPlayer sample;
FFT fft;

JSONObject json;
PFont mono;

Word[] words;
String[] txt;           // speech fragments as text string

Boolean playing = false;
Boolean bar = true;
Boolean circle = false;
Boolean spectrum = false;
Boolean wave = false;
Boolean waveform = false;
Boolean speech_flag = false;
Boolean lastwordspoken = false;
Boolean PDFoutput = false;

String currentCharacter = "A";

// int seek = 1685000;
// int seek = 125000;
int seek = 0;
int millis_start = 0;
int current_time = 0;               // position in soundfile (millisec)
int counter = 0;
int bands = 128;                    // FFT bands (multiple of sampling rate)
int granularity = 3;
int in = 0;
int out = 0;
int silence_min = 30;               // [10]
int box_x, box_y, box_w, box_h;     // text box origin
float scale = 5.0;
float r_width;
float sum_rms;
float[] sum_fft = new float[bands];   // smoothing vector
float smooth_factor = 0.175;          // smoothing factor
float playback_rate = 1.0;
float amp_floor = 0.04; // 0.02 0.04 [0.08]
float _space;
float _leading;
int current_page = 1;
Boolean inParagraph = false;

// float vScale = 2.4;
float vScale = 1.0;

void setup() {
    size(450,800);         // 9 x 16
    // size(1920, 1080);
    // size(400,400);         // 9 x 16
    // pixelDensity(displayDensity());
    // println("displayDensity : " + displayDensity());
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

void draw() {

    if (PDFoutput) {
        beginRecord(PDF, "out/out" + current_page + ".pdf");
        // mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
        mono = createFont("fonts/Speech-to-text-normal.ttf", 16*1.4*vScale);
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
        if (playing && ((current_time) >= sample.length() * 1000))
            stop_sample();

        // analyze amplitude
        sum_rms += (sample.mix.level() - sum_rms) * smooth_factor;
        float rms_scaled = sum_rms * (height/2) * scale;

        // typesetting
        for (Word w : words) {
            if (w.spoken() && (w.page == -1 || w.page == current_page)) {
                if (w.opacity == 0.0)
                    w.opacity(sample.mix.level());

                if (_x + w.width > box_w) {
                    _x = 0;
                    _y += _leading;
                }

                if (_y + box_y + box_y > height) {
                    _y = 0;
                    current_page++;
                    if (PDFoutput) {
                      endRecord();
                      PDFoutput = false;
                    }
                    if (inParagraph) {
                      w.newPageStart();
                    }
                }

                w.display(255, _x + box_x, _y + box_y);
                w.page = current_page;
                inParagraph = true;

                _x += (w.width + _space);

                if (w.paragraph) {
                    _x = 0;
                    _y += _leading;
                    inParagraph = false;
                }

                if (w.term && w.spoken()) {
                  currentCharacter = w.txt.substring(0,1);
                }

                if (_y + box_y + box_y + _leading > height) {
                  PDFoutput = true;
                }
            }
        }

        // if (PDFoutput) {
        //     PDFoutput = false;
        //     endRecord();
        // }

        fill(255);
        text(currentCharacter, width-20*vScale-textWidth(currentCharacter), height-20*vScale);

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
          // float ySilence = height/2;
          int numFrames = sample.mix.size(); // s = AudioPlayer
          for(int i = 0; i < numFrames; i++) {
            // float x = map(i, 0, numFrames -1, 0, r_width*128);
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
        in = 0;
        out = 0;
        counter = 0;
        millis_start = millis();
        sample.play(seek  );

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

void stroke_text(String text, int weight, int x, int y) {

    // see https://forum.processing.org/two/discussion/16700/how-to-outline-text

    // int value = 255 - (weight * 50);
    // fill(value);
    // for (int i = -1; i < 2; i++) {
    for (int i = -weight; i <= weight; i++) {
        text(text, x+i, y);
        text(text, x, y+i);
    }
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
        case '=':
            if (playing) {
                playback_rate += .1;
                // sample.rate(playback_rate);
                break;
            }
        case '-':
            if (playing) {
                playback_rate -= .1;
                // sample.rate(playback_rate);
                break;
            }
        case 'p':
            PDFoutput = !PDFoutput;
            println("** writing PDF to out/out.pdf **");
            break;
        case 'x':
            println("** exit **");
            exit();
            break;
        default:
            break;
    }
    switch(keyCode) {
        case UP:
            if (amp_floor < .99)
                amp_floor+=.01;
            background(204);
            rect(0,height - (amp_floor * height),width,1);
            println(amp_floor);
            break;
        case DOWN:
            if (amp_floor > .01)
                amp_floor-=.01;
            background(204);
            rect(0,height - (amp_floor * height),width,1);
            println(amp_floor);
            break;
        case LEFT:
            // current_time-=1000;
            break;
        case RIGHT:
            /*
            background(255);
            current_time+=1000;
            sample.stop();
            sample.cue(current_time);
            sample.play();
            */
            break;
        default:
            break;
    }
}
