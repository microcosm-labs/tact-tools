BEGIN {
    sub_block_depth = 0; # Current depth of sub-block
    rel_path = "..";  # Relative path of the document directory to the repository root
}

# Function to format code before comments
function format_code_before_comment(line) {
    match(line, /^[ \t]*/);
    indentation_part = substr(line, RSTART, RLENGTH);
    rest = substr(line, RLENGTH + 1);
    # Split rest by quotes to handle string literals
    n = split(rest, segments, /"/);
    code_part = "";
    comment_part = "";
    comment_found = 0;

    for (i = 1; i <= n; i++) {
        if (i % 2 == 1) {
            # Check for comment outside of quotes
            comment_index = index(segments[i], "//");
            if (comment_index > 0 && !comment_found) {
                code_part = code_part substr(segments[i], 1, comment_index - 1);
                comment_part = substr(segments[i], comment_index);
                comment_found = 1;
            } else if (comment_found) {
                comment_part = comment_part segments[i];
            } else {
                code_part = code_part segments[i];
            }
        } else {
            if (comment_found) {
                comment_part = comment_part "\"" segments[i] "\"";
            } else {
                code_part = code_part "\"" segments[i] "\"";
            }
        }
    }

    # Only process code_part if it's not empty
    if (length(code_part) > 0) {
        # Split code_part by quotes to handle string literals
        n = split(code_part, segments, /"/);
        ternary_detected = 0;
        ternary_start = 0;
        ternary_end = 0;
        for (i = 1; i <= n; i++) {
            # Only format segments that are outside of quotes
            if (i % 2 == 1) {
                # Remove all spaces surrounding symbols
                segments[i] = gensub(/\s*([{}()<>=:;,.!?+\-*/|&^])\s*/, "\\1", "g", segments[i]);

                # Add spaces around specific symbols
                segments[i] = gensub(/([<>{}=|&^+\-*/]|!=)/, " \\1 ", "g", segments[i]);  # Add spaces around these symbols
                segments[i] = gensub(/([,\)?:])\s*/, "\\1 ", "g", segments[i]);  # Add space only after these symbols
                segments[i] = gensub(/(!!)\s*/, "\\1 ", "g", segments[i]);  # Add space only after these symbols
                # segments[i] = gensub(/([{])\s*/, " \\1", "g", segments[i]);  # Add space only before these symbols
                segments[i] = gensub(/\s+/, " ", "g", segments[i]);  # Replace multiple spaces with a single space again
                segments[i] = gensub(/([><=|&^+\-!])\s+([><=|&])/, "\\1\\2", "g", segments[i]);  # Remove spaces between symbols
                segments[i] = gensub(/([><=|&^+\-!])\s+([><=|&])/, "\\1\\2", "g", segments[i]);  # Remove spaces between symbols
                segments[i] = gensub(/([:\(\){}?!])\s+([:\(\)}?])/, "\\1\\2", "g", segments[i]);  # Remove spaces between symbols
                segments[i] = gensub(/([:\(\){}?!])\s+([:\(\)}?])/, "\\1\\2", "g", segments[i]);  # Remove spaces between symbols
                segments[i] = gensub(/(map|bounced)\s*<\s*([^>]+)\s>\s/, "\\1<\\2>", "g", segments[i]);  # Remove space for map<> template
                segments[i] = gensub(/([=><&|*\/+\-:])\s*-\s*/, "\\1 -", "g", segments[i]);  # Remove space for negative numbers
                segments[i] = gensub(/([\(])\s*-\s*/, "\\1-", "g", segments[i]);  # Remove space for negative numbers
                segments[i] = gensub(/\s*([.])\s*/, "\\1", "g", segments[i]);  # Remove all spaces surrounding symbols again
                segments[i] = gensub(/\s*(!!|;|,)/, "\\1", "g", segments[i]);  # Remove leading spaces to symbols again
                segments[i] = gensub(/(if|for|repeat|while|return)(\()/, "\\1 \\2", "g", segments[i]);  # Add space only after these keywords
                segments[i] = gensub(/^\s+|\s+$/, "", "g", segments[i]);  # Trim leading and trailing spaces again

                if (segments[i] ~ /\?/) {
                    ternary_start = i;
                }
                if (segments[i] ~ / fun /) {
                    ternary_start = 0;
                }
                split(segments[i], ts, /\?/);
                tsr = gensub(/\{(.*)\}/, "", "g", ts[2]);  # Remove everything inside curly braces
                if (tsr ~ /:/ && ternary_start > 0) {
                    ternary_end = i;
                    ternary_detected = 1;
                    break;
                }
            }
        }
        if (ternary_detected) {
            for (i = ternary_start; i <= ternary_end; i++) {
                if (i % 2 == 1) {
                    # Format ternary operator
                    segments[i] = gensub(/\s*\?\s*/, " ? ", "g", segments[i]);
                    segments[i] = gensub(/\s*:\s*/, " : ", "g", segments[i]);
                }
            }
        }
        # Reconstruct the code_part from segments
        code_part = segments[1];
        for (i = 2; i <= n; i++) {
            if (i % 2 == 0) {
                # Check if the last character of code_part is a symbol
                if (code_part == "" || match(code_part, /[{}().]$/)) {
                    code_part = code_part "\"" segments[i];
                } else {
                    code_part = code_part " \"" segments[i];
                }
            } else {
                # Check if the first character of segments[i] is a symbol
                if (segments[i] == "" || match(segments[i], /^[{}().;]/)) {
                    code_part = code_part "\"" segments[i];
                } else {
                    code_part = code_part "\" " segments[i];
                }
            }
        }
        if (length(comment_part) > 0) {
            code_part = code_part " ";  # Add a space between the code and the comment
        }
    }

    return indentation_part code_part (comment_part ? comment_part : "");
}

# Process each line
{
    # Format the line before the comment
    formatted_line = format_code_before_comment($0);
    # Remove multiple consecutive blank lines
    if (formatted_line ~ /^[ \t]*$/) {
        if (!blank_line) {
            print "";
            blank_line = 1;
        }
    } else {
        print formatted_line;
        blank_line = 0;
    }
}

# Add sub-block depth
/\{/ {
    sub_block_depth += 1;
}

# Remove sub-block depth
/\}/ {
    sub_block_depth -= 1;
}

END {
}
