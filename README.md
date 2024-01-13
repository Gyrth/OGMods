# The Rat King
You play as the rat king. Your subjects follow you around and can be commanded to attack your enemies.

## Technical info
This mod uses my vertex animation texture shader. Basically you animate a model in blender and then bake the vertex offsets into a texture. These offsets can be read inside the vertex shader and played back again. The VAT can contain multiple animations and then the script chooses which animation and which frame to play.

I've included the .dds file because Overgrowth applies filtering to textures. This filtering causes the colors to be less precise and therefore the animation does not look correct. By including the .dds file without filtering, you can circumvent the cache creation.

[Rat model released by AIUM2 under the CC Attribution License.](https://sketchfab.com/3d-models/mouse-d2119364f0c849cc9ed40ab75d7e671b)

This mod supports both **stable** and **internal_testing**.

## Resources used
https://medium.com/tech-at-wildlife-studios/texture-animation-techniques-1daecb316657  
https://stoyan3d.wordpress.com/2021/07/23/vertex-animation-texture-vat/  
https://storyprogramming.com/2019/09/18/shader-graph-rigid-body-animation-using-vertex-animation-textures/  

[Buy the game here.](http://www.wolfire.com/overgrowth)
