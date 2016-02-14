#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Written by Mario Kicherer (http://kicherer.org) 2016
#
# License: GPL-3
#
# Subtitle processing is based on dvbsubrip by Luca Olivetti and Phillip Hansen
#
#
# This script expects a .ts file, e.g., from a TV recording, as parameter. It
# extracts the subtitle stream, converts with multiple threads the subtitle
# images into text and merges video, audio and subtitles into a MKV container.
#

NUM_THREADS=8

import json, subprocess, sys, os
import pprint
import tempfile, shutil
from xml.dom import minidom
from threading import Thread
from queue import Queue

def convtc(intc):
	"""Convert sony timecode to srt timecode at 25fps and add fixed offset"""
	hours=int(intc[:2])
	minutes=int(intc[3:5])
	seconds=int(intc[6:8])
	frames=int(intc[9:])
	
	total=hours*3600000+minutes*60000+seconds*1000+frames*1000/24+time_offset
	
	#The following should be needed in theory, in practice it messes up the timing
	#in fact, removing this line most of this function is useless
	#total=total * 24 / 25
	ms=total % 1000
	total=total/1000
	seconds=total % 60
	total=total/60
	minutes=total % 60
	hours=total/60
	
	return '%02d:%02d:%02d,%03d' % (hours,minutes,seconds,ms)

def snooppts(file, pid):
	"""Use dvbsnoop to obtain the first PTS"""
	dvbsnoop = subprocess.Popen(["dvbsnoop", "-if", file, "-s", "ts", "-tssubdecode", "-tf", pid, "-ph", "0", "-nph"], stdout=subprocess.PIPE)
	for line in dvbsnoop.stdout:
		if line.decode("utf-8").find('==> PTS')>=0:
			dvbsnoop.terminate()
			return int(line.split()[2])
	return 0

def app_avail(app):
	return os.system("which %s >/dev/null" % (app)) == 0;

def wdir(filename):
	global tempdir
	
	return os.path.join(tempdir, filename)

class Worker(Thread):
	def run(self):
		global inqueue
		global outqueue
		
		while True:
			i, frame, hdr = inqueue.get()
			if not frame:
				break;
			
			# prepare subtitle image for OCR
			os.system('convert '+wdir(frame)+' -background black -alpha remove -threshold 40% -bordercolor black -border 100%x100% '+wdir(frame)+'.png')
			
			# first try to recognize multiline text
			p = subprocess.Popen('tesseract -psm 6 -l deu '+wdir(frame)+'.png -', shell=True, stdout=subprocess.PIPE, close_fds=True)
			text = p.stdout.read().decode("utf-8")
			p.stdout.close()
			
			# if we can't recognize something, try as single-line text
			if text.strip() == "":
				p = subprocess.Popen('tesseract -psm 7 -l deu '+wdir(frame)+'.png -', shell=True, stdout=subprocess.PIPE, close_fds=True)
				text = p.stdout.read().decode("utf-8")
				p.stdout.close()
			
			outqueue.put((i, text, hdr))
			inqueue.task_done()

#
# script start
#

apps = ["ffprobe", "projectx_cli", "dvbsnoop", "BDSup2Sub"]

for app in apps:
	if not app_avail(app):
		print("error, %s not found" % app)
		sys.exit(1)

filename=sys.argv[1]

# get video structure with ffprobe
p = subprocess.Popen("ffprobe -print_format json -show_streams -i \"%s\" 2>/dev/null" % (filename), shell=True, stdout=subprocess.PIPE, close_fds=True);
output = p.stdout.readlines();
p.stdout.close()
if p.wait() != 0:
	print("error")
	print(" ".join(output))
	sys.exit(1);

json_string = b" ".join(output).decode('utf-8')
j = json.loads(json_string)

vid=[]
subs=[]
for s in j["streams"]:
	if not "codec_type" in s:
		continue
	
	if s["codec_type"] == "video":
		vid.append(s["id"])
	
	if s["codec_type"] == "subtitle":
		sid = s["id"]
		
		lang = None
		if "tags" in s:
			if "language" in s["tags"]:
				lang = s["tags"]["language"]
		
		subs.append((sid,lang))

tempdir=tempfile.mkdtemp()
#tempdir="tmp"

