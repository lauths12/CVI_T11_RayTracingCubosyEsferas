#include "structures.fxh"
#include "RayUtils.fxh"

ConstantBuffer<CubeAttribs> g_CubeAttribsCB;

float3 GeneratePastelColor(uint id)
{
    float r = frac(sin(id * 12.9898 + 78.233) * 43758.5453);
    float g = frac(sin(id * 12.9898 + 24.982) * 43758.5453);
    float b = frac(sin(id * 12.9898 + 58.393) * 43758.5453);

    r = lerp(0.7, r, 0.4);
    g = lerp(0.7, g, 0.4);
    b = lerp(0.7, b, 0.4);

    return float3(r, g, b);
}

[shader("closesthit")]
void main(inout PrimaryRayPayload payload, in BuiltInTriangleIntersectionAttributes attr)
{
    float3 b = float3(1.0 - attr.barycentrics.x - attr.barycentrics.y, attr.barycentrics.x, attr.barycentrics.y);

    uint3 tri = g_CubeAttribsCB.Primitives[PrimitiveIndex()].xyz;
    float3 normal = 
        g_CubeAttribsCB.Normals[tri.x] * b.x +
        g_CubeAttribsCB.Normals[tri.y] * b.y +
        g_CubeAttribsCB.Normals[tri.z] * b.z;
    normal = normalize(mul((float3x3)ObjectToWorld3x4(), normal));

    float3 pastelColor = GeneratePastelColor(InstanceID());

    float3 hitPoint = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

    payload.Color = pastelColor;
    payload.Depth = RayTCurrent();
    LightingPass(payload.Color, hitPoint, normal, payload.Recursion + 1);
}
