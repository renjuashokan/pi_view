# PiView

A new Flutter project.

## Getting Started

### Build build Docker for Android

```sh
docker build -t flutter-android .

docker run -it --rm -v $(pwd):/app flutter-android

flutter build apk
```
