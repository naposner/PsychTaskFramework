function drawRef(settings, referenceSide)
% Draws the stable reference value on screen *for this particular experiment*
%
% For custom use, this function needs to be re-written accordingly (or a
% function handle passed in its stead).

H = settings.device.screenDims(3);
W = settings.device.screenDims(4);

if referenceSide == 1
    refDims.x = 0.25 * W;
elseif referenceSide == 2
    refDims.x = 0.75 * W;
end
refDims.y = H/4;

ref = settings.game.levels.reference;
windowPtr = settings.device.windowPtr;

Screen('TextSize', settings.device.windowPtr, settings.objects.reference.fontSize);
[ txt, txtDims ] = textLookup(ref, settings.lookups.stakes.txt, ...
  windowPtr);
[ texture, textureDims ] = imgLookup(ref, settings.lookups.stakes.img, ...
  settings.textures);

DrawFormattedText(windowPtr, txt, refDims.x - txtDims(1)/2, refDims.y, ...
    settings.default.fontColor);
Screen('DrawTexture', windowPtr, texture, [], [refDims.x, refDims.y, ...
    refDims.x + textureDims(1), refDims.y + textureDims(2)]);
end
