const c = @import("c.zig");

pub const Feature = struct {
    uri: []const u8,
    required: bool = false
};

pub fn queryMissingFeature(features: []const c.LV2_Feature, feature_list: []Feature) ?Feature {
    for (feature_list) |feat| {
        if (feat.required and c.lv2_features_data(features, uri)) return feat;
    }
    
    return null;
}
