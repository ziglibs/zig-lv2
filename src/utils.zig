const c = @import("c.zig");

pub const Feature = struct {
    uri: []const u8,
    required: bool = false
};

pub fn queryMissingFeature(features: []const c.LV2_Feature, feature_list: []const Feature) ?Feature {
    // TODO: Reimplement lv2_features_data in Zig
    for (feature_list) |feat| {
        var b = c.lv2_features_data(
            @ptrCast([*c]const [*c]const c.LV2_Feature, features)
        , @ptrCast([*c]const u8, feat.uri));
        if (feat.required and !@ptrCast(*bool, b).*) return feat;
    }
    
    return null;
}
