function features = extract_texture_features(gray_img, mask)
    gray_img = double(gray_img);
    gray_masked = gray_img;
    gray_masked(~mask) = 0;

    glcm = graycomatrix(uint8(gray_masked), 'Offset', [0 1]);
    stats = graycoprops(glcm, {'Contrast', 'Energy', 'Homogeneity'});

    lbp = extractLBPFeatures(uint8(gray_masked), 'Upright', false);
    lbp_entropy = entropy(double(lbp));

    features.contrast = stats.Contrast;
    features.energy = stats.Energy;
    features.homogeneity = stats.Homogeneity;
    features.lbp_entropy = lbp_entropy;
end
