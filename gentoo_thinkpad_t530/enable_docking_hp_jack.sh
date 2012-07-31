#! /bin/sh

# enable headphone jack in docking stations for IvyBridge Lenovo Thinkpads

# see official documentation
# http://www.alsa-project.org/main/index.php/HDA_Analyzer
# http://ftp.rz.tu-bs.de/ftp/pub/mirror/ftp.kernel.org/people/tiwai/misc/hda-verb/

# set output pin
./hda-verb /dev/snd/hwC0D0 0x1b SET_PIN_WIDGET_CONTROL 0x40
# unmute
./hda-verb /dev/snd/hwC0D0 0x1b SET_AMP_GAIN_MUTE 0xb000
# choose other audio mixer
./hda-verb /dev/snd/hwC0D0 0x1b SET_CONNECT_SEL 1
