% Run as:
% yourDataName = HagfishBurrowing_ManualTrace()
% Need the Image Processing Toolbox for getrect()
% Recomend Signal Processing toolbox for post-processing midlines

function dataStruct = HagfishBurrowing_ManualTrace()

dataStruct = struct; % create a structure and give it the name provided by user

% ask user to open the video they want to digitize
[dataStruct.videoName, dataStruct.videoPath] = uigetfile('*.*', ...
    'Select the video you want to binarize');

% get some of the video properties
vidName = VideoReader(dataStruct.videoName);
FrNum = vidName.NumFrames;
dataStruct.VidFormat = vidName.VideoFormat;

% ask user for input regarding what chunks of the video they want to
% analyze along with some otehr metadata about saving
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

% create arays to store midlines
Lines(1).Frame = [];
Lines(1).MidLine = [];

% calculate funcitonal frame rate based on how many frames the user wants
% to skip while digitizing
FrRate = dataStruct.originalFrameRate/skipRate;

ImStart = read(vidName,1); % read in first frame of the video

% Get a rectangle to limit search area to area the ctritter is swimming in
disp("Crop vieo to zoom in on the critter.")
rect = CropVideo(ImStart);
dataStruct.rect = rect;
count = 0;

% loop though the frames that the user wants to digitize
for Index = startFrame:skipRate:endFrame
    RawImage = read(vidName,Index); % get the first image to allow user to click the fish
    RawImage = imcrop(RawImage, rect); % crop the image according to the input from above
    h = figure(1);
    
    % if we are not on the first frame, position the figure window the same
    % as the previous frames
    if count == 0
    else
        set(h, 'Position', figProps.Position, 'OuterPosition', ...
            figProps.OuterPosition, 'InnerPosition', figProps.InnerPosition)
    end
    
    % Display the frame to be digitized
    imshow(RawImage);
    title(['Frame ',num2str(Index),' out of ',num2str(endFrame)])
    disp("Click along the fish. Be sure to get the nose and tail")
    disp("Click 'Enter' when done")
    hold on;
    forever = 1;
    X=[]; Y=[];
    
    % have the user click points along the fish and press "enter" when they
    % are done
    while forever
        [x, y] = ginput(1);  % get the location of the fish
        plot(x,y,'ob'); % show the dot the user clicked
        X = [X;x]; Y = [Y;y]; % save each point
        drawnow
        isKeyPressed = ~isempty(get(h,'CurrentCharacter'));
        if isKeyPressed
            break
        end
    end
    
    Lines(Index).Frame=Index;       % save data in the output structure
    Lines(Index).MidLine=[X, Y];
    
    % if we are on the first frame, save the position and size of the
    % figure window set by the user
    if count == 0
        figProps = get(h);
    else
    end
    
    close all
    count = count+1;
end

% save the medatata and midlines in the structre fle
digitizedFrames = startFrame:skipRate:endFrame;
dataStruct.digizedFrames = digitizedFrames;
dataStruct.midlines = Lines(digitizedFrames);

figure
title("Raw Clicked Points")
hold on

% loop through the digitized frames plotting the raw data and using it to
% generate a new array of 21 equally distributed points along the body
nfr = size(dataStruct.midlines,2);
x = []; y = [];
for i = 1:nfr
    xPts = dataStruct.midlines(i).MidLine(:,1);
    yPts = -dataStruct.midlines(i).MidLine(:,2);
    plot(xPts, yPts)
    % Old smoothing functions. Need Signal Processing toolbox
%     xPts = sgolayfilt(dataStruct.midlines(i).MidLine(:,1), 2, 13);
%     yPts = sgolayfilt(-dataStruct.midlines(i).MidLine(:,2), 2, 13);
    randPts = rand(1,length(xPts))/1000; xPts = xPts+randPts';
    % Generate equation if the midline
    [pts, deriv, funct] = interparc(21, xPts, yPts, 'spline');
    % add those points to an array
    x = [x,pts(:,1)]; y = [y,pts(:,2)];
end
axis equal

% save the equally distrubuted points in teh structre file
dataStruct.X = x; dataStruct.Y = y;

% Plot the newly re-sampled points on a second figure to compare
figure
title("Sampled 21 equal Points")
plot(x,y)
hold on
p1 = plot(x(end,:), y(end,:), 'b', 'LineWidth',2);
    cd = [uint8(parula(size(x,2))*255) uint8(ones(size(x,2),1))].';
    drawnow
    set(p1.Edge,'ColorBinding','interpolated', 'ColorData',cd)
p2 = plot(x(1,:), y(1,:), 'k', 'LineWidth',2);
    cd = [uint8(parula(size(x,2))*255) uint8(ones(size(x,2),1))].';
    drawnow
    set(p2.Edge,'ColorBinding','interpolated', 'ColorData',cd)
axis equal

% save the structure file
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