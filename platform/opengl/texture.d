// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texture;

import bindbc.opengl;
import imagefmt;
import sdlang;

import zyeware.common;
import zyeware.rendering;

interface Texture
{
public:
    void bind(uint unit = 0) const;

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;
}

@asset(Yes.cache)
class Texture2D : Texture
{
protected:
    TextureProperties mProperties;
    Vector2i mSize;
    ubyte mChannels;
    uint mID;

public:
    this(in Image image, in TextureProperties properties)
    {
        const(ubyte)[] pixels = image.pixels;
        mSize = image.size;
        mChannels = image.channels;
        mProperties = properties;

        assert(pixels.length <= mSize.x * mSize.y * mChannels,
            "Too much pixel data for texture size.");

        GLenum internalFormat, srcFormat;

        final switch (image.channels)
        {
        case 1:
        case 2:
            internalFormat = GL_ALPHA;
            srcFormat = GL_ALPHA;
            break;

        case 3:
            internalFormat = GL_RGB8;
            srcFormat = GL_RGB;
            break;

        case 4:
            internalFormat = GL_RGBA8;
            srcFormat = GL_RGBA;
            break;
        }

        glGenTextures(1, &mID);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, mID);

        //glTextureStorage2D(mID, 1, internalFormat, mSize.x, mSize.y);
        //glTextureSubImage2D(mID, 0, 0, 0, mSize.x, mSize.y, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, mSize.x, mSize.y, 0, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

        if (properties.generateMipmaps)
        {
            // glEnable(GL_TEXTURE_2D); // To circumvent a bug in certain ATI drivers
            glGenerateMipmap(GL_TEXTURE_2D);
        }
    }

    this(uint id)
    {
        mID = id;
    }

    ~this()
    {
        glDeleteTextures(1, &mID);
    }

    void bind(uint unit = 0) const
    {
        glActiveTexture(GL_TEXTURE0 + unit);
        glBindTexture(GL_TEXTURE_2D, mID);
    }

    void setPixels(in ubyte[] pixels)
        in (pixels.length <= mSize.x * mSize.y * mChannels, "Too much pixel data for texture size.")
    {
        glBindTexture(GL_TEXTURE_2D, mID);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, mSize.x, mSize.y, mChannels == 4 ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, pixels.ptr);
    }

    const(TextureProperties) properties() const pure nothrow
    {
        return mProperties;
    }

    uint id() const pure nothrow
    {
        return mID;
    }

    Vector2i size() pure const nothrow
    {
        return mSize;
    }

    ubyte channels() pure const nothrow
    {
        return mChannels;
    }

    static Texture2D load(string path)
    {
        TextureProperties properties;
        Image img = AssetManager.load!Image(path);

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            import std.conv : to;
            import sdlang;

            scope VFSFile propsFile = VFS.getFile(path ~ ".props");
            Tag root = parseSource(propsFile.readAll!string);
            propsFile.close();

            try
            {
                properties.minFilter = root.getTagValue!string("min-filter", "nearest").to!(TextureProperties.Filter);
                properties.magFilter = root.getTagValue!string("mag-filter", "nearest").to!(TextureProperties.Filter);
                properties.wrapS = root.getTagValue!string("wrap-s", "repeat").to!(TextureProperties.WrapMode);
                properties.wrapT = root.getTagValue!string("wrap-t", "repeat").to!(TextureProperties.WrapMode);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
                ex.dispose();
            }
        }

        return new Texture2D(img, properties);
    }
}

@asset(Yes.cache)
class TextureCubeMap : Texture
{
protected:
    TextureProperties mProperties;
    uint mID;

public:
    this(in Image[6] images, in TextureProperties properties)
    {
        mProperties = properties;

        glGenTextures(1, &mID);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, mID);

        for (size_t i; i < 6; ++i)
        {
            GLenum internalFormat, srcFormat;

            final switch (images[i].channels)
            {
            case 1:
            case 2:
                internalFormat = GL_ALPHA;
                srcFormat = GL_ALPHA;
                break;

            case 3:
                internalFormat = GL_RGB8;
                srcFormat = GL_RGB;
                break;

            case 4:
                internalFormat = GL_RGBA8;
                srcFormat = GL_RGBA;
                break;
            }

            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(int) i, 0, internalFormat, images[i].size.x, images[i].size.y, 0, srcFormat,
                GL_UNSIGNED_BYTE, images[i].pixels.ptr);
        }

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

        if (properties.generateMipmaps)
            glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    }

    this(uint id)
    {
        mID = id;
    }

    ~this()
    {
        glDeleteTextures(1, &mID);
    }

    void bind(uint unit = 0) const
    {
        glActiveTexture(GL_TEXTURE0 + unit);
        glBindTexture(GL_TEXTURE_CUBE_MAP, mID);
    }

    const(TextureProperties) properties() const pure nothrow
    {
        return mProperties;
    }

    uint id() const pure nothrow
    {
        return mID;
    }

    static TextureCubeMap load(string path)
    {
        TextureProperties properties;

        scope VFSFile file = VFS.getFile(path);
        Tag root = parseSource(file.readAll!string);
        file.dispose();

        Image[6] images = [
            AssetManager.load!Image(root.expectTagValue!string("positive-x")),
            AssetManager.load!Image(root.expectTagValue!string("negative-x")),
            AssetManager.load!Image(root.expectTagValue!string("positive-y")),
            AssetManager.load!Image(root.expectTagValue!string("negative-y")),
            AssetManager.load!Image(root.expectTagValue!string("positive-z")),
            AssetManager.load!Image(root.expectTagValue!string("negative-z")),
        ];

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            import std.conv : to;

            scope VFSFile propsFile = VFS.getFile(path ~ ".props");
            root = parseSource(propsFile.readAll!string);
            propsFile.dispose();

            try
            {
                properties.minFilter = root.getTagValue!string("min-filter", "nearest").to!(TextureProperties.Filter);
                properties.magFilter = root.getTagValue!string("mag-filter", "nearest").to!(TextureProperties.Filter);
                properties.wrapS = root.getTagValue!string("wrap-s", "repeat").to!(TextureProperties.WrapMode);
                properties.wrapT = root.getTagValue!string("wrap-t", "repeat").to!(TextureProperties.WrapMode);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
                ex.dispose();
            }
        }

        return new TextureCubeMap(images, properties);
    }
}

private:

GLuint getGLFilter(TextureProperties.Filter filter)
{
    static GLint[TextureProperties.Filter] glFilter;

    if (!glFilter) 
        glFilter = [
            TextureProperties.Filter.nearest: GL_NEAREST,
            TextureProperties.Filter.linear: GL_LINEAR,
            TextureProperties.Filter.bilinear: GL_LINEAR,
            TextureProperties.Filter.trilinear: GL_LINEAR_MIPMAP_LINEAR
        ];

    return glFilter[filter];
}

GLuint getGLWrapMode(TextureProperties.WrapMode wrapMode)
{
    static GLint[TextureProperties.WrapMode] glWrapMode;

    if (!glWrapMode)
        glWrapMode = [
            TextureProperties.WrapMode.repeat: GL_REPEAT,
            TextureProperties.WrapMode.mirroredRepeat: GL_MIRRORED_REPEAT,
            TextureProperties.WrapMode.clampToEdge: GL_CLAMP_TO_EDGE
        ];

    return glWrapMode[wrapMode];
}