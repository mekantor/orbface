// -------------------------------------------------------------------
// orb
// -------------------------------------------------------------------

#include "../../../lib/std.mi"
#include "../../../lib/config.mi"
#include "../../../lib/pldir.mi"

Function startAnimation (AnimatedLayer l, int start, int end, int speed);
Function startFadeOut ();
Function startFadeIn ();

Class ConfigAttribute ToggleConfigAttribute;

Global Wac MainComp, Playlist;
Global Container M_Container;
Global Button Eject;
Global AnimatedLayer Volume, Previous, Play, Pause, Stop, Next, open, VolBg, seekImage, crossfade, shuffle, loop;
Global ToggleButton crossfadeButton, shuffleButton, loopButton;
Global Layout Main, M_Normal;
Global Layer leftI, rightI;
Global Text disp;
Global Timer time1, time2, seekTimer, eyeTimer;
Global Int change, level, alpha, fadeIn, fadeOut, length, position, clicked, doNotSet, crossfadeStatus, shuffleStatus, loopStatus, mouseX, mouseY;
Global ToggleConfigAttribute attrRepeat, attrShuffle, attrCrossfade, attr_desktopalpha;

System.onScriptLoaded() {
	// Objects //
	MainComp		= getWac("{3CBD4483-DC44-11d3-B608-000086340885}");
	Playlist		= getWac("{45F3F7C1-A6F3-4ee6-A15E-125E92FC3F8D}");
	M_Container		= getContainer("Main");
	Main			= M_Container.getLayout("Normal");
	leftI			= Main.getObject("blackc1");
	rightI			= Main.getObject("blackc2");
	Previous		= Main.getObject("previous");
	Pause			= Main.getObject("pause");
	Play			= Main.getObject("play");
	Next			= Main.getObject("next");
	Stop			= Main.getObject("stop");
	Open			= Main.getObject("open");
	Eject			= Main.getObject("eject");
	Volume			= Main.getObject("volume");
	VolBg			= Main.getObject("volume.bg");
	seekImage		= Main.getObject("seekImage");
	crossfade		= Main.getObject("crossfade");
	shuffle		= Main.getObject("shuffle");
	loop			= Main.getObject("loop");
	crossfadeButton	= Main.getObject("crossfadeButton");
	shuffleButton		= Main.getObject("shuffleButton");
	loopButton		= Main.getObject("loopButton");

	// Thanks to Bizzy D. in the forums for this
	ConfigItem item;
	item = Config.getItem("Skins and UI Tweaks");
	if (item != NULL) {
		attr_desktopalpha=item.getAttribute("Enable desktop alpha");
	}
	if (StringToInteger(attr_desktopalpha.getData()) == 1) {
		// NT stuff
		Main.setXMLParam("background","player.main.bgNT");
		Main.setXMLParam("desktopalpha","1");
	} else {
		// 9x/Me stuff
		Main.setXMLParam("background","player.main.bg9x");
		Main.setXMLParam("desktopalpha","0");
	}

	// Volume stuff //
	Float level;
	level=System.getVolume();
	level=(level/255)*(Volume.getLength()-1);
	Volume.gotoFrame(level);

	// Gets Crossfade, Shuffle, and Loop ready //
	ConfigItem item;
	item=Config.getItem("Playlist editor");
	if (item != NULL) {
		attrRepeat=item.getAttribute("repeat");
		attrShuffle=item.getAttribute("shuffle");
	}
	item=Config.getItem("Audio options");
	if (item != NULL) {
		attrCrossfade=item.getAttribute("Enable crossfading");
	}
	if (crossfadeButton != NULL && MainComp != NULL) {
		int temp=StringToInteger(attrCrossfade.getData());
		crossfadeButton.setActivated(temp);
		if (temp == 1) {
			crossfadeStatus=1;
			crossfade.gotoFrame(0);
		} else {
			crossfadeStatus=0;
			crossfade.gotoFrame(3);
		}
	}
	if (shuffleButton != NULL && MainComp != NULL) {
		int temp=StringToInteger(attrShuffle.getData());
		shuffleButton.setActivated(temp);
		if (temp == 1) {
			shuffleStatus=1;
			shuffle.gotoFrame(3);
		} else {
			shuffleStatus=0;
			shuffle.gotoFrame(0);
		}
	}
	if (loopButton != NULL && MainComp != NULL) {
		int temp=StringToInteger(attrRepeat.getData());
		loopButton.setActivated(temp);
		if (temp == 1) {
			loopStatus=1;
			loop.gotoFrame(3);
		} else {
			loopStatus=0;
			loop.gotoFrame(0);
		}
	}

	// Timers //
	time1=new Timer;
	time1.setDelay(5);
	time2=new Timer;
	time2.setDelay(5);
	seekTimer=new Timer;
	seekTimer.setDelay(150);
	seekTimer.start();
	eyeTimer=new Timer;
	eyeTimer.setDelay(25);
	eyeTimer.start();
}

