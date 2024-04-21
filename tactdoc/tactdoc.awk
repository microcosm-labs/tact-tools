# SPDX-License-Identifier: MIT
# Copyright (C) Microcosm Labs 2024
# Tactdoc - Documentation generator for Tact source files inspired by rustdoc
# Author: @0kenx
# Version: 0.1.0
# GitHub: https://github.com/microcosm-labs
#
# AWK script to process source files with refined field detection, linking, and multi-line documentation.
# Modify the `github_path` and `branch` variables to match your repository.
# Usage: awk -f tactdoc.awk <source_file.tact> > documentation.md
# Usage: awk -f tactdoc.awk ./contracts/*.tact > documentation.md

BEGIN {
    current_block = "";  # Keep track of the current message or contract
    last_comment = "";   # Store the last seen documentation comment
    accumulating_comments = 0;  # Flag to indicate if we are currently accumulating comments
    in_sub_block = 0; # Flag to indicate if we are currently in a sub-block
    github_path = "https://github.com/microcosm-labs/tact-tools";
    branch = "main";
}

# Add a sub-block flag
/\{/ {
    if (current_block != "") {
        # print "Entering sub-block from block: " current_block " on line " NR;
        in_sub_block = 1;  # Set sub-block flag
    }
}

# Capture documentation comments
/^\s*\/\/\/\s/ {
    parsed_comment0 = gensub(/\s*\/\/\/\s/, "", "g", $0);  # Clean up the comment
    parsed_comment = gensub(/^#/, "###", "g", parsed_comment0);  # Clean up the comment
    if (accumulating_comments) {
        last_comment = last_comment "\n" parsed_comment;  # Accumulate multi-line comments
    } else {
        last_comment = parsed_comment;  # Start new comment
        accumulating_comments = 1;  # Start accumulating comments
    }
}

# Detect entering a message, contract or struct and store its name
/^\s*(message(\(.*\))?|contract|struct)\s+([a-zA-Z0-9_]+)/ {
    current_block = $2;  # Capture the name of the message or contract
    # print "Entering block: " current_block " on line " NR;
    print "\n## "$1" ["current_block"]("github_path"/blob/"branch last_file_pathname"#L"NR")";
    if (last_comment != "") {
        print "\n"last_comment;
    }
    print "\n**Fields**  ";
    last_comment = "";  # Reset last comment after associating
}

# Check for receive sections
/^\s*receive\s*\(([^)]+)\)/ {
    section_name = gensub(/(^.*\(|\).*$)/, "", "g", $0);  # Clean up the section name
    section_type = gensub(/^.*:\s*/, "", "g", section_name);  # Clean up the section type
    # print "Section start found on line " NR ": " $0;
    print "\n## Receive [" section_type"]("github_path"/blob/"branch last_file_pathname"#L"NR")\n";
    if (last_comment != "") {
        print last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for fun, get fun, and init sections
/^\s*(get\s|inline\s|extends\s|virtual\s)*(fun|init)\s+([a-zA-Z0-9_]+)\s*\(/ {
    section_name = gensub(/(.*(fun|init)\s|\s*{)/, "", "g", $0);  # Clean up the section name
    # print "Section start found on line " NR ": " $0;
    print "\n## Function [" section_name"]("github_path"/blob/"branch last_file_pathname"#L"NR")\n";
    if (last_comment != "") {
        print last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for fields within message or contract blocks and link them
/^\s*[a-zA-Z0-9_]+\s*:/ {
    if (current_block != "" && in_sub_block == 0) {
        field_name = gensub(/(^\s*|:.*)/, "", "g", $0);  # Clean up the field name
        field_type = gensub(/(^.*[^A-Z]:\s?|;?\s*$|;.*$)/, "", "g", $0);  # Clean up the field type
        # print "Field documentation for " current_block " found on line " NR ": " $0;
        print "* ["field_name"]("github_path"/blob/"branch last_file_pathname"#L"NR"): " field_type"  ";
        if (last_comment != "") {
            print last_comment;
        }
        last_comment = "";  # Reset last comment after associating
    }
}

# Handle non-comment lines to reset comment accumulation
/^\s*[a-zA-z0-9\{\}\(\)]/ {
    # print "Matching non-comment line: " $0;
    accumulating_comments = 0;  # Reset comment accumulation
}

# Reset current block when exiting a block
/^\}/ {
    if (current_block != "") {
        # print "Exiting block: " current_block " on line " NR;
        current_block = "";  # Reset current block when exiting
        in_sub_block = 0;  # Reset sub-block flag
        last_comment = "";  # Reset last comment after exiting block
    }
}

# Function to print markdown header
function print_markdown_header(file) {
    print "# Documentation for [" file"]("github_path"/blob/"branch last_file_pathname")";
}

# Process each file
{
    if (FILENAME != last_file) {
        if (last_file != "") {
            print "\n"; # Print a newline between files
        }
        last_file = FILENAME;
        last_file_pathname = gensub(/^./, "", "g", FILENAME);
        print_markdown_header(gensub(/^.\//, "", "g", FILENAME));
    }
}

END {
    if (last_file != "") {
        print "\n"; # Ensure ending newline for the last processed file
    }
    print "\n*Document generated by [Tactdoc](https://github.com/microcosm-labs/tact-tools/tree/main/tactdoc). Copyright © 2024 Microcosm Labs.*";
}
