const float3 specularColor1=float3(0.91,0.91,0.91);
const float3 specularColor2=float3(0.685,0.685,0.685);

const float3 lightColor=float3(1,1,1);
const float primaryShift=.1;
const float secondaryShift=.05;
const float specExp1=1000;
const float specExp2=100;
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
    float3 ShiftTangent(float3 T, float3 N, float shift)
    {
        float3 shiftedT = T + (shift * N);
        return normalize(shiftedT);
    }
    float StrandSpecular(float3 T, float3 V, float L, float exponent)
    {
        float3 H = normalize(L + V);
        float dotTH = dot(T, H);
        float sinTH = sqrt(1.0 - dotTH*dotTH);
        float dirAtten = smoothstep(-1.0, 0.0, dot(T, H));

        return dirAtten * pow(sinTH, exponent);
    }
    float4 HairLighting (float3 tangent, float3 normal, float3 lightVec, 
                     float3 viewVec, float2 uv, float ambOcc)
    {
        // shift tangents
        //float shiftTex = tex2D(tSpecShift, uv) - 0.5;
        float shiftTex = Texture2DSample(tSpecShift, tSpecShiftSampler, uv)-0.5;
        //float shiftTex=0;
        float3 t1 = ShiftTangent(tangent, normal, primaryShift + shiftTex);
        float3 t2 = ShiftTangent(tangent, normal, secondaryShift + shiftTex);

        // diffuse lighting
        //float tmpx1=saturate(lerp(0.25, 1.0, dot(normal, lightVec))); 
        //float3 diffuse = float3(tmpx1,tmpx1,tmpx1);

        // specular lighting
        float3 specular = specularColor1 * StrandSpecular(t1, viewVec, lightVec, specExp1);
        float3 spec1=specular;
        // add second specular term
        //float specMask = tex2D(tSpecMask, uv); 
        float specMask = 1;
        specular += specularColor2 * specMask * StrandSpecular(t2, viewVec, lightVec, specExp2);

        // Final color
        float4 o;
        //o.rgb = (diffuse + specular) * Texture2DSample(tBase, tBaseSampler,uv) * lightColor;
        //o.rgb = (diffuse + specular) * Texture2DSample(tBase, tBaseSampler,uv) * lightColor;
        //o.rgb += spec1;
        //o.rgb *= float3(0.2f, 0.3f, 0.62f);//(0.2f, 0.3f, 0.62f, 1f)
        o.rgb = (specular) * Texture2DSample(tBase, tBaseSampler,uv) * lightColor;
        //o.rgb *= ambOcc; 
        //o.a = tex2D(tAlpha, uv);
        o.a=specular.x;
        return o;
    }
};

#define PI 3.14159265359
#define TWO_PI 6.28318530718
Func func;

//float3 lightVec=float3(1,1,-1);
//lightVec *= -1;
lightVec=normalize(lightVec);

float4 ans=func.HairLighting (tangent, normal, lightVec,  viewVec, uv, ambOcc);
return ans;