# extract subtitles as idx/sub
if not os.path.isfile(wdir('mysub.sup.sub')):
	# SubpictureColorModel: UkFreeview(mc) RTLdeu ZDFvision(mc) "(2) 256 colours"
	f=open(wdir('projectx.ini'), 'w')
	f.write("""# Project-X INI
# ProjectX 0.90.4.00.b32 / 30.12.2009

# Application
Application.Agreement=1
Application.OutputDirectory=%s

# CollectionPanel
CollectionPanel.CutMode=0

# SubtitlePanel
SubtitlePanel.SubpictureColorModel=RTLdeu
SubtitlePanel.enableHDSub=1
SubtitlePanel.exportAsVobSub=1

ExportPanel.Streamtype.MpgVideo=0
ExportPanel.Streamtype.MpgAudio=0
ExportPanel.Streamtype.Ac3Audio=0
ExportPanel.Streamtype.PcmAudio=0
ExportPanel.Streamtype.Teletext=0
ExportPanel.Streamtype.Subpicture=1
ExportPanel.Streamtype.Vbi=0
""" % tempdir)
	f.close()
	subfile = "vobsubs_"+sid+"_"+lang;
	os.system("projectx_cli -ini "+wdir("projectx.ini")+" -name mysub "+filename)

if not os.path.isfile(wdir('mysub.sup.sub')):
	print("projectx failed\n")
	exit(1)

# calculate time offset of subtitles
offset=""
vpts = snooppts(filename, vid[0])
spts = snooppts(filename, subs[0][0])

time_offset = 0
if vpts and spts: # and spts>vpts:
	time_offset = (vpts-spts) / 90
	offset = "%s --sync 0:%d" % (offset, time_offset)


# new color palette for subtitle images
f=open(wdir('color_palette.ini'), 'w')
f.write("""#COL - created by BDSup2Sub 4.0.0
#Sun Feb 14 14:05:22 CET 2016
Color_15=215,215,215
Color_14=215,215,215
Color_13=215,215,215
Color_12=215,215,215
Color_11=215,215,215
Color_10=215,215,215
Color_9=215,215,215
Color_8=215,215,215
Color_7=215,215,215
Color_6=215,215,215
Color_5=215,215,215
Color_4=235,221,32
Color_3=235,221,32
Color_2=235,221,32
Color_1=0,0,0
Color_0=0,0,0
""")
f.close()

# first convert palette then create XML and PNG images out of idx/sub
if not os.path.isfile(os.path.join(tempdir, 'mysub.xml')):
	# bdsup2sub wants relative files
	olddir=os.getcwd()
	os.chdir(tempdir)
	
	os.system('BDSup2Sub mysub.sup.sub    mysub_cc.sup.sub /pal:%s' % wdir("color_palette.ini"))
	os.system('BDSup2Sub mysub_cc.sup.sub mysub.xml')
	
	os.chdir(olddir)

# parse XML
f=open(wdir("mysub.xml"),'r')
xmldoc=minidom.parse(f).documentElement
f.close()
events=xmldoc.getElementsByTagName('Event')
l=len(events)

print("starting OCR process")

# initialize queues for multithreaded image processing & OCR
inqueue = Queue(NUM_THREADS*2)
outqueue = Queue()
workers=[]

# start threads
for i in range(NUM_THREADS):
	w = Worker()
	w.start()
	workers.append(w)

# this thread will produce the work
def producer():
	global events
	global inqueue
	
	i=0
	for event in events:
		intc=event.attributes['InTC'].nodeValue
		outtc=event.attributes['OutTC'].nodeValue
		
		graph=event.getElementsByTagName('Graphic')
		frame=graph[0].childNodes[0].nodeValue
		
		i=i+1
		hdr = '%d\n%s --> %s\n' % (i, convtc(intc),convtc(outtc))
		
		inqueue.put((i, frame, hdr))
Thread(target=producer).start()

print("waiting on results")

out = open(wdir("mysub.srt"), "w")
i=0
last_idx = 0
# we need to reorder the results chronologically
reorder_buf = {}
for event in events:
	i=i+1
	
	idx, text, hdr = outqueue.get()
	reorder_buf[idx] = (text, hdr)
	outqueue.task_done()
	
	while last_idx+1 in reorder_buf.keys():
		last_idx += 1
		text, hdr = reorder_buf[last_idx]
		
		out.write(hdr + text.strip() + '\n\n')
		p = i*100 / l
		sys.stdout.write('\r%d%%' % p)

if last_idx != l:
	print("error %d != %d" %(last_idx, l))

# make the threads quit
for w in workers:
	inqueue.put((None, None, None))

out.close()
print("")

# merge into MKV container
cmd = "mkvmerge -o \""+filename+".mkv\" "+offset+" --track-name 0:"+subs[0][1]+" "+wdir("mysub.srt")+" "+filename+""
print("executing: %s" % cmd)
ret = os.system(cmd)

shutil.rmtree(tempdir)