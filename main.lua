require 'explosion'
Class = require('hump.class')

highScore = 0;
playerImg = nil
enemyImg = nil
shootSound = nil
exploSounds = {}
enemyTypes = {};

Sprite = Class{}

function Sprite:init(x,y,img,cx,cy)
	self.x = x
	self.y = y
	self.alive = true
	self.dx = 0
	self.dy = 0
	self.sx = 1.0
	self.sy = 1.0
	self.cx = 1.0
	self.cy = 1.0
	setImage(self,img,cx,cy)
end

function Sprite:setVelo(dx, dy)
	self.dx = dx
	self.dy = dy
end

function Sprite:setScale(sx, sy)
	self.sx = sx
	self.sy = sy
end

function Sprite:setPosition(x,y)
	self.x = x
	self.y = y
end

function Sprite:setSpatial(x,y,dx,dy)
	self:setPosition(x,y)
	self:setVelo(dx,dy)
end

function Sprite:overlaps(other)
	return checkCollision(self.x - self.ox, self.y - self.oy, self.cx, self.cy, 
		other.x - other.ox, other.y - other.oy, other.cx, other.cy)
end

function Sprite:update(dt)
	if (not self.alive) then
		return false;
	end
	self.x = self.x + (self.dx * dt);
	self.y = self.y + (self.dy * dt);
	
	if ((self.x < -20) or (self.x > love.graphics.getWidth() + self.ox)) then
		self.alive = false
		return false;
	end
--[[
	if self.y < -50 then -- remove bullets when they pass off the screen
		self.alive = false
		return false;
	end
	]]--
	if (self.y > (love.graphics.getHeight() + self.oy)) then -- remove enemies when they pass off the screen
		self.alive = false
		return false;
	end
	return self.alive
end

Cloud = Class{__includes = Sprite}

function Cloud:init(x,y)
	Sprite.init(self,x,y,cloudImg)
	self:setVelo(0,70 + math.random(1,15))
	self:setScale(0.7 + (math.random(1,60) * 0.01),0.7 + (math.random(1,60) * 0.01))
end

function Cloud:update(dt)
	if (Sprite.update(self,dt) == false) then
		self:setPosition(math.random(10, love.graphics.getWidth() - 10),-cloudImg:getHeight())
		self.alive = true
	end
end

Bullet = Class{__includes = Sprite}

function Bullet:init(x,y,dx,dy)
	Sprite.init(self,x,y,bulletImg)
	self:setVelo(dx,dy)
end

BallShot = Class{__includes = Sprite}

function BallShot:init(x,y,dx,dy)
	Sprite.init(self,x,y,enemyShotImg)
	self:setVelo(dx,dy)
end

function setImage(object, image, colx, coly)
	object.img = image;
	object.cx = image:getWidth() * (colx or 1.0);
	object.cy = image:getHeight() * (coly or 1.0);
	object.ox = image:getWidth() * 0.5;
	object.oy = image:getHeight() * 0.5;
end

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
	playerImg = love.graphics.newImage('assets/plane.png')  
	bulletImg = love.graphics.newImage('assets/bullet.png')
	enemyImg = love.graphics.newImage('assets/enemy.png')
	b17Img = love.graphics.newImage('assets/B-17-2.png');
	enemyShotImg = love.graphics.newImage('assets/shotoval.png');
	cloudImg = love.graphics.newImage('assets/cloud_1.jpg');
	
	shootSound = love.audio.newSource("assets/gun-sound.wav", "static");
	shoot_2_sound = love.audio.newSource("assets/bang2.wav", "static");
	table.insert(exploSounds,love.audio.newSource("assets/explo1.ogg", "static"));
	table.insert(exploSounds,love.audio.newSource("assets/explo2.ogg", "static"));
	
	table.insert(enemyTypes, 
		{ img = enemyImg, theta = 0, points = 10, health = 1, ox = enemyImg:getWidth() / 2, oy = enemyImg:getHeight() / 2, 
			numExplosions = 1,
			fireDelay = 1.5,
			speed = 150 });
	table.insert(enemyTypes, 
		{ img = b17Img, theta = math.pi, points = 20, health = 2, ox = b17Img:getWidth() / 2, oy = b17Img:getHeight() / 2, 
			numExplosions = 3,
			fireDelay = 1.0,
			speed = 120});
	
	start()
end

