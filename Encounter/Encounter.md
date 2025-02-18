# Encounter - 256 bytes intro for WASM MicroW8 fantasy console

## What is it?

Attempt to bring a cinematic experience in 256 bytes.

## Watch

You can watch it on YouTube (recommended to select 720p60 quality) 

[![Watch the video](https://img.youtube.com/vi/4QY9WqbS61g/maxresdefault.jpg)](https://www.youtube.com/watch?v=4QY9WqbS61g)

or click the following link if you have the FireFox browser (Chrome’s implementation of WebAssembly has much worse performance). Mobile Firefox should also work well on relatively new mobile phones. The 256 bytes are encoded in the URL:

[https://exoticorn.github.io/microw8/v0.2.2/#AgMvvqs+jH95brXMAYjUjZwn1apTrm62ncvO+qq+kAesx0vh5NB3sa3YEg8JasHVk0OOFeN09Qi/yWyEuuIHweJv5+qt4lQhS0q/exKHo4rtSsnqkY7oWUwXXgbWfGEwKrTto4wxOG4JXZck7ehBB9YHmyanOZxFZeCkpib2M/JXhCmCfPb3mF6tq++ZG2Mm73NopaaKwUFHm2KjpEjYFMEzCZsu98uZmvhD5GzCUXSw8G5Z1V8nfv9uiIQ1+5N+rcjpFezbIXG5/haUR7Lnre3xZVJcp+I6rXkboKqK6SoG5h92w/jndB3sdZyT4G9Lq872lkEkUIM7ciqdsyYJMg==](https://exoticorn.github.io/microw8/v0.2.2/#AgMvvqs+jH95brXMAYjUjZwn1apTrm62ncvO+qq+kAesx0vh5NB3sa3YEg8JasHVk0OOFeN09Qi/yWyEuuIHweJv5+qt4lQhS0q/exKHo4rtSsnqkY7oWUwXXgbWfGEwKrTto4wxOG4JXZck7ehBB9YHmyanOZxFZeCkpib2M/JXhCmCfPb3mF6tq++ZG2Mm73NopaaKwUFHm2KjpEjYFMEzCZsu98uZmvhD5GzCUXSw8G5Z1V8nfv9uiIQ1+5N+rcjpFezbIXG5/haUR7Lnre3xZVJcp+I6rXkboKqK6SoG5h92w/jndB3sdZyT4G9Lq872lkEkUIM7ciqdsyYJMg==) 

I personally love seeing creative process of the others (“making of”) and If you are interested in the steps I went through to create this intro, check the following recording:

[![Watch the video](https://img.youtube.com/vi/X-g7d5NUV2s/mqdefault.jpg)](https://youtu.be/X-g7d5NUV2s)

## Play

I added also a **[JavaScript playground](https://ilmenit.github.io/sizecoding/Encounter/index.html)** so you can play with different parameters of this effect:

## Why?

I love intellectual challenges, art, computer science and in May 2024 there was another [Outline demoscene party](https://outlinedemoparty.nl) with size-coding competition. I did some 256 byte intros in the past (like drawing **[Mona Lisa](https://www.pouet.net/prod.php?which=62917)** for 6502 8bit Atari, ported to a [crazy number of platforms](https://codegolf.stackexchange.com/questions/126738/lets-draw-mona-lisa) or **[Thrive](https://www.pouet.net/prod.php?which=91578)** for TIC-80 showing a [growing tree through the seasons](https://youtu.be/qU5EGLvFXd8)), so I decided to join the competition once again.

If you don’t know what a demoscene is, it’s a computer subculture with roots in Europe [https://en.wikipedia.org/wiki/Demoscene](https://en.wikipedia.org/wiki/Demoscene) similar to [Hacker Camps](https://hackaday.com/2022/06/06/outline-2022-everyone-should-go-to-a-demo-party/). 

A large collection of demoscene productions you can find on [https://demozoo.org](https://demozoo.org/) or [https://www.pouet.net](https://www.pouet.net/) 

## How?

The intro is done for [MicroW8](https://exoticorn.github.io/microw8) platform, which is a [Fantasy Console](https://en.wikipedia.org/wiki/Fantasy_video_game_console) similar to [PICO-8](https://www.lexaloffle.com/pico-8.php), [TIC-80](https://tic80.com/) or [WASM-4](https://wasm4.org). 

MicroW8 has capabilities close to DOS-era machines (16 bit real-mode x86 with FPU and VGA):

* Screen: 320x240, 256 colors, 60Hz, customizable palette.
* Memory: 256KB

but with a MUCH faster CPU powered by WebAssembly (therefore more like running nowadays [FreeDOS](https://www.freedos.org) on a modern PC).

Important note: the compiled “virtual cartridge” is compressed, therefore 256 bytes is not equal to 256 bytes of WASM code. The WASM code needs to be interconnected with the MicroW8 platform and the compression negates this overhead, leading to (according to sizecoding gurus) “code density” in 256 bytes similar to uncompressed x86/FPU code. The compression brings more benefits the bigger the code/data is, however in x86 you can also make tiny code decompressors, that you cannot do easily in WebAssembly due to executable code space separation, therefore for size-constrained programming DOS with x86 and [all the tricks it offers](http://www.sizecoding.org/wiki/DOS) can still be the king.

## Commented code

WebAssembly is a stack-based virtual machine, which makes it easy to represent as an Abstract Syntax Tree or… in infix syntax. That’s the idea behind [CurlyWAS language](https://github.com/exoticorn/curlywas), that compiles Rust-like syntax into a WASM code.

CurlyWAS has ability to use keywords like “inline” (expression is evaluated every time, works similarly to C’s #define), or “lazy” (which uses the local.tee instruction which combines local.set and local.get and therefore saves on bytes). 

In WebAssembly the 32bit integers are encoded in [LEB128 format](https://en.wikipedia.org/wiki/LEB128) and CurlyWAS has sugar syntax of adding _f to a constant to convert integer to 32bit float:

(320_f) is equal to (320 as f32)

```
include "include/microw8-api.cwa"

export fn upd() {

  let fx: f32;
  let prev_wave_height: f32;
  let inline t: f32 = time();

  let inline screen_width = 320_f;
  let inline screen_height = 240_f; // 256_f shorter but bit slower

  loop xloop {
  
    let fy: f32 = 0_f;      
    loop yloop {

      // define the vanishing point coordinates
      let inline vp_x: f32 = 160_f; // center of the screen
      let inline vp_y: f32 = 120.5; // horizon, +0.5 to avoid div by 0

      // define the distance
      let inline d: f32 = 160_f; 

      // calculate the distance from the center
      let inline cx: f32 = vp_x - fx; 
      let inline cy: f32 = vp_y - fy; 
    
      // calculate the angle mapping
      let inline nx: f32 = cx / 2_f / cy; 
      let inline ny: f32 =  d * 2_f / cy;
    
      // A variable to store the total height
      let wave_height = cos(fx*fy)*max(0_f,t-80_f); // matrix-like effect at the end
    
      // Calculate the height of the superposition of waves at a given position and time
      let i: f32=0_f;
    
      // select either water or sky
      let inline iterations: f32 = select(fy<120_f,4_f,16_f);
    
      loop wave_iterations {    
      
        let inline amplitude = i/40_f;
        let inline frequency = 2_f+cos(i);
        let inline phase = cos(i*i);
        // dx and dy are the components of the direction of the wave
        let inline dx = sin(i*i); // serves as PRNG
        let inline dy = cos(i*i*i); // serves as PRNG
        let inline time_shift = t/14_f*iterations;
    
        wave_height -= amplitude * (abs(sin(frequency * (ny * dy + nx * dx) + time_shift + phase)));        
    
        branch_if (i := i + 1_f) < iterations: wave_iterations; 
      }
      let inline dist = sqrt(cx*cx + cy*cy);    
      
      // how big are waves in time
      let inline wave_scale = min(2_f*t,40_f);        
      let inline perspective_height = wave_height * wave_scale * cy / d;   
    
      // minimalistic water reflection+refraction
      let inline h_color: f32 = 1_f-abs(perspective_height-prev_wave_height)/6_f;      
    
      // alien blob/ship
      let inline radius = min(2_f*t-70_f,50_f); 
      let inline blob_color = dist/radius;
      let inline color: f32 = select(dist<radius,blob_color,h_color);
      
      // add cinematic vignette effect (dist) with a bit of fresnel effect (cy)
      let inline p_color = max(0_f,color+(cy-dist)/512_f);
    
      // draw lines also for blob to imitate reflection
      line(fx, fy + perspective_height, fx, fy + prev_wave_height, (255_f*p_color) as i32);
      prev_wave_height = perspective_height;
    
      branch_if (fy := fy + 1_f) < screen_height: yloop;
    }   
    
    // set ocean palette with a bit of yellow tint
    let inline index = (fx as i32) % 128;
    let inline i = 4*index;
    i!0x13000 =  0x030200*(index/4);
    i!0x13200 =  0x020304*(index/2)+0x604000;
    
    branch_if (fx := fx + 1_f) < screen_width: xloop;   
  } 
}
```
