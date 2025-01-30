local prompts = {
    Explain = "Please explain how the following code works.",
    Review = "Please review the following code and provide suggestions for improvement.",
    Tests = "Please explain how the selected code works, then generate unit tests for it.",
    Refactor = "Please refactor the following code to improve its clarity and readability.",
    FixCode = "Please fix the following code to make it work as intended.",
    FixError = "Please explain the error in the following text and provide a solution.",
    BetterNaming = "Please provide better names for the following variables and functions.",
    Documentation = "Please provide documentation for the following code.",
    JsDocs = "Please provide JsDocs for the following code.",
    DocumentationForGithub = "Please provide documentation for the following code ready for GitHub using markdown.",
    CreateAPost =
    "Please provide documentation for the following code to post it in social media, like Linkedin, it has to be deep, well explained and easy to understand.",
    SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
    SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
    Summarize = "Please summarize the following text.",
    Spelling = "Please correct any grammar and spelling errors in the following text.",
    Wording = "Please improve the grammar and wording of the following text.",
    Concise = "Please rewrite the following text to make it more concise.",
}

return {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
        { "github/copilot.vim" },                       -- or zbirenbaum/copilot.lua
        { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken",                            -- Only on MacOS or Linux
    opts = {
        prompts = prompts,
    },
    -- See Commands section for default commands if you want to lazy load on them
    keys = {
        { "<leader>c", group = 'Copilot', desc = 'Copilot' },
        {
            "<leader>cc",
            function() vim.cmd [[CopilotChat]] end,
            desc = "Open Copilot"
        },
        {
            "<leader>ct",
            function() vim.cmd [[CopilotChatToggle]] end,
            desc = "Toggle Copilot"
        },
        {
            "<leader>cs",
            function() vim.cmd [[CopilotChatStop]] end,
            desc = "Stop Copilot"
        },
        {
            "<leader>cr",
            function() vim.cmd [[CopilotChatReset]] end,
            desc = "Reset Copilot"
        },
        {
            "<leader>cpe",
            function() vim.cmd [[CopilotChatExplain]] end,
            desc = "Explain code"
        },
        {
            "<leader>cprw",
            function() vim.cmd [[CopilotChatReview]] end,
            desc = "Review code"
        },
        {
            "<leader>cpt",
            function() vim.cmd [[CopilotChatTests]] end,
            desc = "Generate tests"
        },
        {
            "<leader>cprf",
            function() vim.cmd [[CopilotChatRefactor]] end,
            desc = "Refactor code"
        },
        {
            "<leader>cpf",
            function() vim.cmd [[CopilotChatFixCode]] end,
            desc = "Fix code"
        },
        {
            "<leader>cpfe",
            function() vim.cmd [[CopilotChatFixError]] end,
            desc = "Fix error"
        },
        {
            "<leader>cpn",
            function() vim.cmd [[CopilotChatBetterNaming]] end,
            desc = "Better naming"
        },
        {
            "<leader>cpd",
            function() vim.cmd [[CopilotChatDocumentation]] end,
            desc = "Documentation"
        },
        {
            "<leader>cpj",
            function() vim.cmd [[CopilotChatJsDocs]] end,
            desc = "JsDocs"
        },
        {
            "<leader>cpg",
            function() vim.cmd [[CopilotChatDocumentationForGithub]] end,
            desc = "Documentation for GitHub"
        },
        {
            "<leader>cpp",
            function() vim.cmd [[CopilotChatCreateAPost]] end,
            desc = "Create a post"
        },
        {
            "<leader>cpa",
            function() vim.cmd [[CopilotChatSwaggerApiDocs]] end,
            desc = "Swagger API docs"
        },
        {
            "<leader>cpsj",
            function() vim.cmd [[CopilotChatSwaggerJsDocs]] end,
            desc = "Swagger JsDocs"
        },
        {
            "<leader>cps",
            function() vim.cmd [[CopilotChatSummarize]] end,
            desc = "Summarize"
        },
        {
            "<leader>cpo",
            function() vim.cmd [[CopilotChatSpelling]] end,
            desc = "Spelling"
        },
        {
            "<leader>cpw",
            function() vim.cmd [[CopilotChatWording]] end,
            desc = "Wording"
        },
        {
            "<leader>cpc",
            function() vim.cmd [[CopilotChatConcise]] end,
            desc = "Concise"
        },
    }
}
