#!/bin/bash

if [ "$TYPE" = "python" ]; then
  python -c "import fast; fast.downloadTestDataIfNotExists()"
  pip install pytest numpy
  apt install -y git
  git clone https://github.com/FAST-Imaging/FAST.git
  cd FAST/source/FAST/Python/Tests
  pytest -v -s -k "not cast"
else
  ./opt/fast/bin/systemCheck
fi
