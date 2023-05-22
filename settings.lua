data:extend({

    
-- Display Chat Message?
	{
        type = "bool-setting",
        name = "WarpLCL-Chat-Message",
        setting_type = "runtime-global",
        default_value = true,
        order = "WarpLCL-aa"
    },
-- Chat Message Color
    {
        type = "color-setting",
        name = "WarpLCL-Chat-Color",
        setting_type = "runtime-global",
        default_value = {r=0.1, g=0.3, b=1, a=1},
        order = "WarpLCL-ab"
    },

-- Marker Text (can be blank)
{
    type = "string-setting",
    name = "WarpLCL-Marker-Text",
    setting_type = "runtime-global",
    default_value = "WarpLoot",
    allow_blank = true,
    order = "WarpLCL-ba"
},
-- Marker Chunk-Prescision Mode
{
    type = "bool-setting",
    name = "WarpLCL-Marker-ChunkMode",
    setting_type = "runtime-global",
    default_value = false,
    order = "WarpLCL-bb"

}

})



