#! /bin/sh

# enable headphone jack in docking stations for IvyBridge Lenovo Thinkpads

# see official documentation
# http://www.alsa-project.org/main/index.php/HDA_Analyzer
# http://ftp.rz.tu-bs.de/ftp/pub/mirror/ftp.kernel.org/people/tiwai/misc/hda-verb/

./hda-verb /dev/snd/hwC0D0 0x1b SET_PIN_WIDGET_CONTROL 0x40
./hda-verb /dev/snd/hwC0D0 0x1b SET_AMP_GAIN_MUTE 0xb000
