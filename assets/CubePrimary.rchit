#include "structures.fxh"
#include "RayUtils.fxh"

ConstantBuffer<CubeAttribs> g_CubeAttribsCB;

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    float3 barycentric = float3(1.0 - attr.barycentrics.x - attr.barycentrics.y, attr.barycentrics.x, attr.barycentrics.y);
    uint3 triIndices = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;
    float3 interpolatedNormal = g_CubeAttribsCB.Normals[triIndices.x] * barycentric.x +
                                g_CubeAttribsCB.Normals[triIndices.y] * barycentric.y +
                                g_CubeAttribsCB.Normals[triIndices.z] * barycentric.z;
    float3 worldNormal = normalize(mul((float3x3) ObjectToWorld3x4(), interpolatedNormal));
    float3 reflectionDir = reflect(WorldRayDirection(), worldNormal);

    RayDesc reflectionRay;
    reflectionRay.Origin = WorldRayOrigin() + WorldRayDirection() * RayTCurrent() + worldNormal * SMALL_OFFSET;
    reflectionRay.TMin   = 0.0;
    reflectionRay.TMax   = 100.0;

    float3 finalColor = float3(0.0, 0.0, 0.0);
    int reflectionBlur = (payload.Recursion > 1) ? 1 : g_ConstantsCB.SphereReflectionBlur;

    for (int i = 0; i < reflectionBlur; ++i)
    {
        float2 randomOffset = float2(g_ConstantsCB.DiscPoints[i / 2][(i % 2) * 2], g_ConstantsCB.DiscPoints[i / 2][(i % 2) * 2 + 1]);
        reflectionRay.Direction = DirectionWithinCone(reflectionDir, randomOffset * 0.02);

        finalColor += CastPrimaryRay(reflectionRay, payload.Recursion + 1).Color;
    }

    finalColor /= float(reflectionBlur);

    float metallicFactor = 0.8;
    float roughnessFactor = 0.4;
    float3 metallicColor = finalColor * metallicFactor;

    finalColor = lerp(metallicColor, finalColor, roughnessFactor);
    finalColor *= g_ConstantsCB.SphereReflectionColorMask;

    payload.Color = finalColor;
    payload.Depth = RayTCurrent();
}
