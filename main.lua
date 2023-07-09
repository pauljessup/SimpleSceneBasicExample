--this will be the main example file.
simpleScene=require("simpleSceneDesigner")
love.graphics.setDefaultFilter("nearest","nearest")

local cooldown=0.0 --for keypresses, so they don't repeat a billion times.

----------------------------THIS IS ALL ANIMATION STUFF FOR DOING SPRITE ANIMATIONS. NOT PART OF SIMPLESCENEDESIGNER------
--this is the basic quad for animations, since all the sprites are the same size/etc.
--local animQuad=love.graphics.newQuad()
local animQuads={}


--these are the animation functions. these are not a part of simpleSceneDesigner,
--just an example of how to do animations. Hopefully this will give you an idea
--on how to impliment your own animation library/functions in the update and draw methods
--for each object.
local function initAnimation()
    --this creates our quad. We have animations for each cardinal direction.
    local sets={"down", "left", "right", "up"}
    for y,v in ipairs(sets) do
        animQuads[v]={}
        --four frames per animation. each frame is 24x24
        for x=0, 3 do
            animQuads[v][x] = love.graphics.newQuad(x*24, (y-1)*24, 24, 24, 96, 96)
        end
    end
end
--this
local function updateAnimation(animation)
    if animation.timer>1.0 then 
        animation.timer=0.0
        animation.frame=animation.frame+1
        if animation.frame>3 then animation.frame=0 end
    else
        animation.timer=animation.timer+0.1
    end
end
local function drawAnimation(image, animation, x, y)
        love.graphics.draw(image, animQuads[animation.dir][animation.frame], x, y)
end
-------------------------------END ANIMATIONS-----------------------------------------------------------
------------------------------And here is dumb simple collision routine for bounding boxes. Not a part of the simpleDesignScene library, just
--an example on how to do it. Feel free to use your own.
function collide(a, v)
    if   a.x < v.x+v.w and
    v.x < a.x+a.w and
    a.y < v.y+v.h and
    v.y < a.y+a.h 
    then
        return true
    end
    return false
end
------------------------------END COLLISION----------------------------------------------------------

function love.load() 
    --we init the animation system. Not part of Simple Scene, you can roll your own, use this one, or use a library.
    initAnimation()

    --when we init we set the directories where it will find stuff.
    --default is same directory as source files, or "/"
    --we set the editor asset directory to be editorAssets
    simpleScene:init({
        directories={   editor="editorAssets/",
                        music="music/",
                        scenes="scenes/",
                        sprites="sprites/",
                        layers="backgrounds/"}})

    --adding our object types
    --these are things we can add on our scene, like trees, NPC's, player, enemies, etc.


    --the player.
    --as you can see, with each type we can also add additional functions to be called during the gameplay
    --available functions to add-
    -- init(self, obj, simpleScene) called when object is added to the map
    -- update(self, obj, simpleScene, dt) called each update for the object.
    -- draw(self, obj, simplScene) this is called instead of the draw. The others don't replace the original function, but this will. Good for animations.
    simpleScene:addObjectType({type="player", image="player.png",
                                init=function(self, obj, simpleScene)
                                    --set up the animation. Not a part of simpleScene, custom code. Use your own, if you wish.
                                    obj.animation={frame=1, dir="down", timer=0.0, speed=1.0}
                                    --we make this seperate than obj.image
                                    obj.animImage=love.graphics.newImage("sprites/" .. obj.type .. "anim.png")
                                end,
                                update=function(self, obj, simpleScene, dt)
                                     
                                    local move={x=0, y=0}
                                    --walk the player object if key is pressed.
                                    if love.keyboard.isDown("up") then  move.y=move.y-1 obj.animation.dir="up" end 
                                    if love.keyboard.isDown("down") then move.y=move.y+1 obj.animation.dir="down" end 
                                    if love.keyboard.isDown("left") then move.x=move.x-1 obj.animation.dir="left" end
                                    if love.keyboard.isDown("right") then move.x=move.x+1 obj.animation.dir="right" end
                                    --update animation if you moved.
                                    if move.x~=0 or move.y~=0 then updateAnimation(obj.animation) end

                                    for i,v in ipairs(simpleScene.objects) do 
                                        --don't collide self.
                                        if v.id~=obj.id then
                                            --there is a weird 6 pixel padding around the sprites on the images.
                                            --take a look and se what I mean. the images are in a 24x24 grid, but are 16x6. 
                                            --so we have to add 6 pixels to our bounding box to make up for this.
                                            --in a normal game, it would be better to just set a bounding box for each sprite.
                                            --since this is an example, this is far quicker.
                                            local objBoundingBox={x=v.x+6, y=v.y+6, w=v.width-6, h=v.height-6}
                                            
                                            --the only one that is not like that is collide.
                                            if v.type=="collision" then objBoundingBox={x=v.x, y=v.y, w=v.width, h=v.height} end

                                            --check move x collide
                                            if collide({x=(obj.x+move.x)+6, y=(obj.y)+6, w=obj.width-6, h=obj.height-6}, objBoundingBox) then  move.x=0  end
                                            --check move y collide
                                            if collide({x=(obj.x)+6, y=(obj.y+move.y)+6, w=obj.width-6, h=obj.height-6}, objBoundingBox) then  move.y=0  end

                                        end
                                    end

                                        --move the object, then have the camera follow the player.
                                        simpleScene:moveObject(obj, move.x, move.y)
                                        simpleScene:cameraFollowObject(obj)
                                        simpleScene:cameraClampLayer(obj.layer)
                                end,
                                draw=function(self, obj, simpleScene)
                                    drawAnimation(obj.animImage, obj.animation, obj.x, obj.y)
                                end,
                            })

    --we have four npc's, numerated, so we'll do this quick.
    for i=1, 4 do
        simpleScene:addObjectType({type="npc" .. i , image="npc" .. i .. ".png",})
    end

    --and now a collision object that does nothing but collide.
    simpleScene:addObjectType({type="collision", image="collision.png",
                                draw=function(self, obj, simpleScene)
                                    --only draw if we're in the editor.
                                    if simpleScene.editing==true then
                                        love.graphics.draw(self.image, obj.x, obj.y)
                                    end
                                end,
                            })

    --now we load the scene. This is our test scene
    simpleScene:load("treeTest.scene")
    --and let's play some music
    simpleScene:playMusic()
end

function love.update(dt)
    --update the simpleScene system
    simpleScene:update(dt)
    
    --if press escape and we are not editing, we open the simle scene designer.
    --if we are editing, then we close it.
    if love.keyboard.isDown("escape") and cooldown==0.0 then
        cooldown=1.0
        if simpleScene.editing==false then simpleScene:startEditing() else simpleScene:endEditing() end
    end

    --update the cooldown timer for keypresses in the game.
    if cooldown>0.0 then cooldown=cooldown-0.1 else cooldown=0.0 end
end

function love.draw()
    --draw the game.
    simpleScene:draw()

    --now we draw a simple text telling us to press escape to switch between game and editor.
    love.graphics.scale(2, 2)

    local text="-press escape to go to scene designer-"
    local font=love.graphics.getFont()
    
    if simpleScene.editing then text="-press escape to return to game-" end
    love.graphics.print(text, (love.graphics.getHeight()/2)-(font:getWidth(text)/2), (love.graphics.getHeight()/2)-(font:getHeight()+5))
end
