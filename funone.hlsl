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
};

#define PI 3.14159265359
#define TWO_PI 6.28318530718
Func func;
 
float2 st_ori=st;
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


if (startFadeTime > 0.001) {
    float x15=u_time-startFadeTime;
    
    prt = float2(0.,smoothstep(-1.,1.,sin(x15/2.)));
    if (x15>PI/2.) {
        prt.y=1.;
    }


    bool b1=func.IsInnerRect(st,plb,prt);

    float2 x9=st*15.;
    float2 f_st=frac(x9);
    float2 i_st=floor(x9);

    float x13=func.noise(x9);
    float x10=func.iqnoise(x9,1.,1.); 
    bool b2=x13<prt.y;
    //b2=x10<prt.y;
    if (b2) {
        float x11=smoothstep(prt.y-0.3,prt.y,x10);
        color=float4(oriColor,1.-x11);
    } else {
        color=float4(0.,0.,0.,0.);
    }
 
    return color; 
} else {
    return float4(oriColor,1.);
}
