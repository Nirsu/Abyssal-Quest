pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
poke(0x5f2e,1)

function _init()
  pal({[0]=0,128,5,134,141,2,136,8,142,7,143,140,131,129,1,6},1)

  menu_init()
end

-->8
--menu

function menu_init()
	_update60=menu_update
	_draw=menu_draw
end

function menu_update()
	if (btnp(❎)) game_init()	 
end

function menu_draw()
	--clear screen with blue
	cls(12) 
	
	--make a title with a shadow.
	print("a game!",51,48,0)
	print("a game!",50,48,7)

	--give them instructions on how
	--to play, with a shadow.
	print("press ❎ to play!",31,72,0)
	print("press ❎ to play!",30,72,7)

end

-->8
--game

function game_init()
  p = {
    x=8,
    y=24,
    speed=2,
    -- flip sprite horizontally
    flip = false,
    -- Sprite to draw, sprite frames to use, speed of animation (between 0 == fast and 1 == slow), ticks since last frame
    idle = 1,
    running = {sprite = 2, frames = {2, 3, 4}, speed = 0.1, ticks = 0},
    running_up = {sprite = 5, frames = {5, 6}, speed = 0.1, ticks = 0},
    -- TODO: FIX THIS, and make it work like the other animations
    --dodging = {sprite = 17, frames = {17, 18, 19, 20}, speed = 0.1, ticks = 0},

    timer_dodge = 0,
    dodge_max_cooldown=50,
    can_roll=true,
  }

  pod = {
    width = 3,
    height = 4,
    idle = {
      startSx = 56,
      length = 2,
      sx = 56,
      sy = 0,
      ticks = 0,
      speed = 0.5,
    },
    shooting = {
      startSx = 56,
      length = 2,
      sx = 56,
      sy = 4,
      ticks = 0,
      speed = 0.5,
    }
  }

  init_phantom()

  _update60=game_update
  _draw=game_draw
end

function game_update()
  update_camera(boss)
  update_p()
  update_pod()
end

function game_draw()
  cls()
  map(0,0,0,0,254, 254)
  draw_p()
  draw_pod()
  draw_phantom()
end

-->8
--pod

function draw_pod()
  if (btn(❎)) then
    sspr(pod.shooting.sx, pod.shooting.sy, pod.width, pod.height, p.x+7, p.y - 5)
  else
    sspr(pod.idle.sx, pod.idle.sy, pod.width, pod.height, p.x+7, p.y - 5)
  end
end

function update_pod()
  if (btn(❎)) then
    animateForSspr(pod.shooting, pod.width, pod.shooting.length, pod.shooting.startSx)
  else
    animateForSspr(pod.idle, pod.width, pod.idle.length, pod.idle.startSx)
  end
end

-->8
--player

function check_p_moving()
  if (btn(➡️) or btn(⬅️) or btn(⬆️) or btn(⬇️)) then
    p_moving = true
    if (btn(⬆️)) then
      p_moving_up = true
      return
    end
    p_moving_up = false
  else
    p_moving = false
  end
end

function update_p()
  check_p_moving()
  update_dodging()

  local tmpX = p.x
  local tmpY = p.y

  if (btn(➡️)) then 
    tmpX+=p.speed
    p.flip = false
  end
  if (btn(⬅️)) then
    tmpX-=p.speed 
    p.flip = true
  end
  if (btn(⬆️)) tmpY-=p.speed
  if (btn(⬇️)) tmpY+=p.speed

  p.x = mid(8, tmpX, 240)
  p.y = mid(16, tmpY, 240)

  if (p_moving_up) then
    animate(p.running_up)
  else
    animate(p.running)
  end

  --dodge
  if (p_moving) then
    if (btn(🅾️) and p.can_roll) then
      p.timer_dodge=1
    end
  end
end

function draw_p()

  if (p_moving) then
    if (p_dodging) then
      spr(16+ceil((p.timer_dodge/3)), p.x, p.y, 1, 1, p.flip)
    elseif (p_moving_up) then 
      spr(p.running_up.sprite, p.x, p.y, 1, 1, p.flip)
    else
      spr(p.running.sprite, p.x, p.y, 1, 1, p.flip)
    end
  else
    spr(p.idle, p.x, p.y, 1, 1, p.flip)
  end
end

