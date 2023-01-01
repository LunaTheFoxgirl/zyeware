# ZyeWare roadmap
A lot of stuff has already been done before this file has been started.

[X] Add more profiling information
[X] Add Gamepad input
[X] Possibly merge Context and Window
[X] Implement Mesh loading and rendering
[X] Improve 3D renderer (add batching/instancing, at least render sorting)
[X] Possibly improve 2D renderer performance
[X] Add terrain rendering
[X] Add terrain height checking
[X] Easier material handling (Especially file loading)
[X] Materials should have parenting again
[X] Cameras should have no transformation info, delegate to TransformXDComponent
    - Camera should have helper function ala `getViewMatrix(transform, rotation)`
[X] TransformXDComponent should have globalPosition and position, globalRotation and rotation etc.
[X] Fix Render3D system
[X] Implement better input abstraction
[X] Make part of Profiling accessible in release builds
[X] Separate draw and tick methods for ECS systems
[X] Add SDL as abstraction layer (opens many more platforms!) (maybe dump GLFW?)
[X] For all glGen* and alGen*, check if was actually created
[X] Add more custom Exception types
[X] Look into better audio options (Added OpenAL)
[X] Fix Interpolator
[X] Renderer take setAttribute instead of separate properties
[X] Wireframe mode (glPolygonMode(GL_FRONT_AND_BACK, _wireframe ? GL_LINE : GL_FILL);)


[ ] Rewrite to not use Garbage Collector!!! (with dplug.core.nogc and stf.typecons.RefCounted)
    This is important, we're facing memory leaks here!
    Use https://code.dlang.org/packages/dlib

[ ] Finish Particles
[ ] Work on UI
[ ] Replace Algebraic with SumType
[ ] Implement texture atlases in 3D meshes
[ ] Add CLI (like Angular)
[ ] Update docstrings, add header to all source files
[ ] Possibly move all asset loaders to a package
[ ] Add further mesh loading options (https://code.dlang.org/packages/gltf2loader)
[ ] Add streaming audio
[ ] Port to PS Vita
[ ] Add unittests where appropriate
[ ] Implement TTF font rendering (Improve font rendering as a whole?) (Use SDL_TTF!)