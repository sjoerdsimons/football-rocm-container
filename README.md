# ROCm Football Container

## Dependencies

* `docker-compose`

## Build

```
docker compose up --build
```

## Run

### Start Container

```
# TODO: Expose wayland
# docker run -it -v '/home/user/Videos/:/videos/' rocm-football:latest

# Expose ROCm GPU
docker run -it --rm --device=/dev/kfd --device=/dev/dri/renderD128 --security-opt seccomp=unconfined -v ~/Videos:/videos/ football-arch:latest
```

### Run the demo

```
cd /root/gst-python-ml
. .venv/bin/activate
export GST_PLUGIN_PATH=`realpath plugins/`

# Sanity check
rm ~/.cache/gstreamer-1.0/ -R && GST_DEBUG=3 gst-inspect-1.0 python


BACKEND="fp16" GST_DEBUG=3 ./demo/football/run.sh display /videos/my-video.webm 1920x1080
```