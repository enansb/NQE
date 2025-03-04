folderPath = 'C:\Users\peace\Downloads\test-image';
outputFolder = fullfile(folderPath, '2Noisy'); % 儲存雜訊圖片的資料夾
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

imageFiles = dir(fullfile(folderPath, '*.jpeg')); % 可改為 *.jpg, *.bmp, *.tif 等格式

for i = 1:length(imageFiles)
    % 讀取圖片
    imgPath = fullfile(folderPath, imageFiles(i).name);
    img = imread(imgPath);

    % 添加高斯雜訊 (均值=0，標準差=0.02，可調整)
    noisyImg = imnoise(img, 'gaussian', 0, 0.02);

    % 儲存處理後的圖片
    outputPath = fullfile(outputFolder, imageFiles(i).name);
    imwrite(noisyImg, outputPath);
end

disp('所有圖片已成功加入高斯雜訊並儲存。');
