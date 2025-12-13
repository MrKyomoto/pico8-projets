pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- ====================== 常量定义（集中管理，方便修改） ======================
local CONST = {
  -- 屏幕参数
  SCREEN_W = 127,
  SCREEN_H = 127,
  BAR_H = 6,
  -- 球拍参数
  PAD_W = 24,
  PAD_H = 3,
  PAD_SPEED = 5,
  PAD_FRICTION = 1.7,
  PAD_Y = 122,
  -- 小球参数
  BALL_R = 2,
  BALL_INIT_SPEED_X = 2.5,
  BALL_INIT_SPEED_Y = 2,
  -- 砖块参数
  BRICK_W = 9,
  BRICK_H = 4,
  BRICK_COL_NUM = 11,
  BRICK_ROW_NUM = 5,
  BRICK_SPACING = 2,
  BRICK_START_X = 4,
  BRICK_START_Y = 20,
  -- 音效/颜色
  SFX_BOUNCE = 1,
  SFX_PADDLE = 0,
  SFX_BRICK = 3,
  SFX_DEATH = 2,
  COL_PAD_NORMAL = 7,
  COL_PAD_HIT = 8,
  COL_BRICK = 14,
  COL_BG = 1,
  COL_BAR = 0,
  COL_TEXT = 2,
  COL_MENU_TEXT = 3
}

-- ====================== 全局游戏状态（精简命名，统一管理） ======================
local game = {
  state = "menu",  -- menu/game/gameover
  hp = 3,
  score = 0,
  -- 球拍
  pad_x = 52,
  pad_speed_x = 0,
  pad_col = CONST.COL_PAD_NORMAL,
  -- 小球
  ball_x = 1,
  ball_y = 10,
  ball_speed_x = 0,
  ball_speed_y = 0,
  ball_col = 0,
  -- 砖块
  bricks = {x = {}, y = {}, active = {}}  -- 合并砖块数组，更易管理
}

-- ====================== 初始化/主循环（核心流程） ======================
function _init()
  cls()
  to_menu()
end

function _update()
  if game.state == "menu" then
    update_menu()
  elseif game.state == "game" then
    update_game()
  elseif game.state == "gameover" then
    update_gameover()
  end
end

function _draw()
  cls(CONST.COL_BG)  -- 统一背景色，避免重复cls
  if game.state == "menu" then
    draw_menu()
  elseif game.state == "game" then
    draw_game()
  elseif game.state == "gameover" then
    draw_gameover()
  end
end

-- ====================== 菜单逻辑 ======================
function to_menu()
  game.state = "menu"
end

function update_menu()
  if btn(5) then  -- ❎键开始游戏
    start_game()
  end
end

function draw_menu()
  cls()  -- 菜单单独清屏
  print("pico8 🐱 breakout", 20, 50, CONST.COL_TEXT)
  print("press ❎ to start", 20, 60, CONST.COL_MENU_TEXT)
end

-- ====================== 游戏核心逻辑 ======================
function start_game()
  -- 重置游戏状态
  game.hp = 3
  game.score = 0
  
  -- 重置球拍
  game.pad_x = (CONST.SCREEN_W - CONST.PAD_W) / 2  -- 居中，更合理
  game.pad_speed_x = 0
  game.pad_col = CONST.COL_PAD_NORMAL
  
  -- 重置小球
  relaunch_ball()
  
  -- 重建砖块
  build_bricks()
  
  game.state = "game"
end

function update_game()
  -- 1. 球拍控制
  update_paddle()
  
  -- 2. 计算小球下一个位置
  local next_x = game.ball_x + game.ball_speed_x
  local next_y = game.ball_y + game.ball_speed_y
  game.ball_col = (game.ball_col + 1) % 16  -- 颜色循环，避免越界
  
  -- 3. 边界碰撞检测（上下左右）
  check_screen_bounds(next_x, next_y)
  
  -- 4. 球拍碰撞检测
  game.pad_col = CONST.COL_PAD_NORMAL
  if check_ball_collision(next_x, next_y, game.pad_x, CONST.PAD_Y, CONST.PAD_W, CONST.PAD_H) then
    game.pad_col = CONST.COL_PAD_HIT
    resolve_collision(next_x, next_y, game.pad_x, CONST.PAD_Y, CONST.PAD_W, CONST.PAD_H)
    game.score += 1
    sfx(CONST.SFX_PADDLE)
  end
  
  -- 5. 砖块碰撞检测（优化循环，提前终止无意义遍历）
  check_brick_collisions(next_x, next_y)
  
  -- 6. 更新小球位置
  game.ball_x = next_x
  game.ball_y = next_y
  
  -- 7. 小球落地检测
  if next_y + CONST.BALL_R > CONST.SCREEN_H then
    handle_ball_death()
  end
