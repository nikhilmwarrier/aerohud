run:
  swift run

build:
  swift package clean && swift build -c release

copy:
  cp ./.build/release/aerohud ~/.local/bin/
