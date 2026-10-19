#include <metal_stdlib>
using namespace metal;
struct Triangle { float4 a,b,c,color; uint4 metadata; };
struct Node { int op,left,right,pad; };
struct Camera { float4 eye,right,up,forward; uint4 counts; float4 options; int4 roots; };
struct Event { float t; uint leaf; float3 normal; float edge; float4 color; };
struct Varying { float4 position [[position]]; float2 uv; };
vertex Varying fullscreen(uint id [[vertex_id]]) {
    float2 p = float2((id << 1) & 2, id & 2);
    return {float4(p*2-1,0,1),p};
}
bool evaluate(ulong mask, constant Node *nodes, uint count, int root) {
    bool values[127];
    for(uint i=0;i<count;i++) {
        Node n=nodes[i];
        bool a=n.left>=0 ? (n.op==0 ? ((mask & (1ul<<uint(n.left)))!=0) : values[n.left]) : false;
        bool b=n.right>=0 ? values[n.right] : false;
        values[i]=n.op==0 ? a : n.op==1 ? a||b : n.op==2 ? a&&b : a&&!b;
    }
    return root>=0 ? values[root] : false;
}
fragment float4 preview(Varying in [[stage_in]], constant Triangle *triangles [[buffer(0)]],
    constant Node *nodes [[buffer(1)]], constant Camera &camera [[buffer(2)]],
    constant int *layerRoots [[buffer(3)]]) {
    float2 p=(in.uv*2-1); p.x*=camera.options.x;
    float3 direction=normalize(camera.forward.xyz + camera.right.xyz*p.x*0.5 + camera.up.xyz*p.y*0.5);
    Event events[128]; uint count=0;
    for(uint i=0;i<camera.counts.x;i++) {
        Triangle t=triangles[i];
        float3 e1=t.b.xyz-t.a.xyz, e2=t.c.xyz-t.a.xyz;
        float3 h=cross(direction,e2); float determinant=dot(e1,h);
        if(abs(determinant)<1e-9) continue;
        float inverse=1/determinant;
        float3 s=camera.eye.xyz-t.a.xyz;
        float u=dot(s,h)*inverse; if(u < -1e-6 || u>1.000001) continue;
        float3 q=cross(s,e1); float v=dot(direction,q)*inverse;
        if(v < -1e-6 || u+v>1.000001) continue;
        float distance=dot(e2,q)*inverse;
        if(count==128) return float4(0.8,0.1,0.65,1); // Visible ray quota diagnostic.
        Event event={distance,t.metadata.x,normalize(cross(e1,e2)),min(min(u,v),1-u-v),t.color};
        uint j=count++;
        while(j>0 && events[j-1].t>distance) { events[j]=events[j-1]; j--; }
        events[j]=event;
    }
    ulong mask=0;
    for(uint i=0;i<count;) {
        uint end=i+1; ulong toggle=1ul<<events[i].leaf;
        float epsilon=max(1e-5,abs(events[i].t)*1e-6);
        while(end<count && abs(events[end].t-events[i].t)<epsilon) { toggle |= 1ul<<events[end].leaf; end++; }
        ulong next=mask^toggle;
        // Traverse behind the eye first so occupancy is valid inside operands.
        if(events[i].t<=0) { mask=next; i=end; continue; }
        int layer=-1;
        bool before=evaluate(mask,nodes,camera.counts.y,camera.roots.x);
        bool after=evaluate(next,nodes,camera.counts.y,camera.roots.x);
        if(before!=after) layer=0;
        for(uint r=0;r<camera.counts.z;r++) {
            if(evaluate(mask,nodes,camera.counts.y,layerRoots[r]) != evaluate(next,nodes,camera.counts.y,layerRoots[r])) layer=1;
        }
        if(layer<0) for(uint r=camera.counts.z;r<camera.counts.w;r++) {
            if(evaluate(mask,nodes,camera.counts.y,layerRoots[r]) != evaluate(next,nodes,camera.counts.y,layerRoots[r])) layer=2;
        }
        if(layer>=0) {
            float3 normal=events[i].normal; if(dot(normal,direction)>0) normal=-normal;
            float light=0.28+0.72*max(0.0,dot(normal,normalize(float3(-0.5,-0.6,1))));
            float3 color=layer==1 ? float3(1,0.25,0.15) : layer==2 ? float3(0.45,0.55,0.65) : events[i].color.rgb;
            if(camera.options.y>0.5 && events[i].edge<0.025) color=float3(0.06);
            return float4(color*light,1);
        }
        mask=next; i=end;
    }
    float shade=0.965-0.035*in.uv.y;
    return float4(shade,shade,shade+0.005,1);
}
