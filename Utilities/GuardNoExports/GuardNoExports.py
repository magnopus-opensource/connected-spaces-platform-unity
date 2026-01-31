# This script runs in the CMake configure.
# CSP has been written with a legacy wrapper generator in mind, and has made heavy
# use of macro based code annotations to define a public interface.
# This is problematic. These "public but not really" symbols need to be ignored
# by us to avoid having them in the public interface, although even more crucially,
# the CSP repo has used this power as a means to allow them to reference non public
# types in public headers, which will fail a compile for us.
#
# What this script does is leverage the SWIG macro that Swig defines during preprocessing.
# It transforms the export macros into #ifdef guards that filter these symbols out
# during SWIG parsing, such that when we %include "CSPFile.h", Swig does not process
# those symbols as interface declarations. However, they remain in the files, and are
# still built into the binary. This is ESSENTIAL, as you must retain the same symbol
# layout (particularly for virtual functions), when linking, if you are not to run 
# afoul of ABI breaking UB. This is a lesson the author learned the hard way.
#
# There are two patterns that need to be dealt with
# -- CSP_START_IGNORE and CSP_END_IGNORE blocks --
#   These indicate that all of the content inside the block should be ignored
#   Start ignore is transformed directly to #ifndef SWIG and end ignore into #endif
#
# -- CSP_NO_EXPORT --
#   This is a tag that (normally) applies to a function declaration.
#   It's a little tricker, as C++ function declarations are not necessarily one line
#   long, and nor are they necessarily terminated by a semicolon, in the case of 
#   inline definitions. Logic is done to determine where to place the #endif.
#
# The hope is that this will eventually become unnecessary, CSP can manage it's public
# interface in a more correct way, either by virtuously refusing to have 
# "public but not really" interfaces, or leveraging PIMPL if they really must in
# order to hide that sort of stuff.

from pathlib import Path
import argparse

def LineEndSignifiesEndOfNoExportDeclaration(line: str) -> bool:
    return (
             line.endswith(");")
             or line.endswith("}")
             or line.endswith("};")
             or line.endswith("const;")
             or line.endswith("const ;")
             or line.endswith("override;")
             or line.endswith("override ;")
             or line.endswith("= 0;")
           )

IFNDEF = "#ifndef SWIG"
ENDIF = "#endif"

START_IGNORE = "CSP_START_IGNORE"
END_IGNORE = "CSP_END_IGNORE"
NO_EXPORT = "CSP_NO_EXPORT"

# Easy replace of START_IGNORE and END_IGNORE with IFNDEF guards
def GuardStartEndIgnoreBlocks(text: str) -> str:
    text = text.replace(START_IGNORE, IFNDEF)
    text = text.replace(END_IGNORE, ENDIF)
    return text

def PlaceIfndefGuardsAboveAndBelowRange(text: str, lineRanges: list[tuple[int, int]]) -> str:
    lines = text.splitlines()

    # Keep track of how many newlines we've inserted, as each range needs
    # to be pushed down by this amount as we mutate the lines array
    lineModifier : int = 0

    for lineRange in lineRanges:
        # Insert IFNDEF above top of range
        startingLine = lineRange[0] + lineModifier
        lines = lines[0:startingLine] + [IFNDEF] + lines[startingLine:] 
        lineModifier += 1

        # Insert ENDIF at bottom of range
        endingLine = lineRange[1] + lineModifier
        lines = lines[0:endingLine+1] + [ENDIF] + lines[endingLine+1:] 
        lineModifier += 1

    return "\n".join(
        line for i, line in enumerate(lines, start=0)
    )


