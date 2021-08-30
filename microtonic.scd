// 1. define the microtonic engine
(
SynthDef("microtonic", {
	arg out,
	mix=50,level=(-5),distAmt=2,
	eQFreq=632.4,eQGain=(-20),
	oscAtk=0,oscDcy=500,
	oscWave=0,oscFreq=54,
	modMode=0,modRate=400,modAmt=18,
	nEnvAtk=26,nEnvDcy=200,
	nFilFrq=1000,nFilQ=2.5,
	nFilMod=0,nEnvMod=0,nStereo=1,
	oscLevel=1,nLevel=1,
	oscVel=100,nVel=100,modVel=100,
	fx_lowpass_freq=20000,fx_lowpass_rq=1,
	vel=64;

	// variables
	var osc,noz,nozPostF,snd,pitchMod,nozEnv,numClaps,oscFreeSelf,wn1,wn2,clapFrequency,decayer;

	// convert to seconds from milliseconds
	vel=LinLin.kr(vel,0,128,0,2);
	oscAtk=DC.kr(oscAtk/1000);
	oscDcy=DC.kr(oscDcy/1000);
	nEnvAtk=DC.kr(nEnvAtk/1000);
	nEnvDcy=DC.kr(nEnvDcy/1000*1.4);
	level=DC.kr(level);
	// add logistic curve to the mix
	mix=DC.kr(100/(1+(2.7182**((50-mix)/8))));
	// this is important at low freq
	oscFreq=oscFreq+5;

	// white noise generators (expensive)
	wn1=WhiteNoise.ar();
	wn2=WhiteNoise.ar();
	wn1=Clip.ar(wn1*100,-1,1);
	wn2=Clip.ar(wn2*100,-1,1);
	clapFrequency=DC.kr((4311/(nEnvAtk*1000+28.4))+11.44); // fit using matlab
	// determine who should free
	oscFreeSelf=DC.kr(Select.kr(((oscAtk+oscDcy)>(nEnvAtk+nEnvDcy)),[0,2]));

	// define pitch modulation1
	pitchMod=Select.ar(modMode,[
		Decay.ar(Impulse.ar(0.0001),(1/(2*modRate))), // decay
		SinOsc.ar(-1*modRate), // sine
		Lag.ar(LFNoise0.ar(4*modRate),1/(4*modRate)), // random
	]);

	// mix in the the pitch mod
	pitchMod=pitchMod*modAmt/2*(LinLin.kr(modVel,0,200,2,0)*vel);
	oscFreq=((oscFreq).cpsmidi+pitchMod).midicps;

	// define the oscillator
	osc=Select.ar(oscWave,[
		SinOsc.ar(oscFreq),
		LFTri.ar(oscFreq,mul:0.5),
		SawDPW.ar(oscFreq,mul:0.5),
	]);
	osc=Select.ar(modMode>1,[
		osc,
		SelectX.ar(oscDcy<0.1,[
			LPF.ar(wn2,modRate),
			osc,
		])
	]);


	// add oscillator envelope
	decayer=SelectX.kr(distAmt/100,[0.05,distAmt/100*0.3]);
	osc=osc*EnvGen.ar(Env.new([0.0001,1,0.9,0.0001],[oscAtk,oscDcy*decayer,oscDcy],\exponential),doneAction:oscFreeSelf);

	// apply velocity
	osc=(osc*LinLin.kr(oscVel,0,200,1,0)*vel).softclip;

	// generate noise
	noz=wn1;

	// optional stereo noise
	noz=Select.ar(nStereo,[wn1,[wn1,wn2]]);


	// define noise envelope
	nozEnv=Select.ar(nEnvMod,[
		EnvGen.ar(Env.new(levels: [0.001, 1, 0.0001], times: [nEnvAtk, nEnvDcy],curve:\exponential),doneAction:(2-oscFreeSelf)),
		EnvGen.ar(Env.new([0.0001,1,0.9,0.0001],[nEnvAtk,nEnvDcy*decayer,nEnvDcy*(1-decayer)],\linear)),
		Decay.ar(Impulse.ar(clapFrequency),1/clapFrequency,0.85,0.15)*Trig.ar(1,nEnvAtk+0.001)+EnvGen.ar(Env.new(levels: [0.001, 0.001, 1,0.0001], times: [nEnvAtk,0.001, nEnvDcy],curve:\exponential)),
	]);

	// apply noise filter
	nozPostF=Select.ar(nFilMod,[
		BLowPass.ar(noz,nFilFrq,Clip.kr(1/nFilQ,0.5,3)),
		BBandPass.ar(noz,nFilFrq,Clip.kr(2/nFilQ,0.1,6)),
		BHiPass.ar(noz,nFilFrq,Clip.kr(1/nFilQ,0.5,3))
	]);
	// special Q
	nozPostF=SelectX.ar((0.1092*(nFilQ.log)+0.0343),[nozPostF,SinOsc.ar(nFilFrq)]);

	// apply envelope to noise
	noz=Splay.ar(nozPostF*nozEnv);

	// apply velocities
	noz=(noz*LinLin.kr(nVel,0,200,1,0)*vel).softclip;


	// mix oscillator and noise
	snd=SelectX.ar(mix/100*2,[
		noz*0.5,
		noz*2,
		osc*1
	]);

	// apply distortion
	snd=SineShaper.ar(snd,1.0,1+(10/(1+(2.7182**((50-distAmt)/8))))).softclip;

	// apply eq after distortion
	snd=BPeakEQ.ar(snd,eQFreq,1,eQGain/2);

	snd=HPF.ar(snd,20);

	snd=snd*level.dbamp*0.2;
	// free self if its quiet
	FreeSelf.kr((Amplitude.kr(snd)<0.001)*TDelay.kr(DC.kr(1),0.05));

	// apply some global fx
	snd=RLPF.ar(snd,fx_lowpass_freq,fx_lowpass_rq);

	// level
	Out.ar(0, snd);
}).add;
)




