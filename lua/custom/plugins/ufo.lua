local function is_tag(line)
    local trimmed_line = line:match('^%s*(.*)')
    if trimmed_line:match('^<%w+[^>]*>?') then
        return true
    else
        return false
    end
end

local function get_pair_string(lnum)
    local pair_string = 'default'
    local line = vim.fn.getline(lnum)
    local is_tag_value = is_tag(tostring(line))

    if is_tag_value then
        local tag_name = line:match('<(%w+)')
        if tag_name then
            pair_string = '</' .. tag_name .. '>'
        end
    else
        local lastChar = line:match("([%{%(%[%<])%s*$")
        if lastChar then
            local endChars = { ['{'] = '}', ['('] = ')', ['['] = ']', ['<'] = '>' }
            return endChars[lastChar] or '...'
        end
    end

    return pair_string
end




local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    local suffix = ('  %d ... '):format(endLnum - lnum)

    local pair_string = get_pair_string(lnum)

    local suffix_and_pair = suffix .. ' ' .. pair_string

    local sufWidth = vim.fn.strdisplaywidth(suffix)
    local targetWidth = width - sufWidth
    local curWidth = 0
    for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
        else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix_and_pair = suffix_and_pair .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, { suffix_and_pair, 'MoreMsg' })
    return newVirtText
end


return {
    'kevinhwang91/nvim-ufo',
    config = function()
        vim.o.foldcolumn = '1' -- '0' is not bad
        vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
        vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

        -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
        vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
        vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
        require('ufo').setup({
            provider_selector = function(bufnr, filetype, buftype)
                return { 'treesitter', 'indent' }
            end,
            fold_virt_text_handler = handler
        })
    end,
    dependencies = { 'kevinhwang91/promise-async' }
}