# IFNDEF guard CSP_NO_EXPORT declarations, using a simple bracket counting mechanism 
# and assuming semicolon terminations.
# Should be good enough.
def GuardNoExportDeclarations(text: str) -> str:

    # Build a list of ranges that the no-exports span, we'll put the ifndef guards
    # above and below these ranges. So this is a list of line-number rangers
    # If I was better at python I'd have a nicer way of expressing a fixed size
    # list[2], could use a tuple but they're immutable and I don't know the end value
    # when I place the start value.
    noExportBlocks: list[tuple[int, int]] = []

    inExportBlock = False

    lineCounter = 0
    rangeStartLineTracker = -1
    rangeEndLineTracker = -1
    
    openNormalBrackets = 0
    openCurlyBrackets = 0

    def AppendNoExportLineRange(lineStart, lineEnd):
        noExportBlocks.append((lineStart, lineEnd)) 
        rangeStartLineTracker = -1
        rangeEndLineTracker = -1


    for line in text.splitlines():
        if not inExportBlock:
            if line.lstrip().startswith("CSP_NO_EXPORT"):
                openNormalBrackets += line.count('(')
                openCurlyBrackets += line.count('{')
                
                openNormalBrackets -= line.count(')')
                openCurlyBrackets -= line.count('}')
                
                # Single line declarations are done, don't start a multiline count
                if not LineEndSignifiesEndOfNoExportDeclaration(line):
                    inExportBlock = True
                    rangeStartLineTracker = lineCounter
                else:
                    AppendNoExportLineRange(lineCounter, lineCounter) # Still want to make a line range, even though it's a single line
        else:
            if rangeStartLineTracker == -1:
                raise ValueError("A new CSP_NO_EXPORT block was detected, but its start was not correctly tracked!")

            openNormalBrackets += line.count('(')
            openCurlyBrackets += line.count('{')
            
            openNormalBrackets -= line.count(')')
            openCurlyBrackets -= line.count('}')
            if LineEndSignifiesEndOfNoExportDeclaration(line) :
                if openNormalBrackets <= 0 and openCurlyBrackets <= 0:
                    if openNormalBrackets > 0:
                        raise ValueError("Mismatched count of normal brackets")
                    if openCurlyBrackets > 0:
                        raise ValueError("Mismatched count of curly brackets")
                    
                    inExportBlock = False
                    openNormalBrackets = 0
                    openCurlyBrackets = 0
                    rangeEndLineTracker = lineCounter
                    AppendNoExportLineRange(rangeStartLineTracker, rangeEndLineTracker)
                
        lineCounter = lineCounter+1
    
    # Now we've got all the lines that are CSP_NO_EXPORT declarations, remove them
    return PlaceIfndefGuardsAboveAndBelowRange(text, noExportBlocks)

# CSPCommon is where internal macros are defined, don't want to blast them away.
# The others have weird out-of-pattern CSP_NO_EXPORT's at the top of the file that can't be trivially removed (legacy wrapper gen :/)
# It's okay, none of them matter to us from a public API perspective.
filenames_to_ignore = {"CSPCommon.h", "String.h", "Optional.h", "StringFormat.h"}

def main():
    parser = argparse.ArgumentParser(
        description="Wrap CSP_START_IGNORE / CSP_END_IGNORE and CSP_NO_EXPORT blocks in files with IFNDEF guards, so the SWIG parser ignores their CSP code as intended."
    )
    parser.add_argument("input_root", help="CSP include root directory")
    parser.add_argument("output_root", help="Path to the output directory where IFNDEF-guarded code will be stored")

    args = parser.parse_args()
    
    src_root = Path(args.input_root)
    dst_root = Path(args.output_root)

    for src_file in src_root.rglob("*.h"):

        if src_file.is_file():
            rel_path = src_file.relative_to(src_root)
            dst_file = dst_root / rel_path

            # Make the directories as we go, we're mirroring the directory structure for the output
            dst_file.parent.mkdir(parents=True, exist_ok=True)

            # Do our transformations
            with src_file.open("r", encoding="utf-8") as f_in, dst_file.open("w", encoding="utf-8") as f_out:
                data = f_in.read()
                modified = data    
                # Don't modify any ignored files
                if src_file.name not in filenames_to_ignore:
                    print(src_file.name)
                    modified = GuardStartEndIgnoreBlocks(data)
                    modified = GuardNoExportDeclarations(modified)
 
                f_out.write(modified)
                
if __name__ == "__main__":
    main()