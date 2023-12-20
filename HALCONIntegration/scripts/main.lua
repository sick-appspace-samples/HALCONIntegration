
--Start of Global Scope---------------------------------------------------------

print('AppEngine Version: ' .. Engine.getVersion())

-- Creating and configuring directory image provider
local cam = Image.Provider.Directory.create()
cam:setPath('resources/')
cam:setCycleTime(1000)

-- Creating a viewer instance to see the result in an Image View
local viewer = View.create()

local sDecoration = View.ShapeDecoration.create():setLineColor(255, 0, 0) -- RED

local textDecoration = View.TextDecoration.create():setPosition(10, 10):setSize(4)

local hdevBinarizer = Halcon.create()

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---Declaration of the 'main' function as an entry point for the event loop
local function main()
  -- Loading the HALCON Binarize Procedure and when successful, starting providing images
  if hdevBinarizer:loadProcedure('resources/Binarize.hdvp') then
    -- Starting the image provider
    cam:start()
  end
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

---This function binarizes the Image by using an HALCON script
---The binarized image is returned as well as the counted pixels
---@param img Image
---@return Image
---@return float[]
local function binarizeImage(img)
  -- set the image and control input parameters of the HALCON function Binarize.hdvp
  hdevBinarizer:setImage('InputImage', img)
  hdevBinarizer:setInteger('GrayLevel', 230)

  -- execute the loaded function
  local result = hdevBinarizer:execute()

  -- obtain the results
  local binImage = result:getImage('OutputImage')
  local countedPixels = result:getDoubleArray('PixelCount')

  return binImage, countedPixels
end

---This callback is called for every new image
---@param img Image
local function handleNewImage(img)
  viewer:clear()
  print('handleNewImage')
  local tic = DateTime.getTimestamp()
  -- Here the binarization function is called
  local binarizedImage,
    countedPixels = binarizeImage(img)
  if (countedPixels) then
    local toc = DateTime.getTimestamp()
    local outString =
          'Proc. time: ' ..
          toc - tic ..
          ' ms; Black Pix: ' ..
          countedPixels[1] .. '; White Pix: ' .. countedPixels[2]

    -- finally display the data
    -- Print the processing time and the results into the view
    viewer:addImage(binarizedImage)
    viewer:addText(outString, textDecoration)
    viewer:present()

    print(outString)
  else
    viewer:addImage(img, sDecoration)
    viewer:addText('No image processing running', textDecoration)
    viewer:present()
  end
end
cam:register('OnNewImage', handleNewImage)

--End of Function and Event Scope------------------------------------------------