end

function draw_game()
  -- 绘制球拍
  rectfill(game.pad_x, CONST.PAD_Y, game.pad_x + CONST.PAD_W, CONST.PAD_Y + CONST.PAD_H, game.pad_col)
  
  -- 绘制砖块（优化循环，减少表长度查询）
  local brick_count = #game.bricks.x
  for i = 1, brick_count do
    if game.bricks.active[i] then
      rectfill(
        game.bricks.x[i], game.bricks.y[i],
        game.bricks.x[i] + CONST.BRICK_W, game.bricks.y[i] + CONST.BRICK_H,
        CONST.COL_BRICK
      )
    end
  end
  
  -- 绘制小球
  circfill(game.ball_x, game.ball_y, CONST.BALL_R, game.ball_col)
  
  -- 绘制顶部状态栏
  rectfill(0, 0, CONST.SCREEN_W + 1, CONST.BAR_H, CONST.COL_BAR)
  print("♥:" .. game.hp, 0, 0, CONST.COL_TEXT)
  print("score:" .. game.score, 40, 0, CONST.COL_TEXT)
end

-- ====================== 球拍控制（拆分独立函数，降低复杂度） ======================
function update_paddle()
  local btn_pressed = false
  
  if btn(0) then  -- 左
    game.pad_speed_x = -CONST.PAD_SPEED
    btn_pressed = true
  end
  if btn(1) then  -- 右
    game.pad_speed_x = CONST.PAD_SPEED
    btn_pressed = true
  end
  
  -- 摩擦力
  if not btn_pressed then
    game.pad_speed_x /= CONST.PAD_FRICTION
  end
  
  -- 更新位置并限制边界
  game.pad_x += game.pad_speed_x
  game.pad_x = mid(1, game.pad_x, CONST.SCREEN_W - CONST.PAD_W)  -- 用mid简化边界检查
end

-- ====================== 小球相关逻辑（拆分独立函数） ======================
function relaunch_ball()
  -- 小球重置到球拍上方居中位置，更合理
  game.ball_x = game.pad_x + CONST.PAD_W / 2
  game.ball_y = CONST.PAD_Y - CONST.BALL_R - 1
  game.ball_speed_x = CONST.BALL_INIT_SPEED_X
  game.ball_speed_y = -CONST.BALL_INIT_SPEED_Y  -- 向上发射，避免直接落地
  game.ball_col = 0
end

function check_screen_bounds(next_x, next_y)
  -- 左右边界
  if next_x + CONST.BALL_R > CONST.SCREEN_W then
    game.ball_speed_x = -game.ball_speed_x
    sfx(CONST.SFX_BOUNCE)
    next_x = CONST.SCREEN_W - CONST.BALL_R
  elseif next_x - CONST.BALL_R < 0 then
    game.ball_speed_x = -game.ball_speed_x
    sfx(CONST.SFX_BOUNCE)
    next_x = CONST.BALL_R
  end
  
  -- 上边界（顶部状态栏）
  if next_y - CONST.BALL_R < CONST.BAR_H then
    game.ball_speed_y = -game.ball_speed_y
    sfx(CONST.SFX_BOUNCE)
    next_y = CONST.BAR_H + CONST.BALL_R
  end
end

function handle_ball_death()
  sfx(CONST.SFX_DEATH)
  game.hp -= 1
  
  if game.hp <= 0 then
    game_over()
  else
    game.score = max(0, game.score - 20)  -- 避免分数为负
    relaunch_ball()
  end
end

