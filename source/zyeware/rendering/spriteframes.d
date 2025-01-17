module zyeware.rendering.spriteframes;

import std.datetime : dur, Duration;
import std.conv : to;

import sdlang;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class SpriteFrames
{
private:
    Animation[string] mAnimations;

public:
    /// Represents a single animation.
    struct Animation
    {
        size_t startFrame; /// On which frame to start the animation.
        size_t endFrame; /// Which frame to display last.
        Duration frameInterval; /// Determines how long a frame stays until it advances to the next one.
        bool isLooping; /// If the animation should loop after the last frame.
    }

    /// Adds an animation.
    ///
    /// Params:
    ///     name = The name of the animation to add.
    ///     animation = The animation to add.
    void addAnimation(string name, Animation animation) pure nothrow
        in (name, "Name cannot be null.")
        in (animation.startFrame < animation.endFrame, "Start frame cannot be after end frame!")
        in (animation.frameInterval > Duration.zero, "Frame interval must be greater than zero!")
    {
        mAnimations[name] = animation;
    }

    /// Removes an animation.
    ///
    /// Params:
    ///     name = The name of the animation to remove.
    void removeAnimation(string name) pure nothrow
        in (name, "Name cannot be null.")
    {
        mAnimations.remove(name);
    }

    /// Returns the animation with the given name.
    ///
    /// Params:
    ///     name = The name of the animation to return.
    /// Returns: Pointer to the animation if found, `null` otherwise.
    Animation* getAnimation(string name) pure
        in (name, "Name cannot be null.")
    {
        return name in mAnimations;
    }

    static SpriteFrames load(string path)
        in (path, "Path cannot be null")
    {
        scope VFSFile file = VFS.getFile(path);
        Tag root = parseSource(file.readAll!string);
        file.dispose();

        auto spriteFrames = new SpriteFrames();

        foreach (Tag animationTag; root.all.tags)
        {
            Animation animation;

            animation.startFrame = animationTag.expectTagValue!int("start").to!size_t;
            animation.endFrame = animationTag.expectTagValue!int("end").to!size_t;
            animation.frameInterval = dur!"msecs"(animationTag.expectTagValue!int("interval-msecs"));
            animation.isLooping = animationTag.getTagValue!bool("loop", false);

            spriteFrames.addAnimation(animationTag.name, animation);
        }

        return spriteFrames;
    }
}