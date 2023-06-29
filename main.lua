--this will be the main example file.
simpleScene=require("simpleSceneDesigner")
love.graphics.setDefaultFilter("nearest","nearest")

local cooldown=0.0 --for keypresses, so they don't repeat a billion times.

function love.load() 
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

    --the player.
    simpleScene:addObjectType({type="player", image="player.png",
                                update=function(self, obj, simpleScene, dt)
                                    local move={x=0, y=0}
                                    --walk the player object if key is pressed.
                                    if love.keyboard.isDown("up") then  move.y=move.y-1 end 
                                    if love.keyboard.isDown("down") then move.y=move.y+1 end 
                                    if love.keyboard.isDown("left") then move.x=move.x-1 end
                                    if love.keyboard.isDown("right") then move.x=move.x+1 end
                                    
                                    --move the object, then have the camera follow the player.
                                    simpleScene:moveObject(obj, move.x, move.y)
                                    simpleScene:cameraFollowObject(obj)
                                    simpleScene:cameraClampLayer(obj.layer)
                                end,
                            })

    --we have four npc's, numerated, so we'll do this quick.
    for i=1, 4 do
        simpleScene:addObjectType({type="npc" .. i , image="npc" .. i .. ".png",})
    end

    --and now a collision object that does nothing but collide.
    simpleScene:addObjectType({type="collision", image="collision.png",
                                update=function(self, obj, simpleScene, dt)
                                end,
                                draw=function(self, obj, simpleScene)
                                    --only draw if we're in the editor.
                                    if simpleScene.editing==true then
                                        love.graphics.draw(self.image, obj.x, obj.y)
                                    end
                                end,
                            })

    simpleScene:load("treeTest.scene")
    --simpleScene:playMusic()
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
    simpleScene:draw()
    love.graphics.scale(2, 2)

    local text="-press escape to go to scene designer-"
    local font=love.graphics.getFont()
    
    if simpleScene.editing then text="-press escape to return to game-" end
    love.graphics.print(text, (love.graphics.getHeight()/2)-(font:getWidth(text)/2), (love.graphics.getHeight()/2)-(font:getHeight()+5))
end
