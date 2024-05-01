# SPDX-License-Identifier: MIT
# Copyright (C) Microcosm Labs 2024
# Tactdoc - Documentation generator for Tact source files inspired by rustdoc
# Author: @0kenx
# Version: 0.1.3
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
    sub_block_depth = 0; # Current depth of sub-block
    fields_section = 0;  # Flag to indicate if we are currently in a fields section
    rel_path = "..";  # Relative path of the document directory to the repository root
    prev_nr = 0;  # Store the line number of all previous files
}


# Function to print markdown header
function print_markdown_header(file) {
    print "# Documentation for [" file"]("rel_path last_file_pathname")\n";
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
        prev_nr = NR - 1;  # Store the line number of the last file
    }
}

# Capture documentation comments
/^\s*\/\/\/\s/ {
    parsed_comment0 = gensub(/\s*\/\/\/\s/, "", "g", $0);  # Clean up the comment
    parsed_comment = gensub(/^#/, "####", "g", parsed_comment0);  # Clean up the comment
    if (accumulating_comments) {
        last_comment = last_comment "\n" parsed_comment;  # Accumulate multi-line comments
    } else {
        last_comment = parsed_comment;  # Start new comment
        accumulating_comments = 1;  # Start accumulating comments
    }
}

# For inner comments we print them out directly
/^\s*\/\/!\s/ {
    parsed_comment0 = gensub(/\s*\/\/!\s/, "", "g", $0);  # Clean up the comment
    parsed_comment = gensub(/^#/, "####", "g", parsed_comment0);  # Clean up the comment
    print parsed_comment;
}

# Detect entering a message and store its name
/^\s*(message(\(.*\))?)\s+([a-zA-Z0-9_]+)/ {
    current_block = $2;  # Capture the name of the message or contract
    # print "Entering block: " current_block " on line " NR - prev_nr;
    print "\n### Message ["current_block"]("rel_path last_file_pathname"#L"NR - prev_nr")";
    if (last_comment != "") {
        print "\n"last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Detect entering a struct and store its name
/^\s*(struct)\s+([a-zA-Z0-9_]+)/ {
    current_block = $2;  # Capture the name of the message or contract
    # print "Entering block: " current_block " on line " NR - prev_nr;
    print "\n### Struct ["current_block"]("rel_path last_file_pathname"#L"NR - prev_nr")";
    if (last_comment != "") {
        print "\n"last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Detect entering a contract and store its name
/^\s*(contract)\s+([a-zA-Z0-9_]+)/ {
    current_block = $2;  # Capture the name of the message or contract
    # print "Entering block: " current_block " on line " NR - prev_nr;
    print "\n## Contract ["current_block"]("rel_path last_file_pathname"#L"NR - prev_nr")";
    if (last_comment != "") {
        print "\n"last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Detect entering a trait and store its name
/^\s*(trait)\s+([a-zA-Z0-9_]+)/ {
    current_block = $2;  # Capture the name of the message or contract
    # print "Entering block: " current_block " on line " NR - prev_nr;
    print "\n## Trait ["current_block"]("rel_path last_file_pathname"#L"NR - prev_nr")";
    if (last_comment != "") {
        print "\n"last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for receive sections
/^\s*receive\s*\(([^)]+)\)/ {
    section_name = gensub(/(^.*\(|\).*$)/, "", "g", $0);  # Clean up the section name
    section_type = gensub(/^.*:\s*/, "", "g", section_name);  # Clean up the section type
    # print "Section start found on line " NR - prev_nr ": " $0;
    print "\n### Receive [" section_type"]("rel_path last_file_pathname"#L"NR - prev_nr")\n";
    if (last_comment != "") {
        print last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for fun, get fun, inline fun sections
/^\s*(get\s|inline\s|extends\s|virtual\s)*(fun)\s+([a-zA-Z0-9_]+)\s*\(/ {
    section_name = gensub(/(.*(fun)\s|\s*\{)/, "", "g", $0);  # Clean up the section name
    # print "Section start found on line " NR - prev_nr ": " $0;
    print "\n### Function [" section_name"]("rel_path last_file_pathname"#L"NR - prev_nr")\n";
    if (last_comment != "") {
        print last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for init sections
/^\s*(init)\s*\(/ {
    # print "Section start found on line " NR - prev_nr ": " $0;
    section_name = gensub(/(^\s*|\s*\{)/, "", "g", $0);  # Clean up the section name
    print "\n### Initializer [" section_name"]("rel_path last_file_pathname"#L"NR - prev_nr")\n";
    if (last_comment != "") {
        print last_comment;
    }
    last_comment = "";  # Reset last comment after associating
}

# Check for fields within message or contract blocks and link them
/^\s*[a-zA-Z0-9_]+\s*:/ {
    # print "Current block: " current_block " In sub-block: " sub_block_depth " on line " NR - prev_nr ": " $0;
    if (current_block != "" && sub_block_depth == 1) {
        if (fields_section == 0) {
            print "\n**Fields**  ";
            fields_section = 1;  # Set fields section flag
        }
        field_name = gensub(/(^\s*|:.*)/, "", "g", $0);  # Clean up the field name
        field_type = gensub(/(^.*[^A-Z]:\s?|;?\s*$|;.*$)/, "", "g", $0);  # Clean up the field type
        # print "Field documentation for " current_block " found on line " NR - prev_nr ": " $0;
        print "* ["field_name"]("rel_path last_file_pathname"#L"NR - prev_nr"): " field_type"  ";
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

# Add sub-block depth
/\{/ {
    sub_block_depth += 1;
}

# Remove sub-block depth
/\}/ {
    sub_block_depth -= 1;
}

# Reset current block when exiting a block
/^\}/ {
    if (current_block != "") {
        # print "Exiting block: " current_block " on line " NR - prev_nr;
        current_block = "";  # Reset current block when exiting
        last_comment = "";  # Reset last comment after exiting block
        fields_section = 0;  # Reset fields section flag
    }
}

END {
    if (last_file != "") {
        print "\n"; # Ensure ending newline for the last processed file
    }
    print "\n*Documentation generated by [Tactdoc](https://github.com/microcosm-labs/tact-tools/tree/main/tactdoc) v0.1.3.*";
}