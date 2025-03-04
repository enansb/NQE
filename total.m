% 在檔案頂部直接指定圖片資料夾路徑
folderPath = 'C:\Users\peace\Downloads\test-image\2Noisy';  % 替換為你實際的圖片資料夾路徑
outputPath = 'image_quality_results';  % 輸出檔案名稱
modelParamsPath = 'modelparameters.mat';  % 模型參數檔案路徑

function processImageFolder(folderPath, outputPath, modelParamsPath)
    % processImageFolder - 評估整個資料夾內所有圖片的品質並儲存結果
    %
    % 參數:
    %   folderPath - 包含要處理的圖像文件的資料夾路徑
    %   outputPath - 輸出檔案的路徑（不含副檔名，會自動加上）
    %   modelParamsPath - 模型參數文件的路徑，預設為 'modelparameters.mat'
    %
    % 功能:
    %   1. 處理資料夾中的所有圖像文件
    %   2. 計算每個圖像的品質分數並正規化到0-100範圍
    %   3. 將結果保存到Excel和CSV文件中
    %   4. 提供處理進度和統計信息
    %   5. 支援將新資料追加到現有檔案
    
    % 設置預設參數路徑（如果未提供）
    if nargin < 3
        modelParamsPath = 'modelparameters.mat';
    end
    
    % 設置預設輸出路徑（如果未提供）
    if nargin < 2
        outputPath = 'image_quality_results';
    end
    
    % 顯示開始信息
    fprintf('開始處理資料夾: %s\n', folderPath);
    fprintf('使用模型參數: %s\n', modelParamsPath);
    fprintf('結果將保存到: %s.xlsx 和 %s.csv\n', outputPath, outputPath);
    
    % 載入模型參數
    try
        params = load(modelParamsPath);
        
        % 確保變數名與模型參數文件一致
        mu_prisparam = params.mu_prisparam;
        cov_prisparam = params.cov_prisparam;
        
        fprintf('成功載入模型參數\n');
    catch ME
        error('載入模型參數時出錯: %s', ME.message);
    end
    
    % 設置區塊參數
    blocksizerow = 96;
    blocksizecol = 96;
    blockrowoverlap = 0;
    blockcoloverlap = 0;
    
    % 搜尋所有可能的圖像檔案，不區分大小寫
    allFiles = dir(fullfile(folderPath, '*.*'));
    imageFiles = [];
    
    % 支援的圖像格式（基本副檔名，不含點）
    validExtensions = {'jpg', 'jpeg', 'png', 'bmp', 'tif', 'tiff'};
    
    % 過濾出圖像檔案
    for i = 1:length(allFiles)
        if allFiles(i).isdir
            continue; % 跳過資料夾
        end
        
        [~, ~, fileExt] = fileparts(allFiles(i).name);
        if isempty(fileExt)
            continue; % 跳過沒有副檔名的檔案
        end
        
        % 移除副檔名開頭的點並轉換為小寫進行比較
        fileExt = lower(fileExt(2:end));
        
        if ismember(fileExt, validExtensions)
            imageFiles = [imageFiles; allFiles(i)];
        end
    end
    
    % 如果沒有找到圖像文件，發出錯誤
    if isempty(imageFiles)
        error('在資料夾 %s 中沒有找到支持的圖像文件', folderPath);
    end
    
    % 計算找到的圖像文件數量
    numImages = length(imageFiles);
    fprintf('找到 %d 個圖像文件\n', numImages);
    
    % 創建保存結果的表格
    results = table('Size', [numImages, 5], ...
                    'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
                    'VariableNames', {'Folder', 'ImageName', 'RawScore', 'ClampedScore', 'NormalizedScore'});
    
    % 設定預期的原始分數範圍
    minExpectedRawScore = 0;  % 預期的最佳原始分數
    maxExpectedRawScore = 30; % 預期的最差原始分數
    
    % 創建計時器來估計剩餘時間
    totalStartTime = tic;
    
    % 處理每個圖像文件
    for i = 1:numImages
        % 獲取當前圖像的完整路徑
        currentImageFile = imageFiles(i);
        currentImagePath = fullfile(currentImageFile.folder, currentImageFile.name);
        
        % 開始處理當前圖像
        fprintf('[%d/%d] 處理圖像: %s\n', i, numImages, currentImageFile.name);
        imageStartTime = tic;
        
        try
            % 讀取圖像
            im = imread(currentImagePath);
            
            % 計算原始品質分數
            rawQuality = computequality(im, blocksizerow, blocksizecol, blockrowoverlap, ...
                                       blockcoloverlap, mu_prisparam, cov_prisparam);
            
            % 將原始分數限制在預期範圍內
            clampedRawQuality = max(minExpectedRawScore, min(rawQuality, maxExpectedRawScore));
            
            % 計算正規化分數 (0-100，較低值表示較好品質)
            normalizedQuality = ((clampedRawQuality - minExpectedRawScore) / ...
                                (maxExpectedRawScore - minExpectedRawScore)) * 100;
            
            % 記錄結果
            results.Folder(i) = string(folderPath);
            results.ImageName(i) = string(currentImageFile.name);
            results.RawScore(i) = rawQuality;
            results.ClampedScore(i) = clampedRawQuality;
            results.NormalizedScore(i) = normalizedQuality;
            
            % 顯示處理時間和結果
            processingTime = toc(imageStartTime);
            fprintf('  完成: 原始分數 = %.4f, 正規化分數 = %.2f (處理時間: %.2f 秒)\n', ...
                   rawQuality, normalizedQuality, processingTime);
            
            % 如果不是第一張圖像，估計剩餘時間
            if i > 1
                elapsedTime = toc(totalStartTime);
                estimatedTotalTime = elapsedTime / i * numImages;
                remainingTime = estimatedTotalTime - elapsedTime;
                
                % 格式化剩餘時間
                if remainingTime < 60
                    timeStr = sprintf('%.1f 秒', remainingTime);
                elseif remainingTime < 3600
                    timeStr = sprintf('%.1f 分鐘', remainingTime / 60);
                else
                    timeStr = sprintf('%.1f 小時', remainingTime / 3600);
                end
                
                fprintf('  估計剩餘時間: %s\n', timeStr);
            end
            
        catch ME
            % 記錄處理錯誤
            warning('處理圖像 %s 時出錯: %s', currentImageFile.name, ME.message);
            
            % 記錄錯誤結果
            results.Folder(i) = string(folderPath);
            results.ImageName(i) = string(currentImageFile.name);
            results.RawScore(i) = NaN;
            results.ClampedScore(i) = NaN;
            results.NormalizedScore(i) = NaN;
        end
    end
    
    % 計算處理的總時間
    totalTime = toc(totalStartTime);
    if totalTime < 60
        timeStr = sprintf('%.1f 秒', totalTime);
    elseif totalTime < 3600
        timeStr = sprintf('%.1f 分鐘', totalTime / 60);
    else
        timeStr = sprintf('%.1f 小時', totalTime / 3600);
    end
    
    % 計算成功處理的圖像數量和百分比
    validResults = ~isnan(results.RawScore);
    numValidResults = sum(validResults);
    validPercentage = numValidResults / numImages * 100;
    
    % 計算統計信息
    if numValidResults > 0
        avgRawScore = mean(results.RawScore(validResults));
        minRawScore = min(results.RawScore(validResults));
        maxRawScore = max(results.RawScore(validResults));
        
        avgNormScore = mean(results.NormalizedScore(validResults));
        minNormScore = min(results.NormalizedScore(validResults));
        maxNormScore = max(results.NormalizedScore(validResults));
    else
        avgRawScore = NaN;
        minRawScore = NaN;
        maxRawScore = NaN;
        
        avgNormScore = NaN;
        minNormScore = NaN;
        maxNormScore = NaN;
    end
    
    % 顯示處理完成信息和統計數據
    fprintf('\n處理完成! 總時間: %s\n', timeStr);
    fprintf('成功處理 %d/%d 圖像 (%.1f%%)\n', numValidResults, numImages, validPercentage);
    fprintf('\n統計信息:\n');
    fprintf('原始分數 - 平均: %.4f, 最小: %.4f, 最大: %.4f\n', ...
           avgRawScore, minRawScore, maxRawScore);
    fprintf('正規化分數 - 平均: %.2f, 最小: %.2f, 最大: %.2f\n', ...
           avgNormScore, minNormScore, maxNormScore);
    
    % 保存結果到Excel文件
    try
        excelPath = [outputPath '.xlsx'];
        newSummaryData = {'處理日期時間', datestr(now, 'yyyy-mm-dd HH:MM:SS');
                          '資料夾路徑', folderPath;
                          '處理的圖像總數', numImages;
                          '成功處理的圖像數', numValidResults;
                          '成功百分比', validPercentage;
                          '處理總時間 (秒)', totalTime;
                          '模型參數路徑', modelParamsPath;
                          '正規化範圍 - 最小', minExpectedRawScore;
                          '正規化範圍 - 最大', maxExpectedRawScore};
        
        % 檢查Excel文件是否已存在
        if exist(excelPath, 'file')
            fprintf('檢測到現有Excel文件，將追加新結果...\n');
            
            % 讀取現有數據
            try
                existingData = readtable(excelPath, 'Sheet', '品質分數');
                
                % 合併舊數據和新數據
                combinedResults = [existingData; results];
                
                % 將合併結果寫入Excel
                writetable(combinedResults, excelPath, 'Sheet', '品質分數', 'WriteMode', 'overwrite');
                
                % 更新摘要工作表
                try
                    % 嘗試讀取現有的摘要數據
                    existingSummary = readtable(excelPath, 'Sheet', '摘要');
                    
                    % 將新處理的資料夾信息添加到摘要中
                    newSummaryTable = cell2table(newSummaryData, 'VariableNames', {'指標', '值'});
                    
                    % 檢查摘要表是否為空
                    if ~isempty(existingSummary)
                        % 加入分隔符號
                        separator = {'---', ['批次 ' datestr(now, 'yyyymmdd-HHMMSS')]};
                        separatorTable = cell2table(separator, 'VariableNames', {'指標', '值'});
                        
                        % 合併摘要表
                        combinedSummary = [existingSummary; separatorTable; newSummaryTable];
                    else
                        combinedSummary = newSummaryTable;
                    end
                    
                    % 寫入更新後的摘要
                    writetable(combinedSummary, excelPath, 'Sheet', '摘要', 'WriteMode', 'overwrite');
                    
                catch
                    % 如果讀取摘要表失敗，創建新的摘要表
                    newSummaryTable = cell2table(newSummaryData, 'VariableNames', {'指標', '值'});
                    writetable(newSummaryTable, excelPath, 'Sheet', '摘要', 'WriteMode', 'overwrite');
                end
                
                fprintf('結果已追加到現有Excel文件: %s\n', excelPath);
            catch ME
                warning('讀取或更新現有Excel文件時出錯: %s', ME.message);
                warning('將創建新文件...');
                
                % 如果讀取或更新失敗，創建新文件
                writetable(results, excelPath, 'Sheet', '品質分數');
                newSummaryTable = cell2table(newSummaryData, 'VariableNames', {'指標', '值'});
                writetable(newSummaryTable, excelPath, 'Sheet', '摘要', 'WriteMode', 'overwrite');
            end
        else
            % 如果文件不存在，創建新文件
            writetable(results, excelPath, 'Sheet', '品質分數');
            newSummaryTable = cell2table(newSummaryData, 'VariableNames', {'指標', '值'});
            writetable(newSummaryTable, excelPath, 'Sheet', '摘要', 'WriteMode', 'overwrite');
            
            fprintf('結果已保存到新Excel文件: %s\n', excelPath);
        end
    catch ME
        warning('保存Excel文件時出錯: %s', ME.message);
        
        % 嘗試使用替代文件名
        try
            altExcelPath = [outputPath '_' datestr(now, 'yyyymmdd_HHMMSS') '.xlsx'];
            writetable(results, altExcelPath, 'Sheet', '品質分數');
            newSummaryTable = cell2table(newSummaryData, 'VariableNames', {'指標', '值'});
            writetable(newSummaryTable, altExcelPath, 'Sheet', '摘要', 'WriteMode', 'overwrite');
            fprintf('結果已保存到替代Excel文件: %s\n', altExcelPath);
        catch
            warning('無法保存Excel文件');
        end
    end
    
    % 保存結果到CSV文件
    try
        csvPath = [outputPath '.csv'];
        
        % 檢查CSV文件是否已存在
        if exist(csvPath, 'file')
            fprintf('檢測到現有CSV文件，將追加新結果...\n');
            
            try
                % 讀取現有CSV數據
                existingData = readtable(csvPath);
                
                % 合併舊數據和新數據
                combinedResults = [existingData; results];
                
                % 將合併結果寫入CSV
                writetable(combinedResults, csvPath);
                fprintf('結果已追加到現有CSV文件: %s\n', csvPath);
            catch ME
                warning('讀取或更新現有CSV文件時出錯: %s', ME.message);
                warning('將創建新文件...');
                
                % 如果讀取或更新失敗，創建新文件
                writetable(results, csvPath);
            end
        else
            % 如果文件不存在，創建新文件
            writetable(results, csvPath);
            fprintf('結果已保存到新CSV文件: %s\n', csvPath);
        end
    catch ME
        warning('保存CSV文件時出錯: %s', ME.message);
        
        % 嘗試使用替代文件名
        try
            altCsvPath = [outputPath '_' datestr(now, 'yyyymmdd_HHMMSS') '.csv'];
            writetable(results, altCsvPath);
            fprintf('結果已保存到替代CSV文件: %s\n', altCsvPath);
        catch
            warning('無法保存CSV文件');
        end
    end
end

% 確保保留 computequality 函數的原有功能

function quality = imageQualityFunction(imagePath, modelParamsPath)
    % 這個函數封裝了計算單張圖像品質分數的功能
    % (函數內容保持不變)
end

% 在檔案最後加入這一行來直接執行處理
processImageFolder(folderPath, outputPath, modelParamsPath);