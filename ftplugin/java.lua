-- ==============================================
-- ftplugin/java.lua
-- .java ファイルを開いたときにNeovimが自動で読み込む設定ファイル
-- （ftplugin/<filetype>.lua はファイルタイプごとの設定を書く仕組み）
--
-- nvim-jdtls を使って Java の LSP（補完・定義ジャンプ・エラー表示）と
-- DAP（デバッガー）をまとめてセットアップする
-- ==============================================

local jdtls = require("jdtls")

-- ==============================================
-- プロジェクトのルートディレクトリを探す
-- .git や pom.xml (Maven) / build.gradle (Gradle) がある場所を基準にする
-- ==============================================
local root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
if root_dir == "" then
	return
end

-- ==============================================
-- ワークスペース（jdtlsがプロジェクトごとの状態を保存する場所）
-- プロジェクトごとに別フォルダにする
-- ==============================================
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/site/jdtls-workspace/" .. project_name

-- ==============================================
-- デバッグ機能（java-debug-adapter / java-test）のjarファイルを探す
-- Mason経由でインストールされたものを自動で見つける
-- ==============================================
local bundles = {}
local mason_registry = require("mason-registry")

if mason_registry.is_installed("java-debug-adapter") then
	local java_debug_path = mason_registry.get_package("java-debug-adapter"):get_install_path()
	vim.list_extend(
		bundles,
		vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n")
	)
end

if mason_registry.is_installed("java-test") then
	local java_test_path = mason_registry.get_package("java-test"):get_install_path()
	vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n"))
end

-- ==============================================
-- LSPのセットアップ本体
-- ==============================================
local config = {
	-- jdtls本体を起動するコマンド
	-- "jdtls" はMasonが $PATH に追加した実行ファイル
	-- （OSごとの設定ファイルや起動用jarを自動で選んでくれる）
	cmd = { "jdtls", "-data", workspace_dir },

	root_dir = root_dir,

	-- デバッグ・テスト実行機能を有効にするための拡張バンドル
	init_options = {
		bundles = bundles,
	},

	-- LSPがファイルにアタッチしたときに実行される処理
	on_attach = function(client, bufnr)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- ==============================================
		-- LSPキーマップ（VSCodeのコード操作に相当）
		-- ==============================================
		map("n", "gd", vim.lsp.buf.definition, "定義へジャンプ")
		map("n", "gr", vim.lsp.buf.references, "参照を検索")
		map("n", "K", vim.lsp.buf.hover, "ホバー情報を表示")
		map("n", "<leader>rn", vim.lsp.buf.rename, "名前を変更")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "コードアクション")

		-- 入力中に自動で補完候補を出す（ネイティブLSP補完）
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })

		-- ==============================================
		-- デバッガー（DAP）のセットアップ
		-- ==============================================
		jdtls.setup_dap({ hotcodereplace = "auto" })
		require("jdtls.dap").setup_dap_main_class_configs()

		-- このクラス／直近のメソッドをテスト実行するキー
		map("n", "<leader>df", function()
			require("jdtls.dap").test_class()
		end, "このクラスのテストを実行")
		map("n", "<leader>dn", function()
			require("jdtls.dap").test_nearest_method()
		end, "直近のテストメソッドを実行")
	end,
}

jdtls.start_or_attach(config)
