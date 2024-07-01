# Game development with Beef
This repo contains libraries, frameworks, and guides for starter. Unlike zig-gamedev, I only focus on hobby/indie gamedev, so this repo prefer simple, ergonomic high-level, yolo coding solutions other than high-performance, low-level graphics, ECS, DoD (which is can archieve with Beef by default).


## Disclaimer
- This repo focus on hobby/indie games, may not work with bigger games (gacha, moba, AAA)
- Please this for reference only, not the source of truth (still researching)
- For general purpose programming, see this [awesome list](https://github.com/Jonathan-Racaud/awesome-beef)


## Programming language guides
- If you have experience with C++ and C#, Beef is not hard from the beginning.
- Just read through all the [docs](https://www.beeflang.org/docs/foreward/) (which is short), you will have based knowledge of syntax and semantic.
- Have some practices and experimentals, like [I did](https://github.com/maihd/FunWithBeef). Now you can coding fluently with Beef. That's well enough to start developing game.


## Beef advantages for gamedev
- Check out the [design goals](https://www.beeflang.org/docs/foreward/) of Beef
- Full syntax of C# with C++ semantic (two familiar/main-stream programming languages for gamedev)
- Syntaxes for ergonomic gameplay coding: tagged union, pattern matching, comptime, comptime codegen
- Fast code compile, hot code reloading, immediate change when changing gameplay code (fast iteration development)
- C/C++ interop, easy bindings existing game libraries
- Realtime memory leaks detection, optional safety check on expressions, distinct build
- IDE support for generation file with Beef (like Unity support custom editor with C#)


## Libraries
Only contains libraries which are should used:
- Raylib Beef bindings ([origin version](https://github.com/M0n7y5/raylib-beef), [MaiHD fork](https://github.com/maihd/raylib-beef))
- [Linq](https://github.com/disarray2077/Beef.Linq) (for functional programming)
- [Dear ImGui](https://github.com/RogueMacro/imgui-beef)
- [Json](https://github.com/EinScott/json)


## Frameworks
Create new framework or using existing:
- Use modules from this repo (which I called Gamefx)
- Roll your own based on existing framework/engine: MonoGame (Stardew Valley, Bastion, Celeste), [deepnightLibs](https://github.com/deepnight/deepnightLibs) (use in Dead Cells), SexyAppFramework (Popcap Games), Cocos2d-x (Many many mobile games), ...
- Underhood rendering, audio, IO: 
    - Just use Raylib from beginning
    - Use extension features of Beef to wrap code, in the long-term, you can change your system without change gameplay code
- Modules:
    - Tweening (use comptime reflection to avoid runtime overhead)
    - Timer: middle-level actions scheduler
    - Input bindings: action/callback bindings per input type (only Raylib now)
    - LDtk: parsing the file
- Wishlist modules:
    - Full framework (include all modules, deps)
    - StalkerX: Camera control
    - Windfield: Physics and simulations (high-level wrapper for existing physics engine)
    - LDtk: high-level rendering for common framework, high-level usage like entity/class generation
    - Resources caching, assets flow in game runtime (ie: load and cache texture, sound)
    - Package reader: famous .pak format, raylib's rres
    - Simple and fast allocator (Arena central memory allocations)
- Existing framework:
    - [Pile](https://github.com/EinScott/Pile)
    - [Strawberry (unmaintained)](https://github.com/MaddyThorson/StrawberryBF)
    - [Raylib Beef generator (nearly with C version, no extensions)](https://github.com/Starpelly/raylib-beef)


## Tools
- Beef IDE
- [LDtk](https://ldtk.io/)
- [Asesprite](https://www.aseprite.org/) pixel art editor
- [Pixi](https://foxnne.github.io/pixi/) free pixel art editor
- [Raylib tooling set](https://raylibtech.itch.io/)
- [Raylib's rres](https://github.com/raysan5/rres)


## Games made by Beef
- [Evening Star's Penny's Big Breakaway](https://www.youtube.com/watch?v=1hAgpRYM2M8&pp=ygUVcGVubnkncyBiaWcgYnJlYWthd2F5)
- [Motion Melody](https://store.steampowered.com/app/2175480/Motionmelody/)
- [NeonShooter](https://github.com/maihd/neonshooter/tree/raylib-beef)


## Cross-platform
- Beef work well with Windows (main-stream PC platform, also a starter platform for indie gamedev)
- Can build for mobile, but no production show case
- Wasm for Web platform, which also a priority target platform of Beef
- I have no experience for on gaming console, but [Evening Star's Penny's Big Breakaway](https://www.youtube.com/watch?v=1hAgpRYM2M8&pp=ygUVcGVubnkncyBiaWcgYnJlYWthd2F5) proof it [worked](https://steamcommunity.com/app/1955230/discussions/0/4346606879517102842)


## Source code license
MIT License. Copyright (c) 2024 MaiHD. Detais in [LICENSE](/LICENSE).