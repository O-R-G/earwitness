/*
    Word.pde

    Representation of a Word for Earwitness. Contains word and metadata
    information.
*/

class Word {

    String txt;               // The "word" or output
    int length;               // The number of characters of the "word"
    float in, out;            // The begin/end times in the audio when spoken
    float width;              // Calculated width of the word
    float opacity;            // Opacity of the word, only set when spoken
    Boolean paragraph;        // If the word is the last in a paragrpah.
    Boolean newPageStart;     // If the word is the first on a new page & continues from previous
    Boolean spoken;           // If the word has been spoken
    Boolean term;             // If the word is the first of a term
    Boolean term_component;   // If the word is part of a term
    int page = -1;            // What page the word is on - only sets when spoken

    /*
      Constructor
      in_               the time at which the word begins to be spoken
      out_              the time at which the word stops being spoken
      txt_              the word contents
      paragraph_        if the word is the end of a paragraph
      term_             if the word is the beginning of a term
      term_component_   if the word is part of a term
    */
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

    // Returns true if the word is being spoken
    Boolean speaking() {
        float now = (float)current_time/1000;
        if ((in <= now) && (out >= now))
            return true;
        else
            return false;
    }

    // Returns true if at least half the word has been spoken
    Boolean spoken() {
        float now = (float)current_time/1000;
        if (((in+out)/2 <= now))
            return true;
        else
            return false;
    }

    // Sets the opacity of the word given an amplitude input, mapped [0,0.08] => [150, 255]
    void opacity(float value) {
        if (opacity == 0.0)
            opacity = map(value, 0.0, 0.08, 150.0, 255.0);
    }

    // Displays the word at a given starting coordinate (_x, _y) with a specified
    // fill color (fill). The fill color will also have a certain opacity, previously
    // assigned. If the word is a term component, it will also have an underline
    void display(int fill, int _x, int _y) {
        float scaleFactor = 1.0;

        fill(fill, int(opacity));

        // Try pure white
        // if (term_component)
        //   fill(255);

        text(txt, _x, _y);

        // Try all caps if term
        // if (term_component)
        //   text(txt.toUpperCase(), _x, _y);
        // else
        //   text(txt, _x, _y);

        // Try underline
        if (term_component) {
          noFill();
          stroke(127.5);
          strokeWeight(1*scaleFactor);
          if (!term)
            line(_x-textWidth(" "), _y+5*scaleFactor, _x+textWidth(txt), _y+5*scaleFactor);
          else
            line(_x, _y+5*scaleFactor, _x+textWidth(txt), _y+5*scaleFactor);
        }
    }

    // Call if the beginning of a new page and not the beginning of a paragraph
    // so that an ellipsis can be added
    void newPageStart() {
      if (!newPageStart) {
        txt = "... " + txt;
        width = textWidth(txt);
        newPageStart = true;
      }
    }
}
