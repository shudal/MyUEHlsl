const float shadowwid=.02;
const float noiselen=.01;
const float shadowTargetRidius=.025;
const float shadowOriginRidius=.04;
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
    float3 hsb2rgb(in float3 hsv) {
        return HSVtoRGB(hsv);
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
    float3 hash3( float2 p ) {
        float3 q = float3( dot(p,float2(127.1,311.7)),
                    dot(p,float2(269.5,183.3)),
                    dot(p,float2(419.2,371.9)) );
        return frac(sin(q)*43758.5453);
    }
    float iqnoise( in float2 x, float u, float v ) {
        float2 p = floor(x);
        float2 f = frac(x);

        float k = 1.0+63.0*pow(1.0-v,4.0);

        float va = 0.0;
        float wt = 0.0;
        for (int j=-2; j<=2; j++) {
            for (int i=-2; i<=2; i++) {
                float2 g = float2(float(i),float(j));
                float3 o = hash3(p + g)*float3(u,u,1.0);
                float2 r = g - f + o.xy;
                float d = dot(r,r);
                float ww = pow( 1.-smoothstep(0.0,1.414,sqrt(d)), k );
                va += o.z*ww;
                wt += ww;
            }
        }

        return va/wt;
    }
    float drawCycle(float2 st, float2 ori, float r, float outHalfWid) {
        float dis=distance(st,ori);
        
        if (dis < (r+outHalfWid) && dis > (r-outHalfWid)) { 
            //gl_FragColor = vec4(hsb2rgb(float3(f1(dis),f1(1.),f1(1.))),1.);
            float2 n = normalize(st-ori);
            float tmpx=abs(smoothstep(ori+(r - outHalfWid)*n ,ori+(r +outHalfWid)*n,st) - 0.5)*2.;
            float2 x1 = float2(tmpx,tmpx);
            x1 = 1.0 - x1;
            
            return x1.x*x1.y; 
            
        } 
        return 0.;
    }

};

#define PI 3.14159265359
#define TWO_PI 6.28318530718
Func func;



float3 dir=vecDir.xyz;  
dir = normalize(dir);

float2 ori=float2(.5,.5);
float x=0;  
float4 ans=float4(0,0,0,0);

if (slen > 0 && length(dir)>0)  { 
    st = st + lerp(-noiselen,noiselen,func.noise(st*20+utime));

    float l1=length(st-ori);
    float slendived=slen/swid;
    float x2= 1 - step(slendived,l1);
    x=x2;


    float sintodir=sqrt(1-pow(dot(dir,normalize(st-ori)),2));
    float lentodir=length(st-ori)*sintodir;
    if (lentodir>shadowwid) {
        x=0;
    }
 
    if (dot(dir,st-ori)<0) {
        x=0;
    }
    if (length(st-ori-slendived*dir)<shadowTargetRidius) {
        x=1;
    }
    if (length(st-ori)<shadowOriginRidius) {
        x=1;
    }

    ans = ans+float4(x,x,x,x);
}

 
 
return ans;

