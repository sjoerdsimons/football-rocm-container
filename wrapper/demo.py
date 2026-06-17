#!/usr/bin/env python3
import gi
import sys

gi.require_version("Gst", "1.0")
from gi.repository import Gst, GLib

Gst.init(None)


def on_message(bus, message, loop, pipeline):
    t = message.type

    if t == Gst.MessageType.EOS:
        print("Looping...")
        success = pipeline.seek_simple(
            Gst.Format.TIME,
            Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT,
            0,
        )
        if not success:
            print("Failed to seek back to start", file=sys.stderr)
            loop.quit()

    elif t == Gst.MessageType.ERROR:
        err, debug = message.parse_error()
        print(f"ERROR: {err}", file=sys.stderr)
        if debug:
            print(f"DEBUG: {debug}", file=sys.stderr)
        loop.quit()


def main():
    pipeline_description = (
        f"filesrc location={sys.argv[1]} ! "
        "decodebin ! videoconvert ! videoscale ! "
        "video/x-raw,width=640,height=640,format=RGB ! "
        "queue max-size-buffers=8 max-size-time=0 max-size-bytes=0 ! "
        "pyml_objectdetector engine-name=onnx  "
          " model-name=models/football/football_fp16.onnx device=cuda:0 "
          " input-format=nchw post-process=anchor_free interval=3 ! "
        "queue max-size-buffers=8 max-size-time=0 max-size-bytes=0 ! "
        "pyml_tracker tracker-type=bytetrack ! "
        "videoconvert ! video/x-raw,format=RGBA ! "
        "queue max-size-buffers=8 max-size-time=0 max-size-bytes=0 ! "
        "pyml_football_overlay class-names=ball,goalkeeper,player,referee "
        "  team-colors=true trails=false show-ids=false show-labels=false ! "
        "queue max-size-buffers=600 max-size-time=0 max-size-bytes=0 "
          " min-threshold-buffers=30 ! "
        "videoconvert ! autovideosink sync=true"
    )
    print(pipeline_description)

    try:
        pipeline = Gst.parse_launch(pipeline_description)
    except GLib.Error as e:
        print(f"Failed to create pipeline: {e}", file=sys.stderr)
        sys.exit(1)

    loop = GLib.MainLoop()

    bus = pipeline.get_bus()
    bus.add_signal_watch()
    bus.connect("message", on_message, loop, pipeline)

    pipeline.set_state(Gst.State.PLAYING)

    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    finally:
        pipeline.set_state(Gst.State.NULL)


if __name__ == "__main__":
    main()