System.onScriptUnloading () {
	delete time1;
	delete time2;
	delete seekTimer;
}

/////////////////////////////
/// Windows 9x/ME sucks!!!! /////////////////////////////////////////////////
/////////////////////////////

M_Container.onSwitchToLayout (Layout Normal) {
	ConfigItem item;
	item = Config.getItem("Skins and UI Tweaks");
	attr_desktopalpha=item.getAttribute("Enable desktop alpha");
	if (StringToInteger(attr_desktopalpha.getData()) == 1) {
		// NT stuff
		Main.setXMLParam("background","player.main.bgNT");
		Main.setXMLParam("desktopalpha","1");
	} else {
		// 9x/Me stuff
		Main.setXMLParam("background","player.main.bg9x");
		Main.setXMLParam("desktopalpha","0");
	}
}

/////////////////////////////
/// Moving Eyes /////////////////////////////////////////////////////////////
/////////////////////////////

eyeTimer.onTimer () {
	mouseX=Main.getMousePosX();
	mouseY=Main.getMousePosY();
	float targetX, targetY, angleL, angleR, hypotL, hypotR;

	int diffX=mouseX-102;
	int diffY=mouseY-128;
	hypotL=pow((pow(diffX, 2) + pow(diffY, 2)), 0.5);
	if (hypotL > 18 || hypotL < -18) {
		if (diffY < 0) {
			angleL=(atan(diffX/diffY)*(180/3.14159265));
			targetX=102-(sin(angleL*(3.14159265/180))*15);
			targetY=128-(cos(angleL*(3.14159265/180))*15);
		} else if (diffY > 0) {
			angleL=(atan(diffX/diffY)*(180/3.14159265));
			targetX=102-(sin(angleL*(3.14159265/180))*(-15));
			targetY=128+(cos(angleL*(3.14159265/180))*15);
		}
	} else {
		targetY=mouseY;
		targetX=mouseX;
	}
	leftI.setTargetY(targetY);
	leftI.setTargetX(targetX);
	leftI.gotoTarget();

	int diffX=mouseX-151;
	int diffY=mouseY-128;
	hypotR=pow((pow(diffX, 2) + pow(diffY, 2)), 0.5);
	if (hypotR > 18 || hypotR < -18) {
		if (diffY < 0) {
			angleR=(atan(diffX/diffY)*(180/3.14159265));
			targetX=151-(sin(angleR*(3.14159265/180))*15);
			targetY=128-(cos(angleR*(3.14159265/180))*15);
		} else if (diffY > 0) {
			angleR=(atan(diffX/diffY)*(180/3.14159265));
			targetX=151-(sin(angleR*(3.14159265/180))*(-15));
			targetY=128+(cos(angleR*(3.14159265/180))*15);
		}
	} else {
		targetY=mouseY;
		targetX=mouseX;
	}
	rightI.setTargetY(targetY);
	rightI.setTargetX(targetX);
	rightI.gotoTarget();
}

/////////////////////////////
/// Seeking Control /////////////////////////////////////////////////////////
/////////////////////////////

seekTimer.onTimer () {
	length=getPlayItemLength();
	int position=(getPosition()/length)*40;
	seekImage.gotoFrame(position);
}

seekImage.onLeftButtonDown (int x, int y) {
	if ((Strleft(getPlayItemString(), 4) == "http") || (getPlayItemLength() <= 0)) {
		return;
	} else {
		clicked=1;
		seekTimer.stop();
	}
}

seekImage.onMouseMove (int x, int y) {
	if (clicked == 1) {
		int position=((x-30)/200)*40;
		if (position > 40) {position=40;}
		if (position < 0) {position=0;}
		seekImage.gotoFrame(position);
	}
}

