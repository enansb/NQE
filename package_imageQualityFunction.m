function quality = imageQualityFunction(imagePath, modelParamsPath)
    % 這個函數封裝了原始 example.m 中的所有功能
    % 參數:
    %   imagePath - 圖像文件的路徑 
    %   modelParamsPath - 模型參數文件的路徑，預設為 'modelparameters.mat'
    
    % 設置預設參數路徑（如果未提供）獲取函數被呼叫時傳入的參數數量
    if nargin < 2
        modelParamsPath = 'modelparameters.mat';
    end
    
    % 載入模型參數 是一個臨時變數，用來存儲這些數據。接著，程式碼從 params 中提取 mu_prisparam 和 cov_prisparam，用於後續的品質計算。
    params = load(modelParamsPath);
    
    % 確保變數名與你的模型參數文件一致
    mu_prisparam = params.mu_prisparam;
    cov_prisparam = params.cov_prisparam;
    
    % 設置區塊參數
    blocksizerow = 96;
    blocksizecol = 96;
    blockrowoverlap = 0;
    blockcoloverlap = 0;
    
    % 讀取圖像文件
    im = imread('C:\Users\peace\Downloads\images (2).jpg');
    
    % 計算品質
    quality = computequality(im, blocksizerow, blocksizecol, blockrowoverlap, blockcoloverlap, ...
                            mu_prisparam, cov_prisparam);
end