-- ====================== 砖块相关逻辑 ======================
function build_bricks()
  -- 清空原有砖块
  game.bricks.x = {}
  game.bricks.y = {}
  game.bricks.active = {}
  
  local total_bricks = CONST.BRICK_COL_NUM * CONST.BRICK_ROW_NUM
  local brick_spacing_w = CONST.BRICK_W + CONST.BRICK_SPACING
  local brick_spacing_h = CONST.BRICK_H + CONST.BRICK_SPACING
  
  for i = 1, total_bricks do
    local col = (i - 1) % CONST.BRICK_COL_NUM
    local row = flr((i - 1) / CONST.BRICK_COL_NUM)
    
    add(game.bricks.x, CONST.BRICK_START_X + col * brick_spacing_w)
    add(game.bricks.y, CONST.BRICK_START_Y + row * brick_spacing_h)
    add(game.bricks.active, true)
  end
end

function check_brick_collisions(next_x, next_y)
  local brick_count = #game.bricks.x
  for i = 1, brick_count do
    if game.bricks.active[i] then
      local bx = game.bricks.x[i]
      local by = game.bricks.y[i]
      
      if check_ball_collision(next_x, next_y, bx, by, CONST.BRICK_W, CONST.BRICK_H) then
        -- 解析碰撞方向并反弹
        resolve_collision(next_x, next_y, bx, by, CONST.BRICK_W, CONST.BRICK_H)
        -- 标记砖块为非活动
        game.bricks.active[i] = false
        -- 加分并播放音效
        game.score += 10
        sfx(CONST.SFX_BRICK)
        break  -- 一次只碰撞一个砖块，更符合物理逻辑
      end
    end
  end
end

-- ====================== 碰撞检测（核心逻辑封装） ======================
function check_ball_collision(ball_x, ball_y, box_x, box_y, box_w, box_h)
  -- 轴对齐包围盒（AABB）碰撞检测，简化逻辑
  local ball_left = ball_x - CONST.BALL_R
  local ball_right = ball_x + CONST.BALL_R
  local ball_top = ball_y - CONST.BALL_R
  local ball_bottom = ball_y + CONST.BALL_R
  
  local box_left = box_x
  local box_right = box_x + box_w
  local box_top = box_y
  local box_bottom = box_y + box_h
  
  return not (ball_left > box_right or 
              ball_right < box_left or 
              ball_top > box_bottom or 
              ball_bottom < box_top)
end

function resolve_collision(bx, by, tx, ty, tw, th)
  -- 修复除零错误，优化碰撞方向判断
  local bdx = game.ball_speed_x
  local bdy = game.ball_speed_y
  
  if abs(bdx) < 0.1 then bdx = 0.1 end  -- 避免除零
  if abs(bdy) < 0.1 then bdy = 0.1 end
  
  local ball_edge_x = bx + (bdx > 0 and CONST.BALL_R or -CONST.BALL_R)
  local ball_edge_y = by + (bdy > 0 and CONST.BALL_R or -CONST.BALL_R)
  local slope = bdy / bdx
  
  local cx, cy
  local hit_horizontal = false
  
  if bdx > 0 and slope > 0 then
    cx = tx - ball_edge_x
    cy = ty - ball_edge_y
    hit_horizontal = (cx > 0 and cy / cx < slope)
  elseif bdx > 0 and slope < 0 then
    cx = tx - ball_edge_x
    cy = ty + th - ball_edge_y
    hit_horizontal = (cx > 0 and cy / cx >= slope)
  elseif bdx < 0 and slope > 0 then
    cx = tx + tw - ball_edge_x
    cy = ty + th - ball_edge_y
    hit_horizontal = (cx < 0 and cy / cx <= slope)
  else
    cx = tx + tw - ball_edge_x
    cy = ty - ball_edge_y
    hit_horizontal = (cx < 0 and cy / cx >= slope)
  end
  
  -- 根据碰撞方向反弹
  if hit_horizontal then
    game.ball_speed_x = -game.ball_speed_x
  else
    game.ball_speed_y = -game.ball_speed_y
  end
end

-- ====================== 游戏结束逻辑 ======================
function game_over()
  game.state = "gameover"
  sfx(CONST.SFX_BOUNCE)  -- 游戏结束音效
end

function update_gameover()
  if btn(5) then  -- ❎键重启游戏
    start_game()
  end
  if btn(4) then  -- Z键返回菜单
    to_menu()
  end
end

function draw_gameover()
  print("game 🐱 over", 30, 50, CONST.COL_TEXT)
  print("press ❎ to restart", 20, 60, CONST.COL_MENU_TEXT)
  print("press z to menu", 25, 70, CONST.COL_MENU_TEXT)
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
