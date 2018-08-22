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
    int page = -1;

    Word(float in_, float out_, String txt_, Boolean paragraph_) {
        in = in_;
        out = out_;
        txt = txt_;
        paragraph = paragraph_;

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
        if ((in <= now))
            return true;
        else
            return false;
    }

    void opacity(float value) {
        if (opacity == 0.0)
            // opacity = map(value, 0.0, 0.05, 100.0, 255.0);
            opacity = map(value, 0.0, 0.08, 100.0, 255.0);
    }

    void display(int fill, int _x, int _y) {
        fill(fill, int(opacity));
        text(txt, _x, _y);
        // int weight  = int(map(fill, 0.0, 255.0, 0.0, 12.0));
        // stroke_text(txt, weight, _x, _y);
    }

    void newPageStart() {
      if (!newPageStart) {
        txt = "..." + txt;
        width = textWidth(txt);
        newPageStart = true;
      }
    }

}