// 2. define the sounds
(
~er = { | o = 1, p = 16 |(o / p * (0..p - 1)).floor.differentiate.asInteger.min(1)[0] = if (o <= 0) { 0 } { 1 };};

~kicksound={Synth("microtonic",[
	\distAmt,34.064063429832,
	\eQFreq,80.661909666463,
	\eQGain,30.246815681458,
	\level,-5.1201522322287,
	\mix,88.153877258301,
	\modAmt,33.019509360458,
	\modMode,0,
	\modRate,4.0523291566457,
	\modVel,35.558253526688,
	\nEnvAtk,2.1977363693469,
	\nEnvDcy,1104.977660676,
	\nEnvMod,0,
	\nFilFrq,392.00617432122,
	\nFilMod,0,
	\nFilQ,1.463421337541,
	\nStereo,1,
	\nVel,40.751650929451,
	\oscAtk,0,
	\oscDcy,726.5732892423,
	\oscFreq,48.060961337325,
	\oscVel,38.951644301414,
	\oscWave,0,
])};
~hhsound={Synth("microtonic",[
	\distAmt,1.9999999552965,
	\eQFreq,111.80335896926,
	\eQGain,-36.059684753418,
	\level,0,
	\mix,0,
	\modAmt,0,
	\modMode,0,
	\modRate,2.8301886792453,
	\modVel,36.000001430511,
	\nEnvAtk,1.7076868541052,
	\nEnvDcy,90.509330260423,
	\nEnvMod,0,
	\nFilFrq,7447.9779098801,
	\nFilMod,2,
	\nFilQ,0.70710500896458,
	\nStereo,0,
	\nVel,43.002021312714,
	\oscAtk,0,
	\oscDcy,10,
	\oscFreq,20,
	\oscVel,40.999999642372,
	\oscWave,0,
])};
~sdsound={Synth("microtonic",[
	\distAmt,35.499998927116,
	\eQFreq,59.707651558903,
	\eQGain,-40,
	\level,-4.9999159382834,
	\mix,60.833332061768,
	\modAmt,23.346161411536,
	\modMode,2,
	\modRate,12662.482988632,
	\modVel,40.000000596046,
	\nEnvAtk,0,
	\nEnvDcy,439.39704746109,
	\nEnvMod,0,
	\nFilFrq,245.05603577429,
	\nFilMod,2,
	\nFilQ,148.37726231182,
	\nStereo,0,
	\nVel,40.999999642372,
	\oscAtk,0,
	\oscDcy,68.739970893796,
	\oscFreq,251.73534018926,
	\oscVel,33.000001311302,
	\oscWave,0,
])};
~clapsound={Synth("microtonic",[
	\distAmt,18.334101140499,
	\eQFreq,981.49547151245,
	\eQGain,28.736724853516,
	\level,-6.1622793557187,
	\mix,8.7251434326172,
	\modAmt,-48,
	\modMode,2,
	\modRate,10995.78120095,
	\modVel,27.000001072884,
	\nEnvAtk,34.526091455159,
	\nEnvDcy,199.32752864136,
	\nEnvMod,2,
	\nFilFrq,3571.0693697945,
	\nFilMod,1,
	\nFilQ,0.37636863434079,
	\nStereo,0,
	\nVel,25,
	\oscAtk,0.44352287396344,
	\oscDcy,1402.7378979947,
	\oscFreq,2459.9589879903,
	\oscVel,34.999999403954,
	\oscWave,0,
])};
)


// 3. define the rhythms
(
~kick=~er.(0);
~kick=~er.(2).rotate(2);
~kick=~er.(3).rotate(2)+~er.(1);
~hh={~er.(4).rotate(2)+~er.(7)};
~hh={~er.(14).rotate(2)};
~sd={~er.(2)+~er.(rrand(5,6)).rotate(2)};
~sd=~er.(0);
~sd={~er.(2)+~er.(6).rotate(2)};
~sd=~er.(2).rotate(6);
~sd=~er.(2).rotate(6)+~er.(1).rotate(5);
~clap={~er.(5)+~er.(2).rotate(3)-~er.(4,16)};
~clap=~er.(0);
~clap=~er.(2).rotate(4)+~er.(3).rotate(7);
)

// 4. let it go!
(
x=~kicksound.();
y=~hhsound.();
z=~sdsound.();
w=~clapsound.();
t.stop;
t = Task({
	var bpm=120;
	var beats=16;
	inf.do({ arg i;
		~rand56=rrand(5,6);
		if (~kick[i%beats]>0,{
			if (x.isPlaying,{
				x.free;
			});
			x=~kicksound.();
		});
		if (~hh.(1)[i%beats]>0,{
			if (y.isPlaying,{
				y.free;
			});
			y=~hhsound.();
		});
		if (~sd.(1)[i%beats]>0,{
			if (z.isPlaying,{
				z.free;
			});
			z=~sdsound.();
		});
		if (~clap.(1)[i%beats]>0,{
			if (w.isPlaying,{
				w.free;
			});
			w=~clapsound.();
		});
		(60/bpm/4).wait;
	});
}).play;
)

