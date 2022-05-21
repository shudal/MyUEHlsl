
//float3 oriColor=SceneTextureLookup(GetDefaultSceneTextureUV(Parameters, 14), 14, false).rgb;
float3 ans=oriColor.rgb; 
float nowDep=SceneTextureLookup(GetDefaultSceneTextureUV(Parameters, 1), 1,false).x;
float customDep=SceneTextureLookup(GetDefaultSceneTextureUV(Parameters, 13), 13, false).x; 

if (nowDep+1 > customDep) { 
    float2 outSize=sceneTexSize * outlineWid;
    float dx[4] = {-1,1,0,0};
    float dy[4] = {0,0,1,-1};

    float totalDis=0;
    float2 oriCompUV=GetDefaultSceneTextureUV(Parameters, 1);
    for (int i=0;i<4;i++) {
        for (int k=0;k<2;k++) { 
            float subx=oriCompUV.x + dx[i]*outSize.x;
            float suby=oriCompUV.y + dy[k]*outSize.y;
            totalDis = totalDis + nowDep-SceneTextureLookup(float2(subx,suby), 1, false).x;
        }
    } 
    //totalDis = abs(totalDis);
    totalDis=pow(totalDis,2);
    ans=lerp(oriColor.rgb,float3(0,0,0),totalDis); 
}
return ans;