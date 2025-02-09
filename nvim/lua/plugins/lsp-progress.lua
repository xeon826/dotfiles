return {
  "linrongbin16/lsp-progress.nvim",
  config = function()
    require("lsp-progress").setup({
      client_format = function(client_name, spinner, series_messages)
        if #series_messages == 0 then
          return nil
        end
        return {
          name = client_name,
          body = spinner .. " " .. table.concat(series_messages, ", "),
        }
      end,
      format = function(client_messages)
        --- @param name string
        --- @param msg string?
        --- @return string
        local function stringify(name, msg)
          return msg and string.format("%s %s", name, msg) or name
        end

        local linter_sign = "" -- nf-fa-gear \uf013
        local lsp_sign = " LSP(s):"

        -- Get the current file type
        local filetype = vim.bo.filetype

        -- Filter LSP clients by file type
        local lsp_clients = vim.lsp.get_active_clients()
        local relevant_lsp_clients = {}
        for _, client in ipairs(lsp_clients) do
          if client.config.filetypes and vim.tbl_contains(client.config.filetypes, filetype) then
            table.insert(relevant_lsp_clients, client)
          end
        end

        -- Get relevant linters for the current file type
        local linters = require("lint").linters_by_ft[filetype] or {}
        local running_linters = require("lint").get_running()
        local relevant_linters = vim.tbl_filter(function(linter)
          return vim.tbl_contains(running_linters, linter)
        end, linters)

        local combined_clients = {}

        -- Add relevant LSP clients to the combined list
        for _, client in ipairs(relevant_lsp_clients) do
          table.insert(combined_clients, { name = client.name, type = "lsp" })
        end

        -- Add relevant linters to the combined list
        for _, linter in ipairs(relevant_linters) do
          table.insert(combined_clients, { name = linter, type = "linter" })
        end

        local messages_map = {}
        for _, climsg in ipairs(client_messages) do
          messages_map[climsg.name] = climsg.body
        end

        if #combined_clients > 0 then
          table.sort(combined_clients, function(a, b)
            return a.name < b.name
          end)
          local builder = {}
          local linter_added = false
          local lsp_added = false

          for i, cli in ipairs(combined_clients) do
            if type(cli) == "table" and type(cli.name) == "string" and string.len(cli.name) > 0 then
              if cli.type == "linter" and not linter_added then
                table.insert(builder, linter_sign)
                linter_added = true
              elseif cli.type == "lsp" and not lsp_added then
                table.insert(builder, lsp_sign)
                lsp_added = true
              end

              local name_with_message = cli.name
              if messages_map[cli.name] then
                name_with_message = stringify(cli.name, messages_map[cli.name])
              end

              -- Add a comma if it's not the last item
              if i < #combined_clients then
                table.insert(builder, name_with_message .. ",")
              else
                table.insert(builder, name_with_message)
              end
            end
          end
          if #builder > 0 then
            return table.concat(builder, " ")
          end
        end
        return ""
      end,
    })
  end,
  lazy = false,
  event = "VimEnter", -- Ensures it starts after Neovim finishes loading
}

