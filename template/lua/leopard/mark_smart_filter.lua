-- mark_phrase_filter.lua
-- encoding: utf-8
-- CC-BY-4.0

local function filter(input, env)
    for cand in input:iter() do
        -- 检查是否是 smart 翻译器的候选
        if (cand.type == "sentence") then
            -- 在注释后添加闪电图标
            cand.comment = (cand.comment or "") .. "⚡"
        elseif (cand.type == "user_phrase") then
            cand.comment = (cand.comment or "") .. "🌟"
        end
        yield(cand)
    end
end

return filter