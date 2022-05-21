float3 col=float3(1,1,1);
//col = col *smoothstep(0,0.1,ndotl);
if (ndotl < 0.05) {
    col=float3(0,0,0);
}
return col;