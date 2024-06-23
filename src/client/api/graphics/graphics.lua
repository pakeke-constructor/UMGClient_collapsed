

local oks = {
    --[[
        list of love.graphics functions that are
        "safe" to have in API.

        Note that a lot of functions starting with "new"
        are unsafe because they access files.
    ]]
    "setStencilTest",
    "printf",
    "getWidth",
    "getStencilTest",
    "getDPIScale",
    "getHeight",
    "push",
    "pop",
    "discard",
    "readbackBuffer",
    "readbackBufferAsync",
    "readbackTexture",
    "readbackTextureAsync",
    "validateShader",
    "setCanvas",
    "getCanvas",
    "getColor",
    "setBackgroundColor",
    "getFont",
    "setColorMask",
    "getColorMask",
    "setBlendMode",
    "getBlendMode",
    "setBlendState",
    "getBlendState",
    "setDefaultFilter",
    "getDefaultFilter",
    "setDefaultMipmapFilter",
    "getDefaultMipmapFilter",
    "setLineWidth",
    "setLineStyle",
    "setLineJoin",
    "getLineWidth",
    "getLineStyle",
    "getLineJoin",
    "setPointSize",
    "getPointSize",
    "setDepthMode",
    "getDepthMode",
    "setMeshCullMode",
    "getMeshCullMode",
    "setFrontFaceWinding",
    "getFrontFaceWinding",
    "setWireframe",
    "isWireframe",
    "setShader",
    "getShader",
    "getSupported",
    "getTextureFormats",
    "getRendererInfo",
    "getSystemLimits",
    "getTextureTypes",
    "getStats",
    "captureScreenshot",
    "drawLayer",
    "drawInstanced",
    "drawIndirect",
    "drawFromShader",
    "drawFromShaderIndirect",
    "dispatchThreadgroups",
    "dispatchIndirect",
    "copyBuffer",
    "copyBufferToTexture",
    "copyTextureToBuffer",
    "isGammaCorrect",
    "getPixelWidth",
    "getPixelHeight",
    "getPixelDimensions",
    "getQuadIndexBuffer",
    "setScissor",
    "intersectScissor",
    "getScissor",
    "setStencilMode",
    "getStencilMode",
    "points",
    "line",
    "rectangle",
    "circle",
    "ellipse",
    "arc",
    "polygon",
    "flushBatch",
    "getStackDepth",
    "rotate",
    "scale",
    "translate",
    "shear",
    "applyTransform",
    "replaceTransform",
    "transformPoint",
    "inverseTransformPoint",
    "setOrthoProjection",
    "setPerspectiveProjection",
    "resetProjection",
    "getCanvasFormats",
    "getImageFormats",
    "isActive",
    "origin",
    "clear",
    "getBackgroundColor",
    "draw",
    "present",
    "isCreated",
    "stencil",
    "reset",
    "setFont",
    "setColor",
    "getDimensions",
    "print"
}

-- functions starting with "new" that are safe
local new_oks = {
    "newArrayImage",
    "newCanvas",
    "newMesh",
    "newParticleSystem",
    "newQuad",
    "newSpriteBatch",
    "newText",
    "newVolumeImage"
}


local function is_code(code) 
    --[[
        shader code will always have a newline.

        If it doesn't have a newline, then it's a filename.
    ]]
    return code:find("\n")
end


local function convert_first_arg_to_shadercode(lobj, func)
    
    return function(code, ...)
        if not is_code(code) then
            code = lobj.fsysObj:read(code, "string")
        end
        return func(code, ...)
    end
end


local shaders = {
    "newShader",
    "validateShader"
}



local conv_tc = tc.assert("table", "function")

local function convert_first_arg_to_imagedata(lobj, func)
    conv_tc(lobj, func)
    --[[
        we need to restrict the user so they can't load arbitrary
        files on the system.
        We do this by checking if the first arg is a string,
        and if so, mangle it.
    ]]
    return function(a,...)
        if type(a) == "string"  then
            -- its a filename, convert first arg to imagedata
            local path = a
            local filedata = lobj.fsysObj:newFileData(path)
            local image_data = love.image.newImageData(filedata)
            return func(image_data, ...)
        end

        return func(a,...) -- a is not a path, so OK.
    end
end


local first_arg_imagedata = {
    "newImage",
    "newImageFont",
    "newCubeImage"
}


return function(l)
    local graphics = {}
    --[[
    TODO:

    Need to implement 
        -   love.graphics.newVideo
            (needs love.video api)
        -   love.graphics.newFont
    ]]

    for _, key in ipairs(first_arg_imagedata) do
        local func = love.graphics[key]
        graphics[key] = convert_first_arg_to_imagedata(l, func)
    end

    for _, key in ipairs(shaders) do
        local func = love.graphics[key]
        graphics[key] = convert_first_arg_to_shadercode(l, func)
    end

    for _, key in ipairs(oks) do
        assert(love.graphics[key], "wot")
        graphics[key] = love.graphics[key]
    end

    for _, key in ipairs(new_oks) do
        if not love.graphics[key] then
            error("wot " .. key)
        end
        graphics[key] = love.graphics[key]
    end

    return graphics
end

