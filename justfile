run:
  swift run

build:
  swift build clean && swift build -c release

copy:
  cp ./.build/release/aerohud ~/.local/bin/
