function leaf_disease_detection_gui
fig = figure('Name', 'Leaf Disease Detection System', ...
             'NumberTitle', 'off', 'Position', [100, 100, 1000, 600], ...
             'MenuBar', 'none', 'ToolBar', 'none');

control_panel = uipanel(fig, 'Title', 'Controls', 'Position', [0.01, 0.01, 0.2, 0.98]);
image_panel = uipanel(fig, 'Title', 'Image View', 'Position', [0.22, 0.51, 0.38, 0.48]);
result_panel = uipanel(fig, 'Title', 'Results', 'Position', [0.22, 0.01, 0.38, 0.49]);
feature_panel = uipanel(fig, 'Title', 'Features', 'Position', [0.61, 0.01, 0.38, 0.98]);

orig_axes = axes('Parent', image_panel, 'Position', [0.05, 0.1, 0.4, 0.8]);
proc_axes = axes('Parent', image_panel, 'Position', [0.55, 0.1, 0.4, 0.8]);
result_axes = axes('Parent', result_panel, 'Position', [0.05, 0.1, 0.9, 0.8]);

feature_text = uicontrol('Parent', feature_panel, 'Style', 'text', ...
                         'Position', [20, 20, 340, 540], 'HorizontalAlignment', 'left');

load_btn = uicontrol(control_panel, 'Style', 'pushbutton', 'String', 'Load Image', ...
                     'Position', [20, 500, 160, 30], 'Callback', @loadImage);

process_btn = uicontrol(control_panel, 'Style', 'pushbutton', 'String', 'Process Image', ...
                        'Position', [20, 450, 160, 30], 'Callback', @processImage, 'Enable', 'off');

save_btn = uicontrol(control_panel, 'Style', 'pushbutton', 'String', 'Save Results', ...
                     'Position', [20, 400, 160, 30], 'Callback', @saveResults, 'Enable', 'off');

uicontrol(control_panel, 'Style', 'text', 'String', 'Detection Method:', ...
          'Position', [20, 350, 160, 20], 'HorizontalAlignment', 'left');

algo_dropdown = uicontrol(control_panel, 'Style', 'popupmenu', ...
                          'String', {'Color-based', 'Texture-based', 'Combined'}, ...
                          'Position', [20, 320, 160, 30]);

