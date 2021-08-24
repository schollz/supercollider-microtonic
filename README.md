# supercollider-microtonic

One of my favorite drum machines is the [Microtonic VST by SonicCharge](https://soniccharge.Com/microtonic). I have this VST and I use it a lot, but I was hoping to control it via OSC in SuperCollider so I sought to port it to SuperCollider. Namely, I really wanted to use this sound in [norns](https://monome.org/#norns). I ended up getting very close (I think) and made a norns script using these sounds called "[supertonic](https://schollz.com/blog/supertonic/)".

You can use this repository by opening `microtonic.scd`. It will open up a `SynthDef` with the basic parameters, and then some example presets and an example euclidean drum sequencer.

### Demo

Here's a direct comparison between the SuperCollider port and Microtonic on some random presets: https://vimeo.com/591627963.


### Importing presets

I included a Lua script that you can use to convert your Microtonic presets into SuperCollider code automatically. Simply run:

```bash
lua mtpreset2sc.lua /location/to/microtonic/preset > preset.scd
```

## More information


For more information about this port, check out [my blog](https://schollz.com/blog/microtonic).

## License

MIT