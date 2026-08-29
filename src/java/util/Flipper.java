package util;

// convenient to have; idea from FRACTURE by sixthsurge: 
// https://github.com/sixthsurge/FRACTURE/blob/cb166979d658c928e6f09fb829bbaecdf2007f3c/src/java/util/Flipper.java

public class Flipper<T> {
    private T a;
    private T b;
    private boolean flipped;

    public Flipper(T _a, T _b) {
        this.a = _a;
        this.b = _b;
        this.flipped = false;
    }

    public void flip() {
        this.flipped = true;
    }

    // if this.flipped, our write buffer has been moved to the read buffer
    // i.e., front/read = b, back/write = a
    // default: front/read = a, back/write = b

    public T read_buffer() {
        return this.flipped ? this.b : this.a;
    }

    public T write_buffer() {
        return this.flipped ? this.a : this.b;
    }
}
