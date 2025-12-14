pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	cls()
	to_menu()
end

function _update()
	if state == "menu" then
		update_menu()
	elseif state == "game" then
		update_game()
	elseif state == "gameover" then
		update_gameover()
	end
end

function gameover()
	state = "gameover"
	-- todo: add gameover sfx
	sfx(1)
end

function update_game()
	local btn_pressed = false
	local next_x, next_y

	if btn(0) then
		-- left
		pad_speed_x = -5
		btn_pressed = true
	end
	if btn(1) then
		-- right
		pad_speed_x = 5
		btn_pressed = true
	end
	if not btn_pressed then
		pad_speed_x /= 1.7
	end

	pad_x += pad_speed_x

	if pad_x < 1 then
		pad_x = 1
	end
	if pad_x + pad_w > 126 then
		pad_x = 126 - pad_w
	end

	next_x = ball_x + ball_speed_x
	next_y = ball_y + ball_speed_y
	ball_col += 1

	if next_x + ball_r > 127 then
		ball_speed_x = -ball_speed_x
		sfx(1)
		next_x = 127 - ball_r
	elseif next_x - ball_r < 0 then
		ball_speed_x = -ball_speed_x
		sfx(1)
		next_x = ball_r
	end

	if next_y - ball_r < bar_h then
		ball_speed_y = -ball_speed_y
		sfx(1)
		next_y = ball_r + bar_h
	end

	pad_col = 7
	-- check paddle collision
	if is_ball_collide(next_x, next_y, pad_x, pad_y, pad_w, pad_h) then
		pad_col = 8
		-- find out the collision direction
		if find_collision_direction(ball_x, ball_y, ball_speed_x, ball_speed_y, pad_x, pad_y, pad_w, pad_h) then
			ball_speed_x = -ball_speed_x
		else
			ball_speed_y = -ball_speed_y
			next_y = pad_y - ball_r
		end
		score += 1
		sfx(0)
	end

	local i
	local brickhit = false
	for i = 1, #brick_x do
		if brick_v[i] and is_ball_collide(next_x, next_y, brick_x[i], brick_y[i], brick_w, brick_h) then
			-- find out the collision direction
			if not brickhit then
				if find_collision_direction(ball_x, ball_y, ball_speed_x, ball_speed_y, brick_x[i], brick_y[i], brick_w, brick_h) then
					ball_speed_x = -ball_speed_x
				else
					ball_speed_y = -ball_speed_y
				end
				brickhit = true
			end
			brick_v[i] = false
			score += 10
			sfx(3)
		end
	end

	ball_x = next_x
	ball_y = next_y
	ball_col += 1

	if next_y + ball_r > 127 then
		sfx(2)
		hp -= 1
		if hp == 0 then
			gameover()
		else
			score -= min(score, 20)
		end
		relaunch_ball()
	end
end
function relaunch_ball()
	-- NOTE: ball param
	ball_x = 1
	ball_y = 10

	ball_speed_x = 2.5
	ball_speed_y = 2
end
function update_menu()
	if btn(5) then
		start_game()
	end
end
function start_game()
	ball_r = 2
	ball_col = 0

	-- NOTE: pad param
	pad_x = 52
	pad_y = 122
	pad_w = 24
	pad_h = 3
	pad_speed_x = 0
	pad_col = 7

	bar_h = 6

	build_bricks()

	hp = 3
	score = 0
	state = "game"

	relaunch_ball()
end
function build_bricks()
	local i
	brick_x = {}
	brick_y = {}
	brick_v = {}
	brick_w = 9
	brick_h = 4
	for i = 1, 55 do
		add(brick_x, 4 + ((i - 1) % 11) * (brick_w + 2))
		add(brick_y, 20 + flr((i - 1) / 11) * (brick_h + 2))
		add(brick_v, true)
	end
end
function update_gameover()
	if btn(5) then
		start_game()
	end
	if btn(4) then
		to_menu()
	end
end
function to_menu()
	state = "menu"
end
function _draw()
	if state == "menu" then
		draw_menu()
	elseif state == "game" then
		draw_game()
	elseif state == "gameover" then
		draw_gameover()
	end
end
function draw_game()
	cls(1)
	local i
	rectfill(pad_x, pad_y, pad_x + pad_w, pad_y + pad_h, pad_col)
	-- draw bricks

	for i = 1, #brick_x do
		if brick_v[i] then
			rectfill(brick_x[i], brick_y[i], brick_x[i] + brick_w, brick_y[i] + brick_h, 14)
		end
	end

	circfill(ball_x, ball_y, ball_r, ball_col)
	rectfill(0, 0, 128, bar_h, 0)
	print("♥:" .. hp, 0, 0, 2)
	print("score:" .. score, 40, 0, 2)
end
function draw_menu()
	cls()
	print("pico8 🐱 breakout", 20, 50, 2)
	print("press ❎ to start", 20, 60, 3)
end
function draw_gameover()
	print("game 🐱 over", 30, 50, 2)
	print("press ❎ to restart", 20, 60, 3)
	print("press z to menu", 25, 70, 3)
end

function is_ball_collide(ball_x, ball_y, box_x, box_y, box_w, box_h)
	if ball_y - ball_r > box_y + box_h then
		return false
	end
	if ball_y + ball_r < box_y then
		return false
	end
	if ball_x - ball_r > box_x + box_w then
		return false
	end
	if ball_x + ball_r < box_x then
		return false
	end

	return true
end

function find_collision_direction(bx, by, bdx, bdy, tx, ty, tw, th)
	-- ノよなヒとこ1ヤもあハ⌂きハ✽しフ…⬇️ハ♪⌂ハゆ░ヤも😐フ⬆️そフ…⬇️ヘゆみフも▤ノめこヒいよフ…⬇️ハよ⬇️ヘなくフな❎
	local ball_edge_x = bx + (bdx > 0 and ball_r or -ball_r)
	local ball_edge_y = by + (bdy > 0 and ball_r or -ball_r)
	bx = ball_edge_x
	by = ball_edge_y

	local slope = bdy / bdx
	local cx, cy

	if bdx == 0 then
		return false
	elseif bdy == 0 then
		return true
	elseif slope > 0 and bdx > 0 then
		cx = tx - bx
		cy = ty - by
		return cx > 0 and cy / cx < slope
	elseif slope < 0 and bdx > 0 then
		cx = tx - bx
		cy = ty + th - by
		return cx > 0 and cy / cx >= slope
	elseif slope > 0 and bdx < 0 then
		cx = tx + tw - bx
		cy = ty + th - by
		return cx < 0 and cy / cx <= slope
	else
		cx = tx + tw - bx
		cy = ty - by
		return cx < 0 and cy / cx >= slope
	end
	return false
end

__gfx__
00000000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006606660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006606600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003c0503805034050310502e0502a050270502505023050220501f0501b0501705014050100500d0500b0500005007000050000200001000000000a0000900007000060000400003000020000200002000
000100001c0601805014040120400f0400d0400b03009030080300403000020170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002a45026450214501d4501a45017450134500f4500c4500945006450004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000015050170501a0501d050230502c0503405016000180001a0001c0001f0002300028000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
