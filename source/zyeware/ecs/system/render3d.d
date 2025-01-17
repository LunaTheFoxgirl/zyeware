// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.ecs.system.render3d;

import zyeware.common;
import zyeware.ecs;
import zyeware.rendering;

/// This system is responsible for rendering all entities with `RenderComponent`s
/// to the screen.
///
/// See_Also: RenderComponent
class Render3DSystem : System
{
package:
    pragma(inline, true)
    static void drawNoCameraSprite()
    {
        static Camera camera;
        static Texture2D texture;

        if (!camera)
        {
            camera = new OrthographicCamera(-1, 1, 1, -1);
            texture = AssetManager.load!Texture2D("core://textures/no-camera.png");
        }

        Renderer2D.begin(camera.projectionMatrix, Matrix4f.identity);
        if ((ZyeWare.upTime.total!"hnsecs" / 5_000_000) % 2 == 0)
            Renderer2D.drawRect(Rect2f(-0.5f, -0.5f, 0.5f, 0.5f), Vector2f(0), Vector2f(1), Color.white, texture);
        Renderer2D.end();
    }

public:
    override void draw(EntityManager entities, in FrameTime nextFrameTime) const
    {
        // Find camera first
        bool foundCamera;
        Matrix4f projectionMatrix;
        Environment3D environment;
        Transform3DComponent* cameraTransform;

        foreach (Entity entity, Transform3DComponent* transform, CameraComponent* camera;
            entities.entitiesWith!(Transform3DComponent, CameraComponent))
        {
            if (camera.active)
            {
                foundCamera = true;

                projectionMatrix = camera.camera.projectionMatrix;
                cameraTransform = transform;
                environment = cast(Environment3D) camera.environment;
                break;
            }
        }

        RenderAPI.clear();

        if (!foundCamera || !environment)
        {
            drawNoCameraSprite();
            return;
        }

        static Renderer3D.Light[Renderer3D.maxLights] lights;
        size_t lightPointer = 0;

        foreach (Entity entity, Transform3DComponent* transform, LightComponent* light;
            entities.entitiesWith!(Transform3DComponent, LightComponent))
        {
            lights[lightPointer++] = Renderer3D.Light(transform.globalPosition, light.color, light.attenuation);
            
            if (lightPointer == lights.length)
                break;
        }

        Renderer3D.uploadLights(lights[0 .. lightPointer]);

        Renderer3D.begin(projectionMatrix, cameraTransform.globalMatrix.inverse, environment);

        foreach (Entity entity, Transform3DComponent* transform, Render3DComponent* renderable;
            entities.entitiesWith!(Transform3DComponent, Render3DComponent))
        {
            Renderer3D.submit(renderable.renderable, transform.globalMatrix);
        }

        Renderer3D.end();
    }
}