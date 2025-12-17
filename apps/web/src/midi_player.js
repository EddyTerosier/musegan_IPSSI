import * as Tone from "tone";

let synth = null;

export async function playMidiFromUrl(url) {
  await Tone.start();
  Tone.Transport.stop();
  Tone.Transport.cancel();

  if (!synth) {
    synth = new Tone.PolySynth(Tone.Synth).toDestination();
  }

  const arr = await (await fetch(url)).arrayBuffer();
  const midi = new Tone.Midi(arr);

  const now = Tone.now();
  midi.tracks.forEach((track) => {
    track.notes.forEach((n) => {
      synth.triggerAttackRelease(n.name, n.duration, now + n.time, n.velocity);
    });
  });

  return {
    duration: midi.duration,
    tracks: midi.tracks.length,
    notes: midi.tracks.reduce((acc, t) => acc + t.notes.length, 0),
  };
}
