//
//  Shader.metal
//  iES
//
//  Created by Никита Пивоваров on 20.02.2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_main(const device float4 *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = vertices[vid];
    out.texCoord = vertices[vid].zw;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> nesTexture [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::nearest);
    float4 color = nesTexture.sample(s, in.texCoord);
    return color;
}