seekImage.onLeftButtonUp (int x, int y) {
	if (clicked == 1) {
		clicked=0;
		x=x-seekImage.getLeft();
		int position=(x/seekImage.getWidth())*getPlayItemLength();
		seekTo(position);
		seekTimer.start();
	}
}

/////////////////////////////
/// Volume Control /////////////////////////////////////////////////////////
/////////////////////////////

System.onVolumeChanged (int newVol) {
	Volume.gotoFrame((Volume.getLength()-1)*(newVol/255));
}

Volume.onLeftButtonDown (int x, int y) {
	Float v;
	y=y-Volume.getTop();
	v=y/Volume.getHeight();
	System.setVolume(255-(v*255));
	v=v*(Volume.getLength()-1);
	Volume.gotoFrame((Volume.getLength()-1)-v);
	change=1;
	fadeIn=1;
	fadeOut=0;
	doNotSet=0;
	startFadeIn();
}

Volume.onLeftButtonUp (int x, int y) {
	change=0;
	fadeIn=0;
	fadeOut=1;
	startFadeOut();
}

Volume.onMouseMove (int x, int y) {
	if (change == 1) {
		if  ((x >= 2) && (x <= 29) && (y >= 89) && (y <= 171)) {
			Float v;
			y=y-Volume.getTop();
			v=y/Volume.getHeight();
			System.setVolume(255-(v*255));
			v=v*(Volume.getLength()-1);
			Volume.gotoFrame((Volume.getLength()-1)-v);
		}
	}
}

Volume.onFrame (int n) {
	Float level;
	level=n;
	level=(level/(Volume.getLength()-1))*255;

	VolBg.gotoFrame(Volume.getCurFrame());
}

/////////////////////////////
/// Button Animation ///////////////////////////////////////////////////////
/////////////////////////////

crossfadeButton.onEnterArea () {
	if (crossfadeStatus == 1) {
		crossfade.gotoFrame(1);
	} else {
		crossfade.gotoFrame(4);
	}
}

crossfadeButton.onLeaveArea () {
	if (crossfadeStatus == 1) {
		crossfade.gotoFrame(0);
	} else {
		crossfade.gotoFrame(3);
	}
}

crossfadeButton.onLeftButtonDown (int x, int y) {
	if (crossfadeStatus == 1) {
		crossfade.gotoFrame(2);
	} else {
		crossfade.gotoFrame(5);
	}
}

crossfadeButton.onLeftButtonUp (int x, int y) {
	if (crossfadeStatus == 1) {
		crossfade.gotoFrame(1);
	} else {
		crossfade.gotoFrame(3);
	}
}

crossfadeButton.onToggle (int onoff) {
	String cmd;
	cmd = "crossfade_enable";
	if (MainComp) {
		MainComp.sendCommand(cmd, onoff, 0,"");
		if (onoff) {
			crossfade.gotoFrame(1);
			crossfadeStatus=1;
		} else {
			crossfade.gotoFrame(4);
			crossfadeStatus=0;
		}
	}
}


shuffleButton.onEnterArea () {
	if (shuffleStatus == 1) {
		shuffle.gotoFrame(4);
	} else {
		shuffle.gotoFrame(1);
	}
}

shuffleButton.onLeaveArea () {
	if (shuffleStatus == 1) {
		shuffle.gotoFrame(3);
	} else {
		shuffle.gotoFrame(0);
	}
}

shuffleButton.onLeftButtonDown (int x, int y) {
	if (shuffleStatus == 1) {
		shuffle.gotoFrame(5);
	} else {
		shuffle.gotoFrame(2);
	}
}

shuffleButton.onLeftButtonUp (int x, int y) {
	if (shuffleStatus == 1) {
		shuffle.gotoFrame(3);
	} else {
		shuffle.gotoFrame(1);
	}
}

shuffleButton.onToggle (int onoff) {
	String cmd;
	cmd = "shuffle";
	if (Playlist) {
		Playlist.sendCommand(cmd, onoff, 0,"");
		if (onoff) {
			shuffle.gotoFrame(4);
			shuffleStatus=1;
		} else {
			shuffle.gotoFrame(1);
			shuffleStatus=0;
		}
	}
}


