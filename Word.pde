/*
    word transcribed from google cloud speech-to-text
    with time stamps
*/

class Word {

    String txt;
    int length;
    float in, out;
    float width;
    float opacity;
    Boolean paragraph;
    Boolean newPageStart;
    Boolean spoken;
    Boolean term;
    Boolean term_component;
    int page = -1;

    Word(float in_, float out_, String txt_, Boolean paragraph_, Boolean term_, Boolean term_component_) {
        in = in_;
        out = out_;
        txt = txt_;
        paragraph = paragraph_;
        term = term_;
        term_component = term_component_;

        width = textWidth(this.txt);
        length = txt.length();
        opacity = 0.0;
        spoken = false;
        newPageStart = false;
    }

    Boolean speaking() {
        float now = (float)current_time/1000;
        if ((in <= now) && (out >= now))
            return true;
        else
            return false;
    }

    Boolean spoken() {
        float now = (float)current_time/1000;
        if (((in+out)/2 <= now))
            return true;
        else
            return false;
    }

    void opacity(float value) {
        if (opacity == 0.0)
            // opacity = map(value, 0.0, 0.05, 100.0, 255.0);
            // opacity = map(value, 0.0, 0.08, 100.0, 255.0);
            opacity = map(value, 0.0, 0.08, 150.0, 255.0);
    }

    void display(int fill, int _x, int _y) {
        float scaleFactor = 1.0;

        fill(fill, int(opacity));

        // if (term_component)
        //   fill(255);

        text(txt, _x, _y);

        // if (term_component)
        //   text(txt.toUpperCase(), _x, _y);
        // else
        //   text(txt, _x, _y);

        if (term_component) {
          noFill();
          stroke(127.5);
          strokeWeight(1*scaleFactor);
          if (!term)
            line(_x-textWidth(" "), _y+5*scaleFactor, _x+textWidth(txt), _y+5*scaleFactor);
          else
            line(_x, _y+5*scaleFactor, _x+textWidth(txt), _y+5*scaleFactor);
        }

        // int weight  = int(map(fill, 0.0, 255.0, 0.0, 12.0));
        // stroke_text(txt, weight, _x, _y);
    }

    void newPageStart() {
      if (!newPageStart) {
        txt = "... " + txt;
        width = textWidth(txt);
        newPageStart = true;
      }
    }

}
