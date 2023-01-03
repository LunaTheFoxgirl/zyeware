// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.application;

import core.memory : GC;
import std.exception : enforce, collectException;
import std.algorithm : min;
import std.typecons : Nullable;
import std.uuid : UUID, sha1UUID;

public import zyeware.core.gamestate;
import zyeware.common;
import zyeware.utils.collection;
import zyeware.rendering;

/// Represents an application that can be run by ZyeWare.
/// To write a ZyeWare app, you must inherit from this class and return an
/// instance of it with the `createZyeWareApplication` function.
///
/// Examples:
/// --------------------
/// class MyApplication : Application
/// {
///     ...    
/// }
///
/// extern(C) Application createZyeWareApplication(string[] args)
/// {
///     return new MyApplication(args);   
/// }
/// --------------------
abstract class Application
{
protected:
    string[] mProgramArgs;
    
    this(string[] programArgs) pure nothrow
        in (programArgs, "Program arguments cannot be null.")
    {
        mProgramArgs = programArgs;
    }

public:
    /// Override this method for application initialization.
    abstract void initialize();

    /// Override this method to perform logic on every frame.
    abstract void tick(in FrameTime frameTime);

    /// Override this method to perform rendering.
    abstract void draw(in FrameTime nextFrameTime);

    /// Override this method to return the window properties of the main window.
    abstract WindowProperties getWindowProperties();

    /// Destroys the application.
    void cleanup() {}
    
    /// Handles the specified event in whatever manners seem appropriate.
    ///
    /// Params:
    ///     ev = The event to handle.
    void receive(in Event ev)
        in (ev, "Received event cannot be null.")
    {
        if (cast(QuitEvent) ev)
            ZyeWare.quit();
    }

    /// The frame rate the application should target to hold. This is not a guarantee.
    uint targetFramerate() pure const nothrow
    {
        return 60;
    }

    /// The arguments this application was started with.
    /// These are the same as the ones ZyeWare was started with, but stripped of
    /// engine-specific arguments.
    const(string[]) programArgs() pure const nothrow
    {
        return mProgramArgs;
    }

    UUID uuid() pure const nothrow
    {
        return sha1UUID(typeid(this).name);
    }
}

/// A ZyeWare application that takes care of the game state logic.
/// Game states can be set, pushed and popped.
class GameStateApplication : Application
{
protected:
    GrowableStack!GameState mStateStack;

    this(string[] programArgs)
    {
        super(programArgs);
    }

public:
    override void receive(in Event ev)
        in (ev, "Received event cannot be null.")
    {
        super.receive(ev);

        if (hasState)
            currentState.receive(ev);
    }

    override void tick(in FrameTime frameTime)
    {
        if (hasState)
            currentState.tick(frameTime);
    }

    override void draw(in FrameTime nextFrameTime)
    {
        if (hasState)
            currentState.draw(nextFrameTime);
    }

    /// Change the current state to the given one.
    ///
    /// Params:
    ///     state = The game state to switch to.
    void changeState(GameState state)
        in (state, "Game state cannot be null.")
    {
        if (hasState)
            mStateStack.pop().onDetach();
        
        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        GC.collect();
    }

    /// Pushes the given state onto the stack, and switches to it.
    ///
    /// Params:
    ///     state = The state to push and switch to.
    void pushState(GameState state)
        in (state, "Game state cannot be null.")
    {
        if (hasState)
            currentState.onDetach();
        
        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        GC.collect();
    }

    /// Pops the current state from the stack, restoring the previous state.
    void popState()
    {
        if (hasState)
            mStateStack.pop().onDetach();
        
        currentState.onAttach(!currentState.mWasAlreadyAttached);
        currentState.mWasAlreadyAttached = true;
        GC.collect();
    }

    pragma(inline, true)
    GameState currentState()
    {
        return mStateStack.peek;
    }

    pragma(inline, true)
    bool hasState() const nothrow
    {
        return !mStateStack.empty;
    }
}
