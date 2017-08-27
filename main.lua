require 'explosion'

playerImg = nil
enemyImg = nil
shootSound = nil
exploSounds = {}

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
	playerImg = love.graphics.newImage('assets/plane.png')  
	bulletImg = love.graphics.newImage('assets/bullet.png')
	enemyImg = love.graphics.newImage('assets/enemy.png')
	
	shootSound = love.audio.newSource("assets/gun-sound.wav", "static")
	table.insert(exploSounds,love.audio.newSource("assets/explo1.ogg", "static"));
	table.insert(exploSounds,love.audio.newSource("assets/explo2.ogg", "static"));
	
	start()
end

function start()

	game = {
		score = 0,
	}
	
	wave = {
		next = 0,
	}

	player = {
		x = 100,
		y = 700,
		dx = 150,
		dy = 0,
		bullets = {},
		canShoot = true,
		canShootTimerMax = 0.2, 
		canShootTimer = canShootTimerMax,
		alive = true
	}
	
	player.canShootTimer = player.canShootTimerMax
	player.img = playerImg
	
	enemies = {}
end

function addBullet()
	local newBullet = { x = player.x + (player.img:getWidth()/2), y = player.y, img = bulletImg, dx = 0, dy = -250 }
	table.insert(player.bullets, newBullet)
	shootSound:play();
end

function addEnemy() 
	local enemy = { x = math.random(10, love.graphics.getWidth() - 10),
		y = -enemyImg:getHeight(),
		img = enemyImg,
		dx = 0,
		dy = 150,
		points = 10
	}
	table.insert(enemies, enemy)
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function collisions()
	for i, enemy in ipairs(enemies) do
		for j, bullet in ipairs(player.bullets) do
			if checkCollision(enemy.x, enemy.y, enemy.img:getWidth() *0.8, enemy.img:getHeight() * 0.6, bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
				table.remove(player.bullets, j)
				table.remove(enemies, i)
				game.score = game.score + enemy.points
				enemy.points = 0
				local boom = exploSounds[math.random(1,#exploSounds)] :clone();
				love.audio.play(boom);
				effects:spawn('explosion',enemy.x + enemy.img:getWidth() * 0.5,enemy.y + enemy.img:getHeight() * 0.5);
			end
		end

		if (player.alive) then
			if checkCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth() * 0.7, player.img:getHeight() * 0.7) then 
				table.remove(enemies, i)
				player.alive = false
				local x = player.x + player.img:getWidth() * 0.5;
				local y = player.y + player.img:getHeight() * 0.5;
				effects:spawn('explosion',x,y);
				effects:spawn('explosion',x + math.random(-40,40),y + math.random(-40,40));
				effects:spawn('explosion',x + math.random(-40,40),y + math.random(-40,40));
				effects:spawn('explosion',x + math.random(-40,40),y + math.random(-40,40));
				effects:spawn('redSparks',x + math.random(-40,40),y + math.random(-40,40));
				effects:spawn('greenSparks',x + math.random(-40,40),y + math.random(-40,40));
				effects:spawn('blueSparks',x + math.random(-40,40),y + math.random(-40,40));
			end
		end
	end
end

function updateWave(wave, dt)
	if (wave.next <= 0) then
		--time for next wave
		local count = math.random(1,7)
		for i=1,count,1 do
			addEnemy()
		end
		wave.next = 3.0 - (game.score * 0.0025)
		if (wave.next < 0.8) then
			wave.next = 0.8
		end
	else
		wave.next = wave.next - dt
	end	
end

function updateEnemy(enemy, dt)
	enemy.x = enemy.x + (enemy.dx * dt)
	enemy.y = enemy.y + (enemy.dy * dt)

	if enemy.y > love.graphics.getHeight() then -- remove enemies when they pass off the screen
		return false;
	end
	return true;
end

function updateBullet(bullet, dt)
	bullet.x = bullet.x + (bullet.dx * dt)
	bullet.y = bullet.y + (bullet.dy * dt)
	
	if ((bullet.x < -20) or (bullet.x > love.graphics.getWidth())) then
		return false;
	end

	if bullet.y < -20 then -- remove bullets when they pass off the screen
		return false;
	end
	
	if bullet.y > love.graphics.getHeight() then -- remove when they pass off the screen
		return false;
	end
	
	return true;
end

function love.update(dt)
	-- I always start with an easy way to exit the game
	if love.keyboard.isDown('escape') then
		love.event.push('quit')
	end
	
	if (player.alive) then
		if (player.canShootTimer > 0) then
			player.canShootTimer = player.canShootTimer - (1 * dt)
			if player.canShootTimer < 0 then
			  player.canShoot = true
			end
		end
	
		if love.keyboard.isDown('left','a') then
			if player.x > 0 then -- binds us to the map
				player.x = player.x - (player.dx*dt)
			end
		elseif love.keyboard.isDown('right','d') then
			if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
				player.x = player.x + (player.dx*dt)
			end
		end

		if love.keyboard.isDown('space', 'rctrl', 'lctrl', 'ctrl') and player.canShoot then
			-- Create some bullets
			addBullet()
			player.canShoot = false
			player.canShootTimer = player.canShootTimerMax
		end
	else
		if love.keyboard.isDown('r') then
			start();
		end
	end
	
	if love.keyboard.isDown('b') then
		--addEnemy()
		effects:spawn('explosion',100,100);
	end

	for i, bullet in ipairs(player.bullets) do
		if (updateBullet(bullet,dt) == false) then -- remove bullets when they pass off the screen
			table.remove(player.bullets, i)
		end
	end
	
	--move enemies
	for i, enemy in ipairs(enemies) do
		if (updateEnemy(enemy, dt) == false) then
			table.remove(enemies, i)
		end
	end
	
	collisions()
	
	updateWave(wave,dt)
	
	effects.update(dt);
end

function love.draw()
	
	for i, enemy in ipairs(enemies) do
	  love.graphics.draw(enemy.img, enemy.x, enemy.y)
	end
	
	for i, bullet in ipairs(player.bullets) do
	  love.graphics.draw(bulletImg, bullet.x, bullet.y)
	end
	
		--love.graphics.setColor(20,255,0,255)
  
	if (player.alive == true) then
		love.graphics.draw(player.img, player.x, player.y) 
	end
	
	effects.draw(effects.systems);
	
	love.graphics.print("SCORE " .. game.score, 0,0);
	
	if (player.alive == false) then
			love.graphics.print("Press R to restart", 50,100);

	end
end