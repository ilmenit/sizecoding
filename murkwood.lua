function TIC()
  t=t+1

  cls(15)
  math.randomseed (56)
  
  for layer=14,1,-1 do
    for x=0,layer/3 do  
    -- trees
      r=math.random(240)
      rect(r,0,(15-layer)*1.5,240,layer)
      rect(r-1,math.random(64),1,240,layer)
    end
    y=200-layer*8
    for x=0,240 do  
      -- ground
      rect(x,y/2,1,240,layer)
      y=y+math.random(3)-2
      -- rain
      r=math.random(240)
      pix(x,(r+t/layer)%240,layer)
      -- small dither
      pix(x,r/2,pix(x,r/2)-1)
      pix(x,r,pix(x,r)-1)
      -- palette
      poke(16320+x%48,x%48*5)
    end
  end

  -- play tune
  for x=0,3 do
    sfx(
    0, -- sfx
    41+({0,3,7,8,10,12,15,3})[
     (
         (4-x)*(t//(x*64+64)+1)+(4-x)//4*4
     )%8+1
    ], -- note
    8, -- duration
    x, -- x
    (x*64+64-t)/8
    )
  end
 end
 t=0