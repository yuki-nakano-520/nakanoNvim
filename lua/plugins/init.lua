-- ==============================================
-- plugins/init.lua
-- VSCodeの拡張機能マーケットプレイスに相当
-- lazy.nvim というプラグインマネージャーを使って
-- 拡張機能（プラグイン）を管理する
-- ==============================================

-- lazy.nvimのインストール先パスを変数に入れる
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- lazy.nvim がまだインストールされていない場合は
-- GitHubから自動でダウンロードする
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

-- lazy.nvim をNeovimのパスに追加する
vim.opt.rtp:prepend(lazypath)

-- lua/plugins/ 以下のファイルを全部読み込む
-- これにより後で追加するプラグイン設定が自動で読み込まれる
-- プラグインの一覧
local plugins = {

	-- ==============================================
	-- カラーテーマ
	-- ==============================================
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("vscode").setup({
				-- 背景を透明にする
				transparent = true,
			})
			vim.cmd("colorscheme vscode")
		end,
	},

	-- ==============================================
	-- ステータスバー
	-- 画面下部にモード・ファイル名・行番号などを表示する
	-- VSCodeの下部バーに相当する
	-- ==============================================
	{
		"nvim-lualine/lualine.nvim",

		-- アイコン表示に必要なプラグインを先に読み込む
		dependencies = { "nvim-tree/nvim-web-devicons" },

		config = function()
			require("lualine").setup({
				options = {
					-- VSCodeテーマに合わせた配色にする
					theme = "vscode",
				},
			})
		end,
	},
	-- ==============================================
	-- ファイルツリー
	-- VSCodeの左サイドバーに相当する
	-- Ctrl+B でトグル（表示/非表示）できる
	-- ==============================================
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				view = {
					-- サイドバーの横幅
					width = 35,
				},
				renderer = {
					-- 空フォルダをまとめて表示する
					group_empty = true,
				},
			})

			-- Ctrl+B でファイルツリーを開閉する（VSCodeと同じキー）
			vim.keymap.set("n", "<C-b>", ":NvimTreeToggle<CR>")
		end,
	},
	-- ==============================================
	-- Telescope（ファイル検索）
	-- VSCodeのCtrl+P に相当する
	-- ファイル名で素早くファイルを開ける
	-- ==============================================
	{
		"nvim-telescope/telescope.nvim",

		-- plenary.nvim はTelescopeが内部で使う便利ライブラリ
		dependencies = { "nvim-lua/plenary.nvim" },

		config = function()
			local builtin = require("telescope.builtin")

			-- Ctrl+P でファイル検索（VSCodeと同じキー）
			vim.keymap.set("n", "<C-p>", builtin.find_files)

			-- Ctrl+Shift+F で全文検索（VSCodeと同じキー）
			vim.keymap.set("n", "<C-S-f>", builtin.live_grep)
		end,
	},
	-- ==============================================
	-- bufferline（タブ表示）
	-- 開いているファイルをVSCodeのタブのように
	-- 画面上部に表示する
	-- ==============================================
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("bufferline").setup({
				options = {
					-- ファイルツリー（nvim-tree）と一緒に使う設定
					-- nvim-treeのパネルをタブに含めない
					offsets = {
						{
							filetype = "NvimTree",
							text = "File Explorer",
							separator = true,
						},
					},
				},
			})

			-- Tab で次のタブへ移動
			vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>")

			-- Shift+Tab で前のタブへ移動
			vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>")
		end,
	},
	-- ==============================================
	-- conform.nvim（フォーマッター）
	-- ==============================================
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},

	-- ==============================================
	-- Mason（パッケージマネージャー）
	-- LSP・フォーマッター・リンターを
	-- Neovimの中からインストール・管理できる
	-- VSCodeの拡張機能マーケットプレイスに相当する
	-- ==============================================
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				-- MasonがインストールしたツールをPATHに追加する
				PATH = "prepend",
			})
		end,
	},
	-- ==============================================
	-- toggleterm.nvim（ターミナル）
	-- Neovim内にターミナルを呼び出せる
	-- Ctrl+T で開閉できる
	-- ==============================================
	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("toggleterm").setup({

				-- ターミナルのサイズ（横分割時の高さ）
				size = 15,

				-- Ctrl+T で開閉する
				open_mapping = [[<C-t>]],

				-- ターミナルの表示方向
				-- "horizontal" → 下に横長で表示
				-- "vertical"   → 右に縦長で表示
				-- "float"      → 画面中央にポップアップ表示
				direction = "horizontal",

				-- ポップアップ表示の設定
				float_opts = {
					-- ウィンドウの枠線のスタイル
					border = "curved",
				},
			})

			-- Claude Code専用のターミナルを作成
			-- スペース+c でClaude Codeを起動する
			local Terminal = require("toggleterm.terminal").Terminal
			local claude = Terminal:new({
				-- 起動するコマンド
				cmd = "claude",
				-- フローティングウィンドウで表示
				direction = "float",
				-- ターミナルを閉じたときにバッファも削除する
				hidden = true,
			})

			-- スペース+c でClaude Codeをトグル
			vim.keymap.set("n", "<leader>c", function()
				claude:toggle()
			end)
		end,
	},

	-- ==============================================
	-- mason-tool-installer
	-- Java開発に必要なツールをMason経由で自動インストールする
	-- jdtls             : Java Language Server本体（補完・定義ジャンプなど）
	-- java-debug-adapter: デバッガー（DAP）機能を提供
	-- java-test         : テストの実行機能を提供
	-- ==============================================
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"jdtls",
					"java-debug-adapter",
					"java-test",
				},
			})
		end,
	},

	-- ==============================================
	-- nvim-dap（デバッガー本体）
	-- VSCodeのデバッグ機能（ブレークポイント・ステップ実行）に相当する
	-- ==============================================
	{
		"mfussenegger/nvim-dap",
	},

	-- ==============================================
	-- nvim-dap-ui（デバッガーのUI）
	-- 変数の中身・スタックトレース・ブレークポイント一覧を画面に表示する
	-- ==============================================
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			-- デバッグ開始時に自動でUIを開く
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			-- デバッグ終了時に自動でUIを閉じる
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- ==============================================
			-- デバッグ用キーマップ（VSCodeと同じF5系キー）
			-- ==============================================
			local map = vim.keymap.set
			map("n", "<F5>", dap.continue, { desc = "デバッグ開始/続行" })
			map("n", "<F10>", dap.step_over, { desc = "ステップオーバー" })
			map("n", "<F11>", dap.step_into, { desc = "ステップイン" })
			map("n", "<F12>", dap.step_out, { desc = "ステップアウト" })
			map("n", "<leader>b", dap.toggle_breakpoint, { desc = "ブレークポイント切替" })
			map("n", "<leader>du", dapui.toggle, { desc = "デバッグUIを開閉" })
		end,
	},

	-- ==============================================
	-- nvim-jdtls
	-- Java専用のLSP+DAP連携プラグイン
	-- 補完・定義ジャンプ・エラー表示・デバッグをまとめて提供する
	-- 実際の起動設定は ftplugin/java.lua で行う
	-- （.javaファイルを開いたときにNeovimが自動でそのファイルを読み込む）
	-- ==============================================
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
	},
}
-- lazy.nvim を起動する
require("lazy").setup(plugins)
