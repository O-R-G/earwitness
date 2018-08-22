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


import processing.sound.*;
import processing.pdf.*;

SoundFile sample;
AudioDevice device;
FFT fft;
Amplitude rms;
JSONObject json;
PFont mono;

Word[] words;
String[] txt;           // speech fragments as text string

Boolean playing = false;
Boolean bar = true;
Boolean circle = false;
Boolean spectrum = false;
Boolean wave = false;
Boolean speech_flag = false;
Boolean lastwordspoken = false;
Boolean PDFoutput = false;
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

float[] lastN = new float[100];

void setup() {
    size(450,800);         // 9 x 16
    // size(400,400);         // 9 x 16
    // pixelDensity(displayDensity());
    // println("displayDensity : " + displayDensity());
    smooth();
    frameRate(60);
    mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
    textFont(mono);
    _space = textWidth(" ");    // [], + 10
    _leading = 22;  // [24]
    box_x = 40;     // [20]
    box_y = 60;     // [40]
    box_w = width - box_x * 2;
    box_h = height - box_y * 2;
    device = new AudioDevice(this, 44100, bands);
    r_width = width/float(bands);
    String[] srcs = getDataFiles(sketchPath("data"));
    sample = new SoundFile(this, srcs[0]);
    load_gc_json(srcs[1]);
    println("READY ...");
    println("sample.duration() : " + sample.duration() + " seconds");
}

void draw() {

    if (PDFoutput) {
        beginRecord(PDF, "out/out.pdf");
        mono = createFont("fonts/Speech-to-text-normal.ttf", 16);
        textFont(mono);
    }

    background(0);
    fill(255);
    noStroke();

    int _x = 0;
    int _y = 0;

    inParagraph = true;

    if (playing) {

        current_time = millis() - millis_start;
        if (playing && ((current_time) >= sample.duration() * 1000))
            stop_sample();

        // analyze amplitude
        sum_rms += (rms.analyze() - sum_rms) * smooth_factor;
        float rms_scaled = sum_rms * (height/2) * scale;

        // typesetting
        for (Word w : words) {
            if (w.spoken() && (w.page == -1 || w.page == current_page)) {
                if (w.opacity == 0.0)
                    w.opacity(rms.analyze());

                if (_x + w.width > box_w) {
                    _x = 0;
                    _y += _leading;
                }

                if (_y + box_y + box_y > height) {
                    _y = 0;
                    current_page++;
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
            }
        }
        if (bar)
            rect(0, 0, rms_scaled, 10);
        if (circle)
            ellipse(width/2, height/2, rms_scaled, rms_scaled);
        if (wave)
            rect(counter*granularity%width, height-rms_scaled, granularity, rms_scaled);


        // for (int i = 0; i < lastN.length; i++) {
        //   fill(255);
        //   rect(i, height-50, 1, (float)Math.random()*10);
        // }
        // if (spectrum) {

        // fft.analyze();
        // for (int i = 0; i < bands; i++) {
        //     fill(255);
        //     sum_fft[i] += (fft.spectrum[i] - sum_fft[i]) * smooth_factor;
        //     rect( i*r_width, height, r_width, -sum_fft[i]*height*scale );
        //     println(sum_fft[i]);
        // }
        // }

    }

    if (PDFoutput) {
        PDFoutput = false;
        endRecord();
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
        // sample.play();   // always throws error on exit (bug)
        sample.loop();      // so use .loop() instead

        // not working, likely to do w/bands and sample rate
        // fft = new FFT(this, bands);
        // fft.input(sample);

        rms = new Amplitude(this);
        rms.input(sample);
        playing = true;
        return true;
    } else {
        return false;
    }
}

Boolean stop_sample() {
    playing = false;
    // rms = null;
    sample.stop();
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

                if (w.hasKey("paragraph") == true) {
                    paragraph = w.getBoolean("paragraph");
                }
                // new word object to array
                // words[k] = new Word(in, out, txt);
                words_a[k] = new Word(in, out, txt, paragraph);

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
                sample.rate(playback_rate);
                break;
            }
        case '-':
            if (playing) {
                playback_rate -= .1;
                sample.rate(playback_rate);
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
