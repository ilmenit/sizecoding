-- title:  Thrive
-- author: Ilmenit / Agenda
-- desc:   What will grow out of a tiny seed?
-- script: lua

function b(x,y,a,l)
 for i=0,l do
  -- position with rotation by angle
  j=y+i*s(a)+3*s(i/9)*s(a-8)
  k=x+i*s(a-8)-3*s(i/9)*s(a)

  -- leaves
  circ(k,
    -- random * growth by time * falling by time / growth time divider
    j+s(i)*m(t-633,4)*m(1133-t,1),
	-- negative size is hiding leaves
	m(t-633-i,1),
	-- color of leaves modified by time, with time limit
    3*s(i/9)-m(t/36,36))  

  -- branch gets thinner in time
  n=l-i

  -- tree   
  rect(k,j,n/33,n/33,0)
  -- snow on the branches, appearing in time
  rect(k,j,n/33,m(t-1633-i,1),-m(t-1633-i,133)/33)

  -- sub-branch
  if i%14==9 then
   b(k,j,a+s(i)+s(t/33)/33,n-33)
  end
 end
end

function TIC() 
 -- the full screen
 for i=0,32639 do
  -- background, substracting from color divided y position + dither
  poke4(i,63-i/3333+i*s(i)%1)
  
  -- 60*.4=24, 1000/41.6=24
  -- 60*.36=21.6, 1000/46=21.7
  
  t=time()/46
 
  -- falling snow
  pix(i%333,t-2433+i*s(i*i)/33,12)
 end
 
 --t=t+.36
 

 b(123,123,5,m(t,263))
end
s=math.sin
m=math.min
--t=0