function start()

	game = {
		score = 0,
		enemyBullets = {},
		clouds = {},
		bullets = {}
	}
	
	wave = {
		next = 0,
	}

	player = {
		x = 100,
		y = 700,
		dx = 150,
		dy = 0,
		canShoot = true,
		canShootTimerMax = 0.2, 
		canShootTimer = canShootTimerMax,
		alive = true
	}
	
	player.canShootTimer = player.canShootTimerMax

	setImage(player,playerImg, 0.7, 0.4);
	
	enemies = {};
	
	game.addCloud = function(game)
		local newCloud = Cloud(math.random(10, love.graphics.getWidth() - 10),
			math.random(10, love.graphics.getHeight() - 10))
		table.insert(game.clouds, newCloud);
	end
	
	for i = 1,3,1 do
		game:addCloud();
	end
end

function playSound(sound) 
	local soundInstance = sound:clone();
	love.audio.play(soundInstance);
end

function addBullet()
	--recycle objects?
	local newBullet = nil
	for i, bullet in ipairs(game.bullets) do
		if (bullet.alive == false) then
			newBullet = bullet
			break;
		end
	end
	if (newBullet == nil) then
		newBullet = Bullet(player.x,player.y,0,-250)
		table.insert(game.bullets, newBullet);
	end
	newBullet.x = player.x
	newBullet.y = player.y
	newBullet.alive = true
end

function addEnemyBullet(x, y, dx, dy)
	local newBullet = BallShot(x,y,dx,dy)
	table.insert(game.enemyBullets, newBullet)
end

function addEnemy() 
	local idx = math.random(1,2);
	local img = enemyTypes[idx].img;
	local theta = enemyTypes[idx].theta;
	
	local enemyType = enemyTypes[idx];
	
	local enemy = { 
		alive = true,
		x = math.random(10, love.graphics.getWidth() - 10),
		y = -img:getHeight(),
		dx = 0,
		dy = enemyType.speed,
		theta = theta,
		health = enemyTypes[idx].health,
		enemyType = enemyTypes[idx],
		timer = math.random(-100,100) * 0.007;
	}
	setImage(enemy,img,0.8,0.6)
	table.insert(enemies, enemy)
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function checkObjectCollision(obj1, obj2)
	return checkCollision(obj1.x - obj1.ox, obj1.y - obj1.oy, obj1.cx, obj1.cy, 
		obj2.x - obj2.ox, obj2.y - obj2.oy, obj2.cx, obj2.cy)
end

function spawnExplosions(x,y,count)
	effects:spawn('explosion',x,y);
	if (count > 1) then
		for i=2,count,1 do
			effects:spawn('explosion',x + math.random(-50,50),y + math.random(-50,50));
		end
	end
end