loopButton.onEnterArea () {
	if (loopStatus == 1) {
		loop.gotoFrame(4);
	} else {
		loop.gotoFrame(1);
	}
}

loopButton.onLeaveArea () {
	if (loopStatus == 1) {
		loop.gotoFrame(3);
	} else {
		loop.gotoFrame(0);
	}
}

loopButton.onLeftButtonDown (int x, int y) {
	if (loopStatus == 1) {
		loop.gotoFrame(5);
	} else {
		loop.gotoFrame(2);
	}
}

loopButton.onLeftButtonUp (int x, int y) {
	if (loopStatus == 1) {
		loop.gotoFrame(3);
	} else {
		loop.gotoFrame(1);
	}
}

loopButton.onToggle (int onoff) {
	String cmd;
	cmd = "repeat";
	if (Playlist) {
		Playlist.sendCommand(cmd, onoff, 0,"");
		if (onoff) {
			loop.gotoFrame(4);
			loopStatus=1;
		} else {
			loop.gotoFrame(1);
			loopStatus=0;
		}
	}
}

Open.onEnterArea() {startAnimation(Open, Open.getCurFrame(), 9, 30);}
Open.onLeaveArea() {startAnimation(Open, Open.getCurFrame(), 0, 30);}
Open.onLeftButtonUp(int x, int y) {gotoFrame(9);}
Open.onLeftButtonDown(int x, int y) {startAnimation(Open, 9, 0, 30);Eject.leftClick();}

Stop.onEnterArea() {startAnimation(Stop, Stop.getCurFrame(), 8, 30);}
Stop.onLeaveArea() {startAnimation(Stop, Stop.getCurFrame(), 0, 30);}
Stop.onLeftButtonUp(int x, int y) {gotoFrame(8);}
Stop.onLeftButtonDown(int x, int y) {gotoFrame(8);System.Stop();}

Previous.onEnterArea () {startAnimation(Previous, Previous.getCurFrame(), 8, 30);}
Previous.onLeaveArea () {startAnimation(Previous, Previous.getCurFrame(), 0, 30);}
Previous.onLeftButtonUp (int x, int y) {gotoFrame(8);}
Previous.onLeftButtonDown (int x, int y) {gotoFrame(8);System.Previous();}

Pause.onEnterArea() {startAnimation(Pause, Pause.getCurFrame(), 8, 30);}
Pause.onLeaveArea() {startAnimation(Pause, Pause.getCurFrame(), 0, 30);}
Pause.onLeftButtonUp(int x, int y) {gotoFrame(8);}
Pause.onLeftButtonDown(int x, int y) {gotoFrame(8);System.Pause();}

Play.onEnterArea() {startAnimation(Play, Play.getCurFrame(), 8, 30);}
Play.onLeaveArea() {startAnimation(Play, Play.getCurFrame(), 0, 30);}
Play.onLeftButtonUp(int x, int y) {gotoFrame(8);}
Play.onLeftButtonDown(int x, int y) {gotoFrame(8);System.Play();}

Next.onEnterArea() {startAnimation(Next, Next.getCurFrame(), 8, 30);}
Next.onLeaveArea() {startAnimation(Next, Next.getCurFrame(), 0, 30);}
Next.onLeftButtonUp(int x, int y) {gotoFrame(8);}
Next.onLeftButtonDown(int x, int y) {gotoFrame(8);System.Next();}

/////////////////////////////
/// Misc Functions //////////////////////////////////////////////////////////
/////////////////////////////

startAnimation (AnimatedLayer l, int start, int end, int speed) {
	l.stop();
	l.setStartFrame(start);
	l.setEndFrame(end);
	l.setSpeed(speed);
	l.setAutoReplay(0);
	l.play();
}

startFadeOut () {
	time1.start();
}

startFadeIn () {
	time2.start();
}

time1.onTimer() {
	VolBg.setAlpha(VolBg.getAlpha()-15);
	if ((VolBg.getAlpha() > 0) && (fadeOut == 1)) {
		startFadeOut();
	} else {
		time1.stop();
		fadeOut=0;
	}
}

time2.onTimer() {
	VolBg.setAlpha(VolBg.getAlpha()+15);
	if ((VolBg.getAlpha() < 255) && (fadeIn == 1)) {
		startFadeIn();
	} else {
		time2.stop();
		fadeIn=0;
	}
}