texture ScreenTexture;
float2 PixelSize;
float Daylight = 1.0;
sampler ScreenSampler = sampler_state {
 Texture = <ScreenTexture>;
 MinFilter = Linear; MagFilter = Linear; MipFilter = None;
 AddressU = Clamp; AddressV = Clamp;
};
float3 grade(float3 color) {
 float luma = dot(color,float3(0.2126,0.7152,0.0722));
 color = lerp(luma.xxx,color,0.93);
 color = (color-0.5)*1.035+0.5;
 // Warmer daylight; no exposure boost or raised darkness at night.
 color *= lerp(float3(1,1,1),float3(1.018,1.002,0.984),Daylight);
 return saturate(color);
}
float4 main(float2 uv : TEXCOORD0) : COLOR0 {
 float3 color = tex2D(ScreenSampler,uv).rgb;
 float2 offset = PixelSize*8.0;
 float3 glow = max(tex2D(ScreenSampler,uv+float2(offset.x,0)).rgb-0.75,0);
 glow += max(tex2D(ScreenSampler,uv+float2(-offset.x,0)).rgb-0.75,0);
 glow += max(tex2D(ScreenSampler,uv+float2(0,offset.y)).rgb-0.75,0);
 glow += max(tex2D(ScreenSampler,uv+float2(0,-offset.y)).rgb-0.75,0);
 color += glow*0.03;
 color = grade(color);
 float2 centred = uv*2.0-1.0;
 color *= 1.0-0.06*saturate(dot(centred,centred)*0.5);
 return float4(saturate(color),1);
}
technique RedFear {
 pass P0 {
 AlphaBlendEnable = false;
 ZEnable = false;
 ZWriteEnable = false;
 PixelShader = compile ps_2_0 main();
 }
}
