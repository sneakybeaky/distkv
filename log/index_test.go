package log

import (
	"io"
	"io/ioutil"
	"os"
	"testing"
)

func TestIndex(t *testing.T) {

	f, err := ioutil.TempFile(t.TempDir(), "index_test")
	if err != nil {
		t.Fatal(err)
	}

	c := Config{}
	c.Segment.MaxIndexBytes = 1024
	idx, err := newIndex(f, c)
	if err != nil {
		t.Fatal(err)
	}
	_, _, err = idx.Read(-1)
	if err == nil {
		t.Fatal("Reading a negative position should return an error")
	}

	if f.Name() != idx.Name() {
		t.Fatalf("%s should be the same as %s", f.Name(), idx.Name())
	}

	entries := []struct {
		Off uint32
		Pos uint64
	}{
		{Off: 0, Pos: 0},
		{Off: 1, Pos: 10},
	}

	for _, want := range entries {
		err = idx.Write(want.Off, want.Pos)
		if err != nil {
			t.Fatal(err)
		}

		_, pos, err := idx.Read(int64(want.Off))
		if err != nil {
			t.Fatal(err)
		}

		if want.Pos != pos {
			t.Errorf("wanted %d got %d", want.Pos, pos)
		}

	}

	// index and scanner should error when reading past existing entries
	_, _, err = idx.Read(int64(len(entries)))

	if err != io.EOF {
		t.Errorf("wanted EOF got %v", err)
	}

	_ = idx.Close()

	// index should build its state from the existing file
	f, _ = os.OpenFile(f.Name(), os.O_RDWR, 0600)
	idx, err = newIndex(f, c)
	if err != nil {
		t.Fatal(err)
	}

	off, pos, err := idx.Read(-1)
	if err != nil {
		t.Fatal(err)
	}

	if off != uint32(1) {
		t.Errorf("offset should be 1, but got %d", off)
	}

	if entries[1].Pos != pos {
		t.Errorf("wanted %d got %d", entries[1].Pos, pos)
	}
}
