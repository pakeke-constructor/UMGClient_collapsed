
local balls = {}


local SPD=100

local function makeBall()
    local dx,dy = love.math.random(-20,20), love.math.random(-20,20)
    local mag = math.sqrt(dx*dx + dy*dy)
    if mag > 0 then
        dx=(dx/mag) * SPD
        dy=(dy/mag) * SPD
    else
        dx=SPD
        dy=0
    end

    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    local rad = 0.05 + love.math.random() / 10
    local x,y = love.math.random(0, w), love.math.random(0,h)
    table.insert(balls, {
        x=x, y=y, 
        dx = dx, dy = dy,
        radius = rad
    })
end


local function update(dt)
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()

    for _, ball in ipairs(balls)do
        ball.x = ball.x + ball.dx*dt
        ball.y = ball.y + ball.dy*dt
        
        if (ball.x < 0) then
            ball.x = 0
            ball.dx=-ball.dx
        elseif (ball.x > w) then
            ball.x = w
            ball.dx = -ball.dx
        end

        if (ball.y < 0) then
            ball.y = 0
            ball.dy = -ball.dy
        elseif (ball.y > (h - 0)) then
            ball.y = h
            ball.dy = -ball.dy
        end
    end
end

local lg = love.graphics

local sin, cos = math.sin, math.cos
local min = math.min



local function draw()
    local tt = love.timer.getTime()/30
    local r = min(sin(tt-1)+0.7, 1)
    local g = min(sin(tt+ math.pi)+0.7, 1)
    local b = min(cos(tt)+0.7, 1)

    lg.clear(r,g,b)

    lg.setColor(r-0.05,g-0.05,b-0.05)

    for _, ball in ipairs(balls) do
        local radius = love.graphics.getWidth() * ball.radius
        love.graphics.circle("fill", ball.x, ball.y, radius)
    end
end



return {
    makeBall = makeBall;
    update = update;
    draw = draw
}

