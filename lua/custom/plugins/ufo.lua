local function getFoldEndChar(line)
    -- 检查是否以开始标签结束
    local tagName = line:match("<(%w+)[^>]*>$")
    if tagName then
        -- 检查是否自闭合标签
        if line:match("/%s*>$") then
            return '' -- 自闭合标签没有闭合后缀
        else
            return ('</%s>'):format(tagName) -- 返回对应的闭合标签
        end
    end

    -- 对于非 HTML 标签，保持原有逻辑
    local endChars = { ['{'] = '}', ['('] = ')', ['['] = ']', ['<'] = '>' }
    local char = line:match("([%{%(%[%<])%s*$")
    return endChars[char] or ''
end

local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    local startLine = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
    local endChar = getFoldEndChar(startLine) or '...'
    local suffix = ('  %d %s'):format(endLnum - lnum, endChar)
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
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, { suffix, 'MoreMsg' })
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
