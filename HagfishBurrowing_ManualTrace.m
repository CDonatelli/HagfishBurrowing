function dataStruct = HagfishBurrowing_ManualTrace()

dataStruct = struct;
[dataStruct.videoName, dataStruct.videoPath] = uigetfile('*.*', ...
    'Select the video you want to binarize');

vidName = VideoReader(dataStruct.videoName);
FrNum = vidName.NumFrames;
dataStruct.VidFormat = vidName.VideoFormat;

prompt = {'Enter start frame:','Enter end frame:', 'Enter Video Frame Rate:',...
    'Enter skip rate:', 'Enter save name:'};
dlgtitle = 'What do you want to digitize?';
dims = [1 85];
definput = {'1',num2str(FrNum),num2str(vidName.FrameRate),'1','outputName'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
startFrame = str2num(answer{1});
endFrame = str2num(answer{2});
dataStruct.originalFrameRate = str2num(answer{3});
skipRate = str2num(answer{4});
saveName = answer{5};
dataStruct.endFrame = endFrame;
dataStruct.skipRate = skipRate;

Lines(1).Frame = [];
Lines(1).MidLine = [];

FrRate = dataStruct.originalFrameRate/skipRate;

ImStart = read(vidName,1);

% Get a rectangle to limit search area to area the fish is swimming in
disp("Crop vieo to zoom in on the critter.")
rect = CropVideo(ImStart);
dataStruct.rect = rect;

for Index = startFrame:skipRate:endFrame
    RawImage = read(vidName,Index);%get the first image to allow user to click the fish
    RawImage = imcrop(RawImage, rect);
    h = figure(1);
    imshow(RawImage);
    title(['Frame ',num2str(Index),' out of ',num2str(endFrame)])
    disp("Click along the fish. Be sure to get the nose and tail")
    hold on;
    forever = 1;
    X=[]; Y=[];
    while forever
        [x, y] = ginput(1);  %get the location of the fish
        plot(x,y,'ob'); %show the dot the user clicked
        X = [X;x]; Y = [Y;y];
        drawnow
        isKeyPressed = ~isempty(get(h,'CurrentCharacter'));
        if isKeyPressed
            break
        end
    end
    
    Lines(Index).Frame=Index;       %save data in the output structure
    Lines(Index).MidLine=[X, Y];
    hold off    %allow the image to be redrawn
    close all
end

digitizedFrames = startFrame:skipRate:endFrame;
dataStruct.digizedFrames = digitizedFrames;
dataStruct.midlines = Lines(digitizedFrames);

nfr = size(dataStruct.midlines,2);
x = []; y = [];
for i = 1:nfr
    xPts = sgolayfilt(smooth(dataStruct.midlines(i).MidLine(:,1)), 2, 13);
    yPts = sgolayfilt(smooth(-dataStruct.midlines(i).MidLine(:,2)), 2, 13);
    randPts = rand(1,length(xPts))/1000; xPts = xPts+randPts';
    % Generate equation if the midline
    [pts, deriv, funct] = interparc(21, xPts, yPts, 'spline');
    % add those points to an array
    x = [x,pts(:,1)]; y = [y,pts(:,2)];
end
dataStruct.X = x; dataStruct.Y = y;

close all   %close the image
figure
plot(x,y)
hold on
p1 = plot(x(end,:), y(end,:), 'b', 'LineWidth',2);
    cd = [uint8(parula(length(x))*255) uint8(ones(length(x),1))].';
    drawnow
    set(p1.Edge,'ColorBinding','interpolated', 'ColorData',cd)
p2 = plot(x(1,:), y(1,:), 'k', 'LineWidth',2);
    cd = [uint8(parula(length(x))*255) uint8(ones(length(x),1))].';
    drawnow
    set(p2.Edge,'ColorBinding','interpolated', 'ColorData',cd)
axis equal

dataStruct.midLines = Lines(digitizedFrames);
eval([saveName, '= dataStruct'])
save(saveName, saveName);

function rect = CropVideo(im)
disp('Select the portion of the frame the fish swims through');
choice = 0;
while choice == 0
    imshow(im)
    rect = getrect;
    im2 = imcrop(im,rect);
    imshow(im2)
    choice = input('Does this look right? :');
end