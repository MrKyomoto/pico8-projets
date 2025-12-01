pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	cls()
	-- NOTE: ball param
	ball_x = 1
	ball_y = 1

	ball_speed_x = 2.5
	ball_speed_y = 2

	ball_r = 2
	ball_col = 0

	-- NOTE: pad param
	pad_x = 52
	pad_y = 122
	pad_w = 24
	pad_h = 3
	pad_speed_x = 0
	pad_col = 7
end

function _update()
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

	if next_y + ball_r > 127 then 
		ball_speed_y = -ball_speed_y
		sfx(1)
		next_y = 127 - ball_r
	elseif next_y - ball_r < 0 then
		ball_speed_y = -ball_speed_y
		sfx(1)
		next_y = ball_r
	end

	pad_col = 7
	-- check paddle collision
	if is_ball_collide(next_x, next_y,pad_x, pad_y, pad_w, pad_h) then
		pad_col = 8
		-- find out the collision direction
		if find_collision_direction(ball_x,ball_y,ball_speed_x,ball_speed_y,pad_x,pad_y,pad_w,pad_h) then
			ball_speed_x = -ball_speed_x
		else
			ball_speed_y = -ball_speed_y
		end
		sfx(0)
	end

	ball_x = next_x
	ball_y = next_y
	ball_col += 1
end

function _draw()
	rectfill(0, 0, 127, 127, 1)
	rectfill(pad_x, pad_y, pad_x + pad_w, pad_y + pad_h, pad_col)
	circfill(ball_x, ball_y, ball_r, ball_col)
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
    -- 修正1：加入球半径，用球边缘代替球心计算
    local ball_edge_x = bx + (bdx > 0 and ball_r or -ball_r)
    local ball_edge_y = by + (bdy > 0 and ball_r or -ball_r)
    bx = ball_edge_x
    by = ball_edge_y

    if bdx == 0 then
        return false
    elseif bdy == 0 then
        return true
    else
        local slope = bdy / bdx
        local cx, cy
        if slope > 0 and bdx > 0 then
            cx = tx - bx
            cy = ty - by
            if cx <= 0 then
                return false
            -- 修正2：判定条件取反
            elseif cy / cx > slope then 
                return true
            else
                return false
            end
        elseif slope < 0 and bdx > 0 then
            cx = tx - bx
            cy = ty + th - by
            if cx <= 0 then
                return false
            -- 修正2：判定条件取反
            elseif cy / cx > slope then
                return true
            else
                return false
            end
        elseif slope > 0 and bdx < 0 then
            cx = tx + tw - bx
            cy = ty + th - by
            if cx >= 0 then
                return false
            -- 修正2：判定条件取反
            elseif cy / cx < slope then
                return true
            else
                return false
            end
        else
            cx = tx + tw - bx
            cy = ty - by
            if cx >= 0 then
                return false
            -- 修正2：判定条件取反
            elseif cy / cx > slope then
                return true
            else
                return false
            end
        end
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
