// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.image;

import imagefmt;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Image
{
protected:
    const(ubyte[]) mPixels;
    ubyte mChannels;
    ubyte mBitsPerChannel;
    Vector2i mSize;

public:
    this(in ubyte[] pixels, ubyte channels, ubyte bitsPerChannel, Vector2i size) pure nothrow
        in (size.x > 0 && size.y > 0, "Image must be at least 1x1.")
        in (pixels && pixels.length == size.x * size.y * channels, "Invalid amount of pixels.")
        in (channels > 0 && channels <= 4, "Invalid amount of channels.")
        in (bitsPerChannel > 0 && bitsPerChannel <= 8, "Invalid amount of bits per channel.")
    {
        mPixels = pixels;
        mChannels = channels;
        mBitsPerChannel = bitsPerChannel;
        mSize = size;
    }

    Color getPixel(Vector2i coords) pure const nothrow
    {
        if (coords.x < 0 || coords.y < 0 || coords.x >= mSize.x || coords.y >= mSize.y)
            return Color.black;
        
        ubyte r = 0, g = 0, b = 0, a = 255;
        size_t channelStart = (coords.y * mSize.x + coords.x) * mChannels;

        // Careful, fallthrough.
        switch (mChannels)
        {
        case 4:
            a = pixels[channelStart + 3];
            goto case;

        case 3:
            b = pixels[channelStart + 2];
            goto case;

        case 2:
            g = pixels[channelStart + 1];
            goto case;

        case 1:
            r = pixels[channelStart];
            break;

        default:
        }

        return Color(r / 255f, g / 255f, b / 255f, a / 255f);
    }

    const(ubyte[]) pixels() pure const nothrow
    {
        return mPixels;
    }

    ubyte channels() pure const nothrow
    {
        return mChannels;
    }

    ubyte bitsPerChannel() pure const nothrow
    {
        return mBitsPerChannel;
    }

    Vector2i size() pure const nothrow
    {
        return mSize;
    }

    static Image load(string path)
        in (path, "Path cannot be null.")
    {
        scope VFSFile file = VFS.getFile(path);

        ubyte[] data = new ubyte[file.size];
        file.read(data);
        file.dispose();

        IFImage img = read_image(data);
        data.dispose();

        return new Image(img.buf8, img.c, img.bpc, Vector2i(img.w, img.h));
    }

    static Image load(in ubyte[] data)
    {
        IFImage img = read_image(data);

        return new Image(img.buf8, img.c, img.bpc, Vector2i(img.w, img.h));
    }
}