function hitEnemy(enemy)
	enemy.health = enemy.health - 1;
	if (enemy.health < 1) then
		enemy.alive = false;
		game.score = game.score + enemy.enemyType.points;
		if (game.score > highScore) then
			highScore = game.score;
		end
		local boom = exploSounds[math.random(1,#exploSounds)]:clone();
		love.audio.play(boom);
		spawnExplosions(enemy.x,enemy.y,enemy.enemyType.numExplosions);
		return true;
	end
	return false;
end

function hitPlayer()
	player.alive = false
	local x = player.x;
	local y = player.y;
	spawnExplosions(x,y,4);
	local sparks = effects:spawn('redSparks',x + math.random(-40,40),y + math.random(-40,40));
	sparks.dx = math.random(-400,400); sparks.dy = math.random(-400,400);
	sparks = effects:spawn('greenSparks',x + math.random(-40,40),y + math.random(-40,40));
	sparks.dx = math.random(-400,400); sparks.dy = math.random(-400,400);
	sparks = effects:spawn('blueSparks',x + math.random(-40,40),y + math.random(-40,40));
	sparks.dx = math.random(-400,400); sparks.dy = math.random(-400,400);
	
	local boom = exploSounds[math.random(1,#exploSounds)]:clone();
	love.audio.play(boom);
end

function collisions()
	for i, enemy in ipairs(enemies) do
		if (enemy.alive) then
			for j, bullet in ipairs(game.bullets) do
				if bullet.alive then
					if checkObjectCollision(enemy, bullet) then
						bullet.alive = false
						--table.remove(game.bullets, j)
						if (hitEnemy(enemy)) then
							table.remove(enemies, i)
						else
							effects:spawn('blueSparks',bullet.x + math.random(-40,40),bullet.y + math.random(-40,40));
						end
					end
				end
			end

			if (player.alive) then
				if checkObjectCollision(enemy, player) then 
					table.remove(enemies, i)
					hitPlayer();
				end
			end
		end
	end
	
	if (player.alive) then
		for j, bullet in ipairs(game.enemyBullets) do
			if checkObjectCollision(player, bullet) then
				table.remove(game.enemyBullets, j)
				hitPlayer();
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

function updateObject(object, dt)
	if (not object.alive) then
		return false;
	end
	object.x = object.x + (object.dx * dt);
	object.y = object.y + (object.dy * dt);
	
	if ((object.x < -20) or (object.x > love.graphics.getWidth() + object.ox)) then
		object.alive = false
		return false;
	end
--[[
	if object.y < -50 then -- remove bullets when they pass off the screen
		object.alive = false
		return false;
	end
	]]--
	if (object.y > (love.graphics.getHeight() + object.oy)) then -- remove enemies when they pass off the screen
		object.alive = false
		return false;
	end
	return object.alive
end

function updateEnemy(enemy, dt)
	if (not updateObject(enemy,dt)) then
		return false
	end
	
	enemy.timer = enemy.timer + dt;
	if (enemy.timer > enemy.enemyType.fireDelay) then
		addEnemyBullet(enemy.x, enemy.y + enemy.img:getHeight() * 0.2, 0, 220);
		enemy.timer = 0.0;
		local shotSound = shoot_2_sound:clone();
		love.audio.play(shotSound);
	end

	return true;
end

function updateBullet(bullet, dt)
	if (not updateObject(bullet,dt)) then
		return false
	end
	
	return bullet.alive;
end

function updateSprite(sprite, dt)
	if (not updateObject(sprite,dt)) then
		return false
	end
	
	return true;
end

function update(game, dt)
	for i, cloud in ipairs(game.clouds) do
		cloud:update(dt)
	end
	
	for i, bullet in ipairs(game.bullets) do
		bullet:update(dt)
	end
	
	for i, bullet in ipairs(game.enemyBullets) do
		if (bullet:update(dt) == false) then
			table.remove(game.enemyBullets, i)
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

function love.update(dt)
	
	if love.keyboard.isDown('escape') then
		love.event.push('quit')
	end
	
	update(game, dt);
	
	if (player.alive) then
		if (player.canShootTimer > 0) then
			player.canShootTimer = player.canShootTimer - (1 * dt)
			if player.canShootTimer < 0 then
			  player.canShoot = true
			end
		end
	
		if love.keyboard.isDown('left','a') then
			if player.x > player.ox * 0.5 then -- binds us to the map
				player.x = player.x - (player.dx*dt)
			end
		elseif love.keyboard.isDown('right','d') then
			if player.x < (love.graphics.getWidth() - player.ox * 0.5) then
				player.x = player.x + (player.dx*dt)
			end
		end

		if love.keyboard.isDown('space', 'rctrl', 'lctrl', 'ctrl') and player.canShoot then
			-- Create some bullets
			addBullet()
			playSound(shootSound)
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
		--effects:spawn('explosion',100,100);
		addEnemyBullet(100,100,0,250);
	end

end

function love.draw()
	love.graphics.setBlendMode("add");
	for i, cloud in ipairs(game.clouds) do
	  love.graphics.draw(cloud.img, cloud.x, cloud.y, cloud.theta or 0, cloud.sx or 1, cloud.sy or 1, cloud.ox or 0.0, cloud.oy or 0.0)
	end
	love.graphics.setBlendMode("alpha");
	
	for i, enemy in ipairs(enemies) do
	  love.graphics.draw(enemy.img, enemy.x, enemy.y, enemy.theta, 1, 1, enemy.ox, enemy.oy)
	end
	
	for i, bullet in ipairs(game.bullets) do
		if (bullet.alive) then
			love.graphics.draw(bullet.img, bullet.x, bullet.y)
		end
	end
	
	for i, bullet in ipairs(game.enemyBullets) do
	  love.graphics.draw(bullet.img, bullet.x, bullet.y)
	end
	
		--love.graphics.setColor(20,255,0,255)
  
	if (player.alive == true) then
		love.graphics.draw(player.img, player.x, player.y, 0, 1, 1, player.ox, player.oy); 
	end
	
	effects.draw(effects.systems);
	
	love.graphics.print("SCORE " .. game.score, 0,0);
	love.graphics.printf("HIGH " .. highScore, love.graphics.getWidth() - 100, 0, 100, "right");
	
	if (player.alive == false) then
			love.graphics.print("Press R to restart", 50,100);

	end
end