struct Func {
    float fRand(float x, float time) {
        return abs(sin(time/3+x));
    } 
    float3 HUEtoRGB(in float H)
    {
        float R = abs(H * 6 - 3) - 1;
        float G = 2 - abs(H * 6 - 2);
        float B = 2 - abs(H * 6 - 4);
        return saturate(float3(R,G,B));
    }
    float3 HSVtoRGB(in float3 HSV)
    {
        float3 RGB = HUEtoRGB(HSV.x);
        return ((RGB - 1) * HSV.y + 1) * HSV.z;
    }
    float random(float x) {
        return frac(sin(x)*100000.0);
    }
    float random(float2 _st) {
        return frac(sin(dot(_st.xy,
                         float2(12.9898,78.233)))*
        43758.5453123);
    }
    float noise(float x) {
        float i = floor(x);  // 整数（i 代表 integer）
        float f = frac(x);  
        float u = f * f * (3.0 - 2.0 * f ); // custom cubic curve
        float y = lerp(random(i), random(i + 1.0), u);
        return y;
    }
    float noise(float2 st) {
        float2 i = floor(st);
        float2 f = frac(st);

        // Four corners in 2D of a tile
        float a = random(i);
        float b = random(i + float2(1.0, 0.0));
        float c = random(i + float2(0.0, 1.0));
        float d = random(i + float2(1.0, 1.0));

        // Smooth Interpolation

        // Cubic Hermine Curve.  Same as SmoothStep()
        float2 u = f*f*(3.0-2.0*f);
        // u = smoothstep(0.,1.,f);

        // lerp 4 coorners percentages
        //return lerp(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) +  (d - b) * u.x * u.y;
        return lerp(lerp(a, b, smoothstep(0.0, 1.0, f.x)), lerp(c, d, smoothstep(0.0, 1.0, f.x)), smoothstep(0.0, 1.0, f.y));
    }
    bool IsInnerRect(float2 st,float2 plb, float2 prt) {
        bool ans,b1,b2;
        ans=false;
        b1=false;
        b2=false;
        if (st.x > plb.x && st.y > plb.y) {
            b1 = true;
        } 
        prt = float2(1.0,1.) - prt;
        if (st.x < prt.x && st.y < prt.y) {
            b2 = true;
        }
        ans = b1 && b2;
        return ans; 
    }
    #define OCTAVES 6
    float fbm (in float2 st) {
        // Initial values
        float value = 0.0;
        float amplitude = .5;
        float frequency = 0.;
        //
        // Loop of octaves
        for (int i = 0; i < OCTAVES; i++) {
            value += amplitude * noise(st);
            st *= 2.;
            amplitude *= .5;
        }
        return value;
    }
};
Func func;
 
float4 color = float4(0.5,0.5,0.5,1.);

float sca=13.;
float x8=u_time;
float x1= func.fbm(st*sca + x8);
float x2= func.fbm(st*sca+10. +x8);


float x5=0.05;
float x6=lerp(-x5,x5,x1);
float x7=lerp(-x5,x5,x2);

st = st + float2(x6,x7);
st=frac(st);

float2 plb=float2(0.,0.);
float2 prt=plb;

prt = float2(0.,smoothstep(-1.,1.,sin(u_time/3.)));
 
if (func.IsInnerRect(st,plb,prt)) {
    color=float4(x1,0.,0.,1.);
} else {
    color=float4(0.,0.,0.,0.);
}
return color; 