// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.mesh;

import std.string : format;
import std.path : extension;

import inmath.linalg;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Mesh : Renderable
{
protected:
    BufferGroup mBufferGroup;
    Material mMaterial;

    pragma(inline, true)
    static Vector3f calculateSurfaceNormal(Vector3f p1, Vector3f p2, Vector3f p3) nothrow pure
    {
        immutable Vector3f u = p2 - p1;
        immutable Vector3f v = p3 - p1;

        return u.cross(v);
    }

    static void calculateNormals(ref Vertex[] vertices, in uint[] indices) nothrow pure
        in (vertices, "Vertices cannot be null.")
        in (indices, "Indices cannot be null.")
    {
        // First, calculate all missing vertex normals
        for (size_t i; i < indices.length; i += 3)
        {
            Vertex* v1 = &vertices[indices[i]], v2 = &vertices[indices[i + 1]], v3 = &vertices[indices[i + 2]];

            // If one of the vertices already has a normal, continue on
            if (v1.normal != Vector3f(0) || v2.normal != Vector3f(0) || v3.normal != Vector3f(0))
                continue;

            immutable Vector3f normal = calculateSurfaceNormal(v1.position, v2.position, v3.position);

            v1.normal += normal;
            v2.normal += normal;
            v3.normal += normal;
        }

        // Secondly, normalize all normals
        foreach (ref Vertex v; vertices)
            v.normal = v.normal.normalized;
    }

    static Mesh loadFromOBJFile(string path)
        in (path, "Path cannot be null.")
    {
        import std.string : splitLines, strip, startsWith, split;
        import std.conv : to;

        VFSFile file = VFS.getFile(path);
        string content = file.readAll!string;
        file.dispose();

        Vector4f[] positions;
        Vector2f[] uvs;
        Vector3f[] normals;

        Mesh.Vertex[] vertices;
        uint[] indices;

        size_t[size_t] positionToVertexIndex;
        size_t lineNr;
        string currentObjectName = null;

    parseLoop:
        foreach (string line; content.splitLines)
        {
            ++lineNr;
            line = line.strip;

            // Skip comment or blank lines
            if (line.startsWith("#") || line.length == 0)
                continue;

            string[] element = line.split();

            switch (element[0])
            {
            case "o": // Object name
                if (element.length < 2)
                {
                    Logger.core.log(LogLevel.warning, "Malformed object name in '%s' at line %d.", path, lineNr);
                    continue;
                }

                if (currentObjectName)
                {
                    Logger.core.log(LogLevel.info, "Loading OBJs with multiple objects currently not supported. ('%s')", path);
                    break parseLoop;
                }

                currentObjectName = element[1];
                break;

            case "v": // Vertex position
                if (element.length < 4)
                {
                    Logger.core.log(LogLevel.warning, "Malformed vertex element in '%s' at line %d.", path, lineNr);
                    continue;
                }

                immutable float x = element[1].to!float;
                immutable float y = element[2].to!float;
                immutable float z = element[3].to!float;
                float w = 1;

                if (element.length > 4)
                    w = element[4].to!float;

                positions ~= Vector4f(x, y, z, w);
                break;

            case "vt": // UV
                if (element.length < 2)
                {
                    Logger.core.log(LogLevel.warning, "Malformed UV element in '%s' at line %d.", path, lineNr);
                    continue;
                }

                immutable float u = element[1].to!float;
                float v;

                if (element.length > 2)
                    v = element[2].to!float;

                uvs ~= Vector2f(u, v);
                break;

            case "vn": // Vertex normal
                if (element.length < 4)
                {
                    Logger.core.log(LogLevel.warning, "Malformed normal element in '%s' at line %d.", path, lineNr);
                    continue;
                }

                normals ~= Vector3f(
                    element[1].to!float, element[2].to!float, element[3].to!float
                );
                break;

            case "f": // Face
                foreach (string vertex; element[1 .. $])
                {
                    string[] vertexAttribs = vertex.split("/");

                    // To keep code short, put it into this function.
                    // Check if vertex attribute exists, if so, get proper index.
                    // Negative value from end, positive value starts at 1.
                    size_t getAttrib(size_t idx, size_t arrayLength)
                    {
                        if (vertexAttribs.length > idx && vertexAttribs[idx] != "")
                        {
                            ptrdiff_t value = vertexAttribs[idx].to!ptrdiff_t;

                            if (value < 0)
                                return arrayLength - value;
                            else
                                return cast(size_t) value - 1;
                        }
                        else
                            return size_t.max;
                    }

                    immutable size_t posIdx = getAttrib(0, positions.length);
                    immutable size_t uvIdx = getAttrib(1, uvs.length);
                    immutable size_t normalIdx = getAttrib(2, normals.length);

                    // Check if this vertex was already processed. If so, only add index.
                    size_t* vertexIdx = posIdx in positionToVertexIndex;

                    if (vertexIdx)
                        indices ~= cast(uint) *vertexIdx;
                    else
                    {
                        Mesh.Vertex v;

                        v.position = positions[posIdx].xyz;

                        if (uvIdx != size_t.max)
                            v.uv = uvs[uvIdx];

                        if (normalIdx != size_t.max)
                            v.normal = normals[normalIdx];

                        positionToVertexIndex[posIdx] = vertices.length;
                        indices ~= cast(uint) vertices.length;
                        vertices ~= v;
                    }
                }
                break;

            default:
                Logger.core.log(LogLevel.debug_, "Unrecognized element '%s' in '%s' at line %d.", element[0], path, lineNr);
            }
        }

        return new Mesh(vertices, indices, null);
    }

public:
    struct Vertex
    {
        Vector3f position;
        Vector2f uv = Vector2f(0);
        Vector3f normal = Vector3f(0);
        Vector4f color = Vector4f(1);
    }

    this(Vertex[] vertices, in uint[] indices, Material material)
        in (vertices, "Vertices cannot be null.")
        in (indices, "Indices cannot be null.")
    {
        calculateNormals(vertices, indices);

        mBufferGroup = new BufferGroup();
        mBufferGroup.dataBuffer = new DataBuffer(vertices, BufferLayout([
            BufferElement("aPosition", BufferElement.Type.vec3),
            BufferElement("aUV", BufferElement.Type.vec2),
            BufferElement("aNormal", BufferElement.Type.vec3),
            BufferElement("aColor", BufferElement.Type.vec4)
        ]), No.dynamic);

        mBufferGroup.indexBuffer = new IndexBuffer(indices, No.dynamic);

        mMaterial = material;
    }

    inout(BufferGroup) bufferGroup() inout nothrow pure
    {
        return mBufferGroup;
    }

    inout(Material) material() inout nothrow pure
    {
        return mMaterial;
    }

    void material(Material value) nothrow pure
    {
        mMaterial = value;
    }

    static Mesh load(string path)
        in (path, "Path cannot be null.")
    {
        Mesh mesh;

        switch (path.extension)
        {
        case ".obj":
            mesh = loadFromOBJFile(path);
            break;

        default:
            throw new RenderException(format!"Could not find suitable mesh loader for '%s'."(path));
        }

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            import sdlang;

            scope VFSFile propsFile = VFS.getFile(path ~ ".props");
            Tag root = parseSource(propsFile.readAll!string);
            propsFile.dispose();

            try
            {
                if (string materialPath = root.getTagValue!string("material", null))
                    mesh.mMaterial = AssetManager.load!Material(materialPath);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
                ex.dispose();
            }
        }

        return mesh;
    }
}