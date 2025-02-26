% cnn_script.m
% 假設這是你的 CNN 處理流程
imagePath = 'C:\Users\peace\Downloads\images (2).jpg'; % CNN 處理的圖像
modelParamsPath = 'modelparameters.mat'; % 模型參數路徑

% 在 CNN 處理後評估圖像品質
quality = package_imageQualityFunction(imagePath, modelParamsPath);
disp(['圖像品質分數: ', num2str(quality)]);