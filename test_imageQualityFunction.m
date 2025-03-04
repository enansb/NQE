%跟function3.m憶起使用
function quality = imageQualityFunction(imagePath, modelParamsPath)
    % 這個函數封裝了原始 example.m 中的所有功能，並將分數正規化到0-100範圍
    % 參數:
    % imagePath - 圖像文件的路徑
    % modelParamsPath - 模型參數文件的路徑，預設為 'modelparameters.mat'
    % 返回:
    % quality - 正規化後的圖像品質分數 (0-100，分數越低表示品質越好)
    
    % 設置預設參數路徑（如果未提供）
    if nargin < 2
        modelParamsPath = 'modelparameters.mat';
    end
    
    % 載入模型參數
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
    try
        % 嘗試使用提供的圖像路徑
        im = imread("C:\Users\peace\Downloads\test-image\Noisy\ILSVRC2012_val_00002993.JPEG");
    catch
        % 如果提供的路徑無效，使用預設路徑
        warning('無法讀取提供的圖像路徑，使用預設路徑。');
        im = imread("");
    end
    
    % 計算原始品質分數
    rawQuality = computequality(im, blocksizerow, blocksizecol, blockrowoverlap, blockcoloverlap, ...
        mu_prisparam, cov_prisparam);
    
    % 正規化品質分數到0-100範圍
    % 注意：這裡我們假設原始分數是一個距離指標，較大值表示較差品質
    % 我們將使用反向映射使較低的值表示較好的品質
    
    % 基於經驗值設定預期的最小和最大原始分數範圍
    % 您可能需要根據實際數據調整這些值
    minExpectedRawScore = 0;    % 預期的最佳原始分數
    maxExpectedRawScore = 30;   % 預期的最差原始分數
    
    % 將原始分數限制在預期範圍內
    clampedRawQuality = max(minExpectedRawScore, min(rawQuality, maxExpectedRawScore));
    
    % 計算正規化分數 (0-100，較低值表示較好品質)
    % 這裡我們使用線性映射將範圍從[minExpected, maxExpected]映射到[0, 100]
    normalizedQuality = ((clampedRawQuality - minExpectedRawScore) / ...
        (maxExpectedRawScore - minExpectedRawScore)) * 100;
    
    % 輸出診斷信息（可選，可以移除）
    fprintf('原始品質分數: %.4f\n', rawQuality);
    fprintf('正規化品質分數 (0-100): %.2f\n', normalizedQuality);
    
    % 返回正規化的品質分數
    quality = normalizedQuality;
end
