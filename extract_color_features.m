function features = extract_color_features(rgb_img, mask)
    r = double(rgb_img(:,:,1));
    g = double(rgb_img(:,:,2));
    b = double(rgb_img(:,:,3));

    r_masked = r(mask);
    g_masked = g(mask);
    b_masked = b(mask);

    mean_r = mean(r_masked);
    mean_g = mean(g_masked);
    mean_b = mean(b_masked);

    r_g_ratio = mean_r / max(mean_g, 1e-5);
    r_b_ratio = mean_r / max(mean_b, 1e-5);
    g_b_ratio = mean_g / max(mean_b, 1e-5);

    features.mean_r = mean_r;
    features.mean_g = mean_g;
    features.mean_b = mean_b;
    features.r_g_ratio = r_g_ratio;
    features.r_b_ratio = r_b_ratio;
    features.g_b_ratio = g_b_ratio;
end
