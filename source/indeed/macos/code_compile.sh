codecompile() {
    echo "Compiling code documentation for Indeed projects..."
    echo "This script analyzes code repositories and generates documentation in Obsidian format"
    /Users/tpinto/code/python-playground/venv/bin/python \
        /Users/tpinto/code/python-playground/codes/code_compiler3.py \
        "/Users/tpinto/code/angam" \
        "/Users/tpinto/code/eda-scribble" \
        "/Users/tpinto/code/evo-conversions" \
        "/Users/tpinto/code/evo-event-triggers" \
        "/Users/tpinto/code/evo-kafka-consumers" \
        "/Users/tpinto/code/fusion-lms-leads-router" \
        "/Users/tpinto/code/fusion-data-checker" \
        "/Users/tpinto/code/fusion-lms" \
        "/Users/tpinto/code/jobs-info" \
        "/Users/tpinto/code/mrlds" \
        "/Users/tpinto/code/synapse-kafka-publisher" \
        "/Users/tpinto/code/synapse-lib" \
        "/Users/tpinto/code/synapse-triggers" \
        "/Users/tpinto/code/synapse" \
        "/Users/tpinto/code/swiftlift" \
        "/Users/tpinto/code/fusion-block-dca" \
        "/Users/tpinto/madpin/swap" \
        "/Users/tpinto/code/synapse-leads" \
        /Users/tpinto/code/evo-jira-summarizer \
        /Users/tpinto/setup-station \
        --table-tree --no-deps --frontmatter \
        -o "/Users/tpinto/Library/Mobile Documents/iCloud~md~obsidian/Documents/MadVault/Indeed/Codes/"
}