data = struct();

    function loadImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp;*.tif'}, 'Select a leaf image');
        if filename == 0, return; end
        data.img = imread(fullfile(pathname, filename));
        axes(orig_axes); imshow(data.img); title('Original Image');
        set(process_btn, 'Enable', 'on');
    end

    function processImage(~, ~)
        if ~isfield(data, 'img'), return; end
        algo_idx = get(algo_dropdown, 'Value');

        if size(data.img, 3) == 3
            data.gray_img = rgb2gray(data.img);
        else
            data.gray_img = data.img;
        end

        data.enhanced_img = imadjust(data.gray_img);
        level = graythresh(data.enhanced_img);
        data.binary_img = imbinarize(data.enhanced_img, level);
        data.binary_img = bwareaopen(data.binary_img, 50);
        data.binary_img = imfill(data.binary_img, 'holes');

        switch algo_idx
            case 1
                green_channel = data.img(:,:,2);
                green_thresh = green_channel < 150;
                data.diseased_regions = green_thresh & data.binary_img;
                data.diseased_regions = bwareaopen(data.diseased_regions, 30);
            case 2
                entropy_img = entropyfilt(data.gray_img);
                entropy_thresh = entropy_img > 4.5;
                data.diseased_regions = entropy_thresh & data.binary_img;
                data.diseased_regions = bwareaopen(data.diseased_regions, 30);
            case 3
                green_channel = data.img(:,:,2);
                green_thresh = green_channel < 150;
                entropy_img = entropyfilt(data.gray_img);
                entropy_thresh = entropy_img > 4.5;
                data.diseased_regions = (green_thresh | entropy_thresh) & data.binary_img;
                data.diseased_regions = bwareaopen(data.diseased_regions, 30);
        end

        data.leaf_area = sum(data.binary_img(:));
        data.diseased_area = sum(data.diseased_regions(:));
        data.disease_percentage = (data.diseased_area / data.leaf_area) * 100;

        axes(proc_axes); imshow(data.binary_img); title('Segmented Leaf');

        if size(data.img, 3) == 3
            data.overlay_img = data.img;
            for i = 1:3
                channel = data.overlay_img(:,:,i);
                if i == 1
                    channel(data.diseased_regions) = 255;
                else
                    channel(data.diseased_regions) = 0;
                end
                data.overlay_img(:,:,i) = channel;
            end
        else
            data.overlay_img = data.gray_img;
            data.overlay_img(data.diseased_regions) = 255;
        end

        axes(result_axes);
        imshow(data.overlay_img);
        title(sprintf('Disease Detection (%.2f%% affected)', data.disease_percentage));

        if size(data.img, 3) == 3
            data.color_features = extract_color_features(data.img, data.binary_img);
        end
        data.texture_features = extract_texture_features(data.gray_img, data.binary_img);

        if data.disease_percentage < 5
            data.disease_status = 'Healthy';
        elseif data.disease_percentage < 15
            data.disease_status = 'Mild Infection';
        elseif data.disease_percentage < 30
            data.disease_status = 'Moderate Infection';
        else
            data.disease_status = 'Severe Infection';
        end

        feature_str = sprintf('Disease Status: %s\n\n', data.disease_status);
        feature_str = [feature_str, sprintf('Disease Severity: %.2f%%\n\n', data.disease_percentage)];

        if isfield(data, 'color_features')
            f = data.color_features;
            feature_str = [feature_str, 'Color Features:\n'];
            feature_str = [feature_str, sprintf('Mean RGB: [%.2f, %.2f, %.2f]\n', f.mean_r, f.mean_g, f.mean_b)];
            feature_str = [feature_str, sprintf('RGB Ratios: [R/G: %.2f, R/B: %.2f, G/B: %.2f]\n', ...
                f.r_g_ratio, f.r_b_ratio, f.g_b_ratio)];
        end

        t = data.texture_features;
        feature_str = [feature_str, sprintf('\nTexture Features:\n')];
        feature_str = [feature_str, sprintf('GLCM Contrast: %.4f\n', t.contrast)];
        feature_str = [feature_str, sprintf('GLCM Energy: %.4f\n', t.energy)];
        feature_str = [feature_str, sprintf('GLCM Homogeneity: %.4f\n', t.homogeneity)];
        feature_str = [feature_str, sprintf('LBP Entropy: %.4f\n', t.lbp_entropy)];

        set(feature_text, 'String', feature_str);
        set(save_btn, 'Enable', 'on');
    end

    function saveResults(~, ~)
        if ~isfield(data, 'overlay_img') || ~isfield(data, 'disease_status'), return; end
        [filename, pathname] = uiputfile({'*.png','PNG Image'; '*.jpg','JPEG Image'}, 'Save Image');
        if filename == 0, return; end
        imwrite(data.overlay_img, fullfile(pathname, filename));

        [~, name, ~] = fileparts(filename);
        fid = fopen(fullfile(pathname, [name '_report.txt']), 'w');
        fprintf(fid, 'Disease Status: %s\n', data.disease_status);
        fprintf(fid, 'Severity: %.2f%%\n\n', data.disease_percentage);

        if isfield(data, 'color_features')
            c = data.color_features;
            fprintf(fid, 'Color Features:\nMean RGB: [%.2f, %.2f, %.2f]\n', c.mean_r, c.mean_g, c.mean_b);
            fprintf(fid, 'Ratios [R/G: %.2f, R/B: %.2f, G/B: %.2f]\n\n', c.r_g_ratio, c.r_b_ratio, c.g_b_ratio);
        end

        t = data.texture_features;
        fprintf(fid, 'Texture Features:\nGLCM Contrast: %.4f\nEnergy: %.4f\nHomogeneity: %.4f\nLBP Entropy: %.4f\n', ...
            t.contrast, t.energy, t.homogeneity, t.lbp_entropy);
        fclose(fid);

        msgbox(sprintf('Saved to:\n%s', fullfile(pathname, filename)), 'Save Complete');
    end
end