function update_dodging()
	p_dodging = false
  p.speed = 2
	if p.timer_dodge>0 and p.timer_dodge<p.dodge_max_cooldown and p_moving then
		p.timer_dodge+=1
    if p.timer_dodge<12 then
      p.can_roll = false
      p.speed = 4
      p_dodging = true
    end
  else
    p.timer_dodge=0
    p.can_roll = true
 end
end

-->8
--Phantom Blade

function init_phantom()
  boss = {
    x=128,
    y=128,
    speed=3,
    pv=100,
  }
end

function draw_phantom()
  -- spr(16, boss.x, boss.y, 1, 1, false)
  rectfill(boss.x, boss.y, boss.x + 16, boss.y + 16, 7)
end

-->8
--camera

function lerp(a, b, t)
  return a + (b - a) * t
end

function update_camera(target)
  local focusMargin = 0.3 -- Controle la distance entre le joueur et le point de focalisation (0 = sur le joueur, 1 = sur la cible)
  
  -- Calcule le point intermediaire entre le joueur et la cible
  local focusX = lerp(p.x, target.x, focusMargin)
  local focusY = lerp(p.y, target.y, focusMargin)

  -- Positionne la caméra pour qu'elle centre ce point intermédiaire, tout en assurant une marge autour du joueur
  local camX = focusX - 64
  local camY = focusY - 64

  camera(camX, camY)
end

-->8
--utils

function animate(obj)
  obj.ticks += (1/60)
  if obj.ticks > obj.speed then
    obj.sprite += 1
    if obj.sprite > obj.frames[#obj.frames] then
      obj.sprite = obj.frames[1]
    end
    obj.ticks = 0
  end
end

function animateForSspr(obj, width, length, defaultSx)
  obj.ticks += (1/60)
  if (obj.ticks > obj.speed) then
    obj.sx += width
    if (obj.sx > (defaultSx + (width * length) - width)) then
      obj.sx = defaultSx
    end
    obj.ticks = 0
  end
end

__gfx__
0770000000fff90000fff90000fff9000000000000fff90000000000fff000000000000000000000000000000000000000000000000000000000000000000000
78a700000ffaaa900ffaaa900fffaf9000fff9000fffff9000fff900f7ffff000000000000000000000000000000000000000000000000000000000000000000
077000000faaaa900f9aaa907ffaaa900ffaaa900fffff900fffff902f2f7f000000000000000000000000000000000000000000000000000000000000000000
000000000777777077777770077777700f9aaa90077777700fffff90202202000000000000000000000000000000000000000000000000000000000000000000
000000007fdfffd00fdfffd0ffdfffd07777777000dfff7007777770ffffff000000000000000000000000000000000000000000000000000000000000000000
000000000fdfffd0f0dffd0000dffd00ffdfffd000dfffd000dfffd0f8ff7f000000000000000000000000000000000000000000000000000000000000000000
000000000ddddd0002dddd000ddd2d000ddddd000dddd2000d2ddd002f22f2000000000000000000000000000000000000000000000000000000000000000000
00000000002002000000020000200000002002000020000000000200202202000000000000000000000000000000000000000000000000000000000000000000
00000000000007000000007002002000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ff7ff0000dd07000dddd07070dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddd79ff02dff7f00ddffd770f7ffd200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002dff7aaf00dff79f0dfff770f97ffd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dff7aaf2dff7aa90df777909aa7ffd20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002dff7aa90df77aa90d7aaa909aa77fd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dd79900dd7aa90097aaa9009aa7dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000990000999900009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fdeeeedfffffffff000ffffffffff000fdeeeedffdeeeedfeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeeeddeeddeeeeeeeeeeeeeeee0000000000000000
fdeeeedfdddddddd00fddddddddddf00ddeeeedffdeeeeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeeeddeeddeeeeeeeeeeeeeeee0000000000000000
fdeeeedfeeeeeeee0fdeeeeeeeeeedf0eeeeeedffdeeeeeeeeddddddddddddeeeeeeeeeeeeeeeeeeeeeeddeeeeddeeeeeeedddddddedddee0000000000000000
fdeeeedfeeeeeeeefdeeeeeeeeeeeedfeeeeeedffdeeeeeeeeddddddddddddeeeeeeeeeeeeeeeeeeeeeeddeeeeddeeeeeeeeeeddeeddedee0000000000000000
fdeeeedfeeeeeeeefdeeeeeeeeeeeedfeeeeeedffdeeeeeeeeddeeeeeeeeddeeeeeeecccccceeeeedddddccccccdddddeeeeeeeeeeeeddee0000000000000000
fdeeeedfeeeeeeeefdeeeeeeeeeeeedfeeeeedf00fdeeeeeeeddeeeeeeeeddeeeeeecccccc9ceeeeddddcccccc9cddddeeddeeeeeeeedeee0000000000000000
fdeeeedfddddddddfdeeeeddddeeeedfdddddf0000fdddddeeddeeddddeeddeeeeecccccc989ceeeeeecccccc989ceeeeeddeedddeeeedee0000000000000000
fdeeeedffffffffffdeeeedffdeeeedffffff000000fffffeeddeeddddeeddeeeeeccccccc9cceeeeeeccccccc9cceeeeedeeedeedeeedee0000000000000000
ddddddddddddddddeeeeeeeecccccccc0000000000000000eeddeeddddeeddeeeeeccc9cccccceeeeeeccc9cccccceeeeeddeeddddeedeee0000000000000000
deeeeddddeeeddddeeeeeeeeccccccce0000000000000000eeddeeddddeeddeeeeecc989ccccceeeeeecc989ccccceeeeeddeedddeeeddee0000000000000000
ddeeddeeddeddddeeeeeeeeeccccccee0000000000000000eeddeeeeeeeeddeeeeeecc9ccccceeeeddddcc9cccccddddeeeeeeeeeeeeedee0000000000000000
dddddddeddddddeeeeeeeeeeccccceee0000000000000000eeddeeeeeeeeddeeeeeeecccccceeeeedddddccccccdddddeedeeeeeeeeeddee0000000000000000
ddddddddeddddddeeeeeeeeecccceeee0000000000000000eeddddddddddddeeeeeeeeeeeeeeeeeeeeeeddeeeeddeeeeeeddeddddddddeee0000000000000000
deeedddddddeddddeeeeeeeeceeeeeee0000000000000000eeddddddddddddeeeeeeeeeeeeeeeeeeeeeeddeeeeddeeeeeeddddeededdddee0000000000000000
ddeeddedddeeedddeeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeeeddeeddeeeeeeeeeeeeeeee0000000000000000
dddddddddddeddddeeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeeeddeeddeeeeeeeeeeeeeeee0000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2221212121212121212121212121212121212121212121212121212121212123000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2030313130303130303130313030313031303130313031313130313130313020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2030313031303031313031303030313130313031313130313031303031313020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20333226272627262726272627262726272627262726272627262726272c2d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2032282b373637363736373637363736373637363736373637363736373c3d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20263a3b27262726272627262726272627262726272c2d262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2036373637363736373637363736373637363736373c3d363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2026272627262726272627262726272627262726272627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203637363d3c373637363736373637362a2b373637362a2b3736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20262732322c272627262726272627263a3b272627263a3b2726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20363d32323c373637362a2b37363736373637362a2b37363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20262d32322c272627263a3b27262726272627263a3b27262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20363732323c37363736373637362a2b37363736373637363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20262726272627262726272627263a3b27262726272627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203c3d3c37363736373637363736373637363736373637363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202c272c2726272627262726272627262726272c2d2627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20363736373637363736373637363d3c373637363d3c37362a2b373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202627262726272627262726272c2d2c2d262726272c27263a3b272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2036373637362a2b37363736373c37363d363736373637363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2026272627263a3b27262726272627262d2c2726272627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2036373637363736373637363736373637363736373637363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2026272627262726272c2d2627262726272627262d2c2d2c2d2c272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2036373637363736373c3d3637362a2b37363736373637363d3c373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20262726272627262d26272627263a3b27262726272627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203637363736373c3d363736373637363736373c373637363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202c2d2627262d26272627262726272627262d28292627262726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20363d3c3736373637363d362a2b37363736373839362a2b3736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202627262d26272627262d263a3b27262732323232263a3b2726272627262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
203637363d3c37362a2b3736373637363d323232323c37363736373637363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20262726272c2d263a3b27262726273232323232323232323226272c2d262720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20363d3c37363d36373637363736373232323232323232323236373c3d363720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2521212121212121212121212121212121212121212121212121212121212124000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
