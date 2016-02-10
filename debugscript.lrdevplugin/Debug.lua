--[[----------------------------------------------------------------------------
12345678901234567890123456789012345678901234567890123456789012345678901234567890

Debug 

Copyright 2010-2012, John R. Ellis -- You may use this script for any purpose, as
long as you include this notice in any versions derived in whole or part from
this file.

This module provides an interactive debugger, a prepackaged LrLogger with some
simple utility functions, and a rudimentary elapsed-time functin profiler. For
an introductory overview, see the accompanying "Debugging Toolkit.htm".

Overview of the public interface; for details, see the particular function:

namespace init ([boolean enable])
    Initializes the interactive debugger.
    
boolean enabled
    True if the interactive debugging is enabled.
    
void Debug.pause (...)
    Pauses the plugin and displays the debugger window.
    
void pauseIf (boolean condition, ...)
    Conditionally pauses the plugin and displays the debugger window.
    
function showErrors (function)
    Wraps a function with an error handler that invokes the debugger.

function wrappedFunc, string error 
breakFunc (function or string f, string expr)
    Sets a breakpoint on a function's entry and return.
    
function originalFunc, string error
unbreakFunc (function or string f)
    Removes a function breakpoint.

void invokeEditor (string filename, int lineNumber) 
    Invokes the configured text editor on a file / line.
    
void showOptionsWindow ()    
    Displays the debugger's Options window for setting options.
    
string pp (value, int indent, int maxChars, int maxLines) 
    Pretty prints an arbitrary Lua value.
    
LrLogger log
    A log file that outputs to "debug.log" in the plugin directory.
    
void setLogFilename (string)    
    Changes the filename of "log".
    
void logn (...)    
    Writes the arguments to "log", converted to strings and space-separated.
    
void lognpp (...)    
    Pretty prints the arguments to "log", separated by spaces or newlines.
    
void stackTrace ()
    Writes a stack trace to "log".
    
function profileFunc (function func, string funcName)    
    Enables elapsed-time profiling of a function.

string profileResults ()
    Returns the current profiling results, nicely formatted.
------------------------------------------------------------------------------]]

local Debug = {}

local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrColor = import 'LrColor'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrFunctionContext = import 'LrFunctionContext'
local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local LrPrefs = import 'LrPrefs'
local LrShell = import 'LrShell'
local LrStringUtils = import 'LrStringUtils'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'

local Require 
pcall (function () Require = require 'Require' end)

local prefs = LrPrefs.prefsForPlugin ()
local bind = LrView.bind
local f = LrView.osFactory()

    -- Forward references
local clearAllBreaks, clearNamedBreaks, defaultTextEditor, downPush, editPush,
    evalPush, findFile, formatStackInfo, getCallExprs, getFuncInfo,
    getStackInfo, goUntilErrorPush, goUntilReturnPush, invokeEditorStackInfo,
    lineCount, logFilename, logPush, namedBreaks, parseParams, breaksPush,
    showErrors, showWindow, sourceLines, upPush

local ThisFilename = "Debug.lua"
    --[[ The name of this source file, used for filtering out stack frames of
    this module. We try to set it automatically but default to this value. ]]

Debug.DebugTerminatedError = "Debug terminated plugin execution"
    --[[ Error thrown when user hits Stop button.  Recognized by the
    function wrapper handling Debug.breakFunc. ]]
    
local breakCallReturn = true
    --[[ True if wrapped functions should break at calls and returns and show
    the debugger window.  Implements the "Go until return" and "Go until error"
    commands. ]]

local funcFuncInfo = {}
    --[[ A table representing all the functions with current breaks. All broken
    functions have an entry keyed by the wrapped function. In addition,
    functions with globally accessible names (myGlobalFunc or
    MyNamespace.myFunc) are also keyed by the globally accessible name. The
    value of an entry is a FuncInfo table:
    
    func (function): 
        The original unwrapped function.
    wrappedFunc (function):
        The function wrapped with the calls to Debug.
    conditionalExpr (string):
        The conditional break expression, or nil if not supplied.
    moduleName (string):
    name (string):
        For globally accessible named functions, non-nil; for local functions,
        nil. _G [moduleName][name] == func or wrappedFunc.  For functions in the
        global namespace, moduleName == "_G".
    funcName
        The fully qualified name (module.myFunc, myGlobalFunc, or myLocalFunc).
        This is always is non-nil, even for local functions.
    filename (string):.
        The source filename (without directory), non-nil.
    lineNumber (string):
        Line number within the file filename, non-nil.     
    parameters (array of string):
        The parameter names, parsed from the source file, or nil if they 
        couldn't be parsed. ]]
    
local path
    --[[ array of string: List of directories to search for the sources for
    files. ]]

local filenameLines = {}
    --[[ Mapping from filename to the file's contents, represented as an array
    of strings, one string per line. This is not updated if the user 
    changes the file during a debugging session. ]]

local Newline = WIN_ENV and "\r\n" or "\n"
    --[[ A  platform-indepent newline. Unfortunately, some controls (e.g.
    edit_field) need to have the old-fashioned \r\n supplied in strings to
    display newlines properly on Windows. ]]

--[[----------------------------------------------------------------------------
public namespace 
init ([boolean enable])

Re-initializes the interactive debugger, discarding breaks and cached source
lines.

If "enable" is true or if it is nil and the plugin directory ends with
".lrdevplugin", then debugging is enabled.  Otherwise, debugging is disabled,
and calls to Debug.pause, Debug.pauseIf, Debug.breakFunc, and Debug.unbreakFunc
will be ignored. 

This lets you leave calls to the debugging functions in your code and just
enable or disable the debugger via the call to Debug.init.  Further, calling
Debug.init() with no parameters automatically enables debugging only when
running from a ".lrdevplugin" directory; in released code (".lrplugin"),
debugging will be disabled.

When Debug is loaded, it does an implicit Debug.init().  That is, debugging
will be enabled if the plugin directory ends with ".lrdevplugin", disabled
otherwise.

Returns the Debug module.
------------------------------------------------------------------------------]]

function Debug.init (enable)
    if enable == nil then enable = _PLUGIN.path:sub (-12) == ".lrdevplugin" end
    
    prefs.debugInvokeEditor = 
        (prefs.debugInvokeEditor == nil) and true or prefs.debugInvokeEditor
    prefs.debugEditorCommandLine = 
        (prefs.debugEditorCommandLine ~= nil and 
         prefs.debugEditorCommandLine ~= "") and
        prefs.debugEditorCommandLine or defaultTextEditor ()
    prefs.debugLogWindow = (prefs.debugLogWindow == nil) and true or 
        prefs.debugLogWindow
    
    local function f () end
    local info = debug.getinfo (f)
    if info and info.source and info.source:sub (-4) == ".lua" then
        ThisFilename = info.source       
        end

    breakCallReturn = true
    clearAllBreaks ()
    filenameLines = {}

    Debug.enabled = enable
    
    return Debug
    end

--[[----------------------------------------------------------------------------
private string
defaultTextEditor ()

Returns the default text-editor command line for displaying source:

- On Windows, TextPad if it exists, Notepad otherwise.

- On Mac, TextEdit

------------------------------------------------------------------------------]]

local TextPad32 = [[C:\Program Files\TextPad 5\TextPad.exe]]
local TextPad64 = [[C:\Program Files (x86)\TextPad 5\TextPad.exe]]
local TextPadCommand = '"%s" "{file}"({line})'
local EditPad32 = [[C:\Program Files (x86)\JGSoft\EditPadPro6\EditPadPro.exe]]
local EditPad64 = [[C:\Program Files\JGSoft\EditPadPro6\EditPadPro.exe]]
local EditPadCommand = '"%s" /l{line} "{file}"'

function defaultTextEditor ()
    if MAC_ENV then 
        return 'open "{file}" -a TextEdit' 
    elseif LrFileUtils.exists (TextPad64) then 
        return string.format (TextPadCommand, TextPad64)
    elseif LrFileUtils.exists (TextPad32) then 
        return string.format (TextPadCommand, TextPad32)
    elseif LrFileUtils.exists (EditPad32) then 
        return string.format (EditPadCommand, EditPad32)
    elseif LrFileUtils.exists (EditPad64) then 
        return string.format (EditPadCommand, EditPad64)
    else
        return 'notepad "{file}"'
        end
    end

--[[----------------------------------------------------------------------------
public boolean enabled

True if debugging has been enabled by Debug.init, false otherwise.
------------------------------------------------------------------------------]]

Debug.enabled = false

--[[----------------------------------------------------------------------------
public void 
pause (...)

Pauses the plugin and displays the debugger window, showing all the argument
values in the Arguments pane.  Does nothing if debugging was disabled by
Debug.init.  Returns the argument values.
------------------------------------------------------------------------------]]

function Debug.pause (...)
    if not Debug.enabled then return end
    if not breakCallReturn then return end
    local values = {...}
    values.n = select("#", ...)
    showWindow ("paused", getCallExprs (3), values, nil, nil, getStackInfo (3))
    return unpack (values)
    end


--[[----------------------------------------------------------------------------
public void 
pauseIf (boolean condition, ...)

If "condition" is true, pauses the plugin and displays the debugger window,
showing all the argument values in the Arguments pane.

Does nothing if debugging was disabled by Debug.init.
------------------------------------------------------------------------------]]

function Debug.pauseIf (condition, ...)
    if not Debug.enabled then return end
    if not (breakCallReturn and condition) then return end
    local values = {}
    values [1] = condition
    for i = 1, select ("#", ...) do values [i + 1] = select (i, ...) end
    values.n = select ("#", ...) + 1
    showWindow ("paused", getCallExprs (3), values, nil, nil, getStackInfo (3))
    end


--[[----------------------------------------------------------------------------
private array of string 
getCallExprs (int level)

Returns the parsed expressions from the source of a call to Debug.pause or
Debug.pauseIf at the given level in the debug.getinfo() call stack.  E.g. if the
source line is "Debug.pause (x + 5, f (x, y))" returns {"x + 5", "f (x, y)"}.
------------------------------------------------------------------------------]]

function getCallExprs (level)
    local info = debug.getinfo (level)
    if not info then return nil end
    local lines = sourceLines (info.source, info.currentline, 10)
    local params = lines:match ("^.-Debug.pause[^%(]*(%(.*)$")
    if not params then return nil end
    return parseParams (params)
    end


--[[----------------------------------------------------------------------------
public function 
showErrors (function)

Returns a function wrapped around "func" such that if any errors occur from
calling "func", the debugger window is displayed.  If debugging was disabled by
Debug.init, then instead of displaying the debugger window, the standard
Lightroom error dialog is displayed.
------------------------------------------------------------------------------]]

function Debug.showErrors (func)
    if type (func) ~= "function" then 
        error ("Debug.showErrors argument must be a function", 2)
        end

    if not Debug.enabled then return showErrors (func) end
    
    local fi = getFuncInfo (func)
    if not fi then return showErrors (func) end
    
    return function (...)
        local args = {...}
        args.n = select("#", ...)
        
        local function onReturn (success, ...)
            if not success then 
                local err = select (1, ...)
                if err ~= Debug.DebugTerminatedError then 
                    showWindow ("failed", fi.parameters, args, nil, err, 
                        getStackInfo (4, fi.funcName, fi.filename, 
                                      fi.lineNumber, err))
                    end
                error (err, 0)
            else
                return ...
                end
            end 
        
        if LrTasks.canYield () then
            return onReturn (LrTasks.pcall (func, ...))
        else
            return onReturn (pcall (func, ...))
            end
        end           
    end
    

--[[----------------------------------------------------------------------------
private func showErrors (func)

Returns a function wrapped around "func" such that if any errors occur from
calling "func", the standard Lightroom error dialog is displayed.  By default,
Lightroom doesn't show an error dialog for callbacks from LrView controls or for
tasks created by LrTasks.
------------------------------------------------------------------------------]]

function showErrors (func)
    return function (...)
        return LrFunctionContext.callWithContext("wrapped", 
            function (context)
                LrDialogs.attachErrorDialogToFunctionContext (context)
                return func (unpack (arg))
                end)
        end 
    end


--[[----------------------------------------------------------------------------
public function wrappedFunc, string error
breakFunc (function or string f, string expr)

Sets a breakpoint on "f", which should either be a function object or a string
that's a globally accessible name of a function.  The debugger window is
displayed when the function is called and when it returns. Examples:

    Debug.breakFunc (MyModule.myFunc)
    Debug.breakFunc ("MyModule.myFunc")
    
To break a local function whose name is not globally accessible, do:

    myLocalFunc = Debug.breakFunc (myLocalFunc)
    
Any previous breakpoint on "f" is removed.

If "expr" is non-nil, it is interpreted as a Lua expression referring to
globally accessible names and parameter names of the function.  The expression
is evaluated each call to the function, and the debugger window is shown only
if the result is true.

On success, returns a new function wrapping the original function; the new
function is the one containing the "breakpoint" (the invocations of the debugger
window).  On failure, returns nil and a second result which is the error
message.

Does nothing if debugging was disabled by Debug.init.
------------------------------------------------------------------------------]]

function Debug.breakFunc (f, expr)
    if not Debug.enabled then return f end
    
    Debug.unbreakFunc (f)    
    local fi = getFuncInfo (f)
    if not fi then return nil, "Not a globally accessible function" end
    
    local func = fi.func
    local conditionFunc = function () return true end

    if expr == "" then expr = nil end
    fi.expr = expr
    if expr and expr ~= "" then
        local funcStr = "return function (" .. 
            table.concat (fi.parameters, ", ") .. ") " .. 
            "return " .. expr .. " end"
        local chunk, e = loadstring (funcStr)
        if not chunk then return nil, e end
        conditionFunc = chunk ()
        end

    local wrappedFunc = function (...)
        if not conditionFunc (...) then return func (...) end
    
        local args = {...}
        args.n = select("#", ...)

        local showResult
        if breakCallReturn then
            showResult = showWindow ("called", fi.parameters, args, nil, nil, 
                getStackInfo (3, fi.funcName, fi.filename, fi.lineNumber))
            end

        local function onReturn (success, ...)
            if not success then
                breakCallReturn = true
                local err = select (1, ...)
                if err ~= Debug.DebugTerminatedError then 
                    showWindow ("failed", fi.parameters, args, nil, err, 
                        getStackInfo (4, fi.funcName, fi.filename, 
                                      fi.lineNumber, err))
                    end
                error (err, 0)
                
            else
                if breakCallReturn or showResult == "goUntilReturn" then
                    breakCallReturn = true
                    local results = {...}
                    results.n = select("#", ...)
                    showWindow ("returned", fi.parameters, args, results, nil,
                        getStackInfo (4, fi.funcName, fi.filename, 
                                      fi.lineNumber))
                    end
                return ...
                end
            end

        if LrTasks.canYield () then
            if prefs.debugTrappingErrors then
                return onReturn (LrTasks.pcall (func, ...))
            else
                return onReturn (true, func (...))
                end
        else
            return onReturn (pcall (func, ...))
            end
        end

    fi.wrappedFunc = wrappedFunc
    if fi.moduleName then 
        rawset (rawget (_G, fi.moduleName), fi.name, wrappedFunc)
        funcFuncInfo [fi.funcName] = fi 
        end
    funcFuncInfo [wrappedFunc] = fi

    return wrappedFunc
    end

--[[----------------------------------------------------------------------------
public function originalFunc, string error
unbreakFunc (function or string f)

Removes any breakpoint on "f", which can have the same values as in
Debug.breakFunc().  To unbreak a function named by a globally accessible name:

    Debug.unbreakFunc ("MyModule.myFunc")
    Debug.unbreakFunc (MyModule.myFunc)
    
To unbreak a local function:

    myLocalFunc = Debug.unbreakFunc (myLocalFunc)
    
On success, returns the original (unwrapped) function; On failure, returns nil
and a second result which is the error message.

Does nothing if debugging was disabled by Debug.init.
------------------------------------------------------------------------------]]

function Debug.unbreakFunc (f)
    if not Debug.enabled then return f end
    
    local fi = funcFuncInfo [f]
    if not fi then return nil, "Not a function with a break" end
    if fi.moduleName then
        rawset (rawget (_G, fi.moduleName), fi.name, fi.func)
        funcFuncInfo [fi.funcName] = nil
        end
    funcFuncInfo [fi.wrappedFunc] = nil
    return fi.func
    end    


--[[----------------------------------------------------------------------------
private array of FuncInfo
namedBreaks ()

Returns an array of all the FuncInfo records representing breaks of functions
with globally accessible names (all breaks excluding those of local functions).
------------------------------------------------------------------------------]]

function namedBreaks ()
    local funcInfos = {}
    for f, fi in pairs (funcFuncInfo) do
        if type (f) == "string" then 
            table.insert (funcInfos, fi)
            end
        end
    return funcInfos
    end    


--[[----------------------------------------------------------------------------
private void
clearAllBreaks ()

Removes all function breaks by calling Debug.unbreakFunc (f) on each
broken function "f".
------------------------------------------------------------------------------]]


function clearAllBreaks ()
    for f, fi in pairs (table.shallowcopy (funcFuncInfo)) do
        Debug.unbreakFunc (f)
        end
    end    


--[[----------------------------------------------------------------------------
private void
clearNamedBreaks ()

Removes all function breaks of functions with globally accessible names (all
breaks excluding those of local functions) by calling Debug.unbreakFunc (f) on
each such "f".
------------------------------------------------------------------------------]]

function clearNamedBreaks ()
    for f, fi in pairs (table.shallowcopy (funcFuncInfo)) do
        if type (f) == "string" then 
            Debug.unbreakFunc (f)
            end
        end
    end    


--[[----------------------------------------------------------------------------
private FuncInfo 
getFuncInfo (function or string f)

Creates a FuncInfo record for "f", which has the same interpretation as in
Debug.breakFunc(). (See above for the specification of a FuncInfo record.)  The
information is obtained via debug.getinfo() and parsing the source for the first
lines of the function definition. Returns nil if "f" does not specify a function
or its source definition cannot be accessed or parsed.
------------------------------------------------------------------------------]]

function getFuncInfo (f)
    local func, moduleName, name, funcName, info, m, n, params
    
    if type (f) == "string" then
        moduleName, name = f:match ("^([^%.]-)[%.]?([^%.]+)$")
        if not moduleName then return nil end
        if moduleName == "" then 
            moduleName = "_G" 
            funcName = name
        else
            funcName = moduleName .. "." .. name
            end
        if type (rawget (_G, moduleName)) ~= "table" then return nil end
        func = rawget (rawget (_G, moduleName), name)
        if type (func) ~= "function" then return nil end
        info = debug.getinfo (func)
        if not info then return nil end
        local line = sourceLines (info.source, info.linedefined, 10)
        m, n, params = 
            line:match ("^.-function%s%s-([^%.%s]-)[%.]?([^%.%s%(]+)%s-(%(.*)$")

    elseif type (f) == "function" then
        func = f
        info = debug.getinfo (func)
        if not info then return nil end
        local line = sourceLines (info.source, info.linedefined, 10)
        moduleName, name, params =     
            line:match ("^.-function%s-([^%.%s]-)[%.]?([^%.%s%(]-)%s*(%(.*)$")
        if not moduleName then moduleName, name, params = "", "", "" end
        if moduleName == "" and name == "" then
            funcName = "(anonymous)"
            moduleName, name = nil
        else
            if moduleName == "" then 
                moduleName = "_G"
                funcName = name
            else
                funcName = moduleName .. "." .. name
                end
            if type (rawget (_G, moduleName)) ~= "table" or 
               func ~= rawget (rawget (_G, moduleName), name)
            then
                moduleName, name = nil, nil
                end
            end
    else
        return nil
        end
        
    return {func = func, moduleName = moduleName, name = name, 
        funcName = funcName, filename = info.source, 
        lineNumber = info.linedefined, parameters = parseParams (params)}
    end
    

--[[----------------------------------------------------------------------------
private array of string
parseParams (string s)

The string "s" should be the parameter specification of a function definition
or the argument list to a function call, e.g. 

    (x, y, z)
    (x + 5, f [g (x, y] .. "Hello world", z)
    
Parses the list of parameters and returns them as an array of strings. Lua
syntax is respected, and comments and surrounding whitespace are stripped out.
------------------------------------------------------------------------------]]

local IsWhiteSpace = {[" "] = true, ["\t"] = true, ["\r"] = true, ["\n"] = true}

function parseParams (s)
    local parameters = {}
    local parens = 0
    local done = false
    local c
    local i = 1
    while i <= #s and not done do
        local param = ""
        while i <= #s do
            c = s:sub (i, i); i = i + 1
            if c == "(" then
                if parens > 0 then param = param .. c end
                parens = parens + 1
            elseif c == ")" then 
                parens = parens - 1
                if parens == 0 then done = true; break end
                param = param .. c
            elseif c == "," and parens == 1 then
                break
            elseif c == "-" and s:find ("^%-%[=*%[", i) then
                local close = "]" .. s:match ("^%-%[(=*)%[", i) .. "]"
                i = i + 3
                while i <= #s do
                    if s:sub (i, i + #close - 1) == close then 
                        i = i + #close; 
                        break 
                        end
                    i = i + 1
                    end
            elseif c == "-" and s:sub (i, i) == "-" then
                i = i + 1
                while i <= #s do
                    c = s:sub (i, i); i = i + 1
                    if c == "\n" then break end
                    end
            elseif c == "[" and s:find ("^=*%[", i) then
                param = param .. c
                local close = "]" .. s:match ("^(=*)%[", i) .. "]"
                while i <= #s do
                    if s:sub (i, i + #close - 1) == close then 
                        param = param .. close
                        i = i + #close; 
                        break 
                        end
                    param = param .. s:sub (i, i)
                    i = i + 1
                    end
            elseif c == '"' then
                param = param .. c
                while i <= #s do
                    c = s:sub (i, i); i = i + 1
                    param = param .. c
                    if c == "\\" then
                        c = s:sub (i, i); i = i + 1
                        param = param .. c
                    elseif c == '"' then
                        break
                        end
                    end
            elseif c == "\r" or c == "\n" then

            else 
                param = param .. c
                end
            end
            
        local l = 1
        while l <= #param and IsWhiteSpace [param:sub (l, l)] do l = l + 1 end
        local r = #param
        while r >= 1 and IsWhiteSpace [param:sub (r, r)] do r = r - 1 end
        param = param:sub (l, r)

        if param ~= "" then 
            table.insert (parameters, param) 
            end
        end
        
    return parameters
    end

--[[----------------------------------------------------------------------------
private array of StackInfo
getStackInfo (level, funcName, filename, lineNumber, err)

Returns an array of StackInfo records representing the filtered call stack as
displayed to the user.  A StackInfo record represents a stack frame and has
these fields:

funcName (string): 
    The name of the function; "error" if this stack frame represents an error;
    nil if Lua doesn't know the name of the function.

filename (string): 
lineNumber (int): 
    The source file and line within the file containing the function call.

If "err" is non-nil, it is an error message trapped from a call to error(), and
a StackInfo record is pushed on top of the stack with "funcName" = "error" and
'filename" and "lineNumber" set to values parsed from the error string.

If "funcName" is non-nil, then a StackInfo record is pushed on top of the
stack with "funcName", "filename", and "lineNumber".

Stack frames returned from debug.getinfo() whose source is this file are
filtered out, as are pcall() frames called by such frames.
------------------------------------------------------------------------------]]

function getStackInfo (level, funcName, filename, lineNumber, err)
    local stackInfo = {}
    
    if err then
            --[[ Error messages apparently can have two formats:
            compiled by require: [string "filename.lua":line] error
            compiled by loadfile: full-file-path:line: error ]]
        local file, line, line2
        file, line = err:match ('%[string "([^"]+)"%]:(%d+):')
        if not file then file, line = err:match ('([^\\/]+):(%d+):') end

        if file then line2 = err:match ("at line (%d+)%)") end 
        line = line2 or line
        table.insert (stackInfo, {funcName = "error", filename = file or "",
            lineNumber = tonumber (line or "0")})
        end
    
    if funcName then 
        table.insert (stackInfo, {funcName = funcName, filename = filename,
            lineNumber = lineNumber})
        end
        
    local i = level
    while true do
        local info = debug.getinfo (i)
        if not info then break end
        if info.source == ThisFilename then
            if #stackInfo > 0 and stackInfo [#stackInfo].funcName == "pcall"
               and stackInfo [#stackInfo].filename == "=[C]" 
            then
                stackInfo [#stackInfo] = nil
                end
        else
            table.insert (stackInfo, {funcName = info.name,
                filename = info.source, lineNumber = info.currentline})
            end
        i = i + 1
        end

    return stackInfo
    end


--[[----------------------------------------------------------------------------
private string
formatStackInfo (si)

Formats a StackInfo record "si" for display to the user.
------------------------------------------------------------------------------]]

function formatStackInfo (si)
    if not si then return "" end
    return string.format ("%s[%s %s] %s", 
        (si.funcName and si.funcName ~= "") and si.funcName .. " " or "", 
        si.filename, si.lineNumber, sourceLines (si.filename, si.lineNumber))
    end
    

--[[----------------------------------------------------------------------------
private string
sourceLines (string filename, int lineNumber [, int n])

Returns up to "n" source lines from file "filename", starting at line number
"lineNumber".  "filename" is resolved via findFile().  "n" defaults to 1.
------------------------------------------------------------------------------]]

function sourceLines (filename, lineNumber, n)
    if not n then n = 1 end
    if filename:sub (1, 1) == "=" then
        return ""
        end
        
    if not filenameLines [filename] then
        local lines = {}
        local f = io.open (findFile (filename) or filename, "r")
        if f then 
            while true do
                local line = f:read ("*l")
                if not line then break end
                table.insert (lines, line)
                end
            f:close ()
            end
        filenameLines [filename] = lines
        end
                
    local lines = ""
    for i = lineNumber, lineNumber + n - 1 do
        if i > lineNumber then lines = lines .. Newline end
        lines = lines .. (filenameLines [filename][i] or "")
        end
    return lines
    end
    
    
--[[----------------------------------------------------------------------------
private void
invokeEditorStackInfo (StackInfo stackInfo)

If the user has configured a text editor, and if StackInfo has a non-nile
filename with a line number > 0, the editor is invoked on that
filename/linenumber.  Any failures are silently ignored.
------------------------------------------------------------------------------]]

function invokeEditorStackInfo (stackInfo)
    if not stackInfo then return end
    if not (stackInfo.filename and stackInfo.lineNumber) then return end
    if stackInfo.lineNumber < 1 then return end
    Debug.invokeEditor (stackInfo.filename, stackInfo.lineNumber)
    end
    
    
--[[----------------------------------------------------------------------------
public void
invokeEditor (string filename, int lineNumber)  

If the user has configured a text editor, it is invoked on "filename" /
"lineNumber".  If "filename" is a relative file, it is resolved to a qualified
file path using findFile(). Any failures are silently ignored.
------------------------------------------------------------------------------]]

function Debug.invokeEditor (filename, lineNumber) 
    if not prefs.debugEditorCommandLine then return end
    if not lineNumber then lineNumber = 1 end
    filename = findFile (filename) or filename
    
    LrFunctionContext.postAsyncTaskWithContext ("", function (context)
        LrDialogs.attachErrorDialogToFunctionContext (context)
        local cmd = prefs.debugEditorCommandLine:gsub ("{file}", filename)
        cmd = cmd:gsub ("{line}", lineNumber)
        if WIN_ENV then cmd = '"' .. cmd .. '"' end
        LrTasks.execute (cmd)
        end)
    end
    

--[[----------------------------------------------------------------------------
public table
path (...)

Sets a search path of directories to search for file sources. "." is always
implicitly included at the front of the path.  Each argument should be a string
containing a directory path, and each path can be absolute or relative to the
directory _PLUGIN.path.  Returns the Debug module.
------------------------------------------------------------------------------]]

function Debug.path (...)
    path = {"."}
    for i = 1, select ("#", ...) do 
        local dir = select (i, ...)
        table.insert (path, dir)
        end
    return Debug
    end


--[[----------------------------------------------------------------------------
private string 
findFile (string filename)

Returns a fully qualified file path for the .lua source file "filename". If
"filename" is absolute, it is returned.  If a directory path has been set with
Debug.path, the file is searched for there; otherwise, if Require has been
loaded, then Require.findFile is called to find the file; otherwise,
_PLUGIN.path is searched.  Returns nil if the file can't be found.

If the first character of "filename" is "@", it is ignored.  (dofile () appears
to put it there -- not sure why.)
------------------------------------------------------------------------------]]

function findFile (filename)
    if filename:sub (1, 1) == "@" then filename = filename:sub (2) end
    if not LrPathUtils.isRelative (filename) then return filename end
    if not path and Require then return Require.findFile (filename) end
    
    for i, dir in ipairs (path or {_PLUGIN.path}) do
        if LrPathUtils.isRelative (dir) then
            dir = LrPathUtils.child (_PLUGIN.path, dir)
            end
        local filePath = LrPathUtils.child (dir, filename)
        if LrFileUtils.exists (filePath) then return filePath end
        end
    return nil
    end

--[[----------------------------------------------------------------------------
private string 
showWindow (string what, array of string names, array args, 
    array results, string err, array of StackInfo stack)

Shows the debugger window.  Parameters:

what: "paused" for calls from Debug.pause(), "called" for entry to broken
functions, "returned" for returns from broken functions, or "failed" for trapped
error returns from broken functions.

names: The array of strings representing the parameter names (for function
calls) or expressions (for calls to Debug.pause()).

args: The array of values passed to the function or Debug.pause (). "args.n"
should be the number of argument values, including nils.

results: The array of values returned by the broken function (non-nil only for
what == "called"). "results.nil" should be the number of argument values,
including nil.

err: If "failed", then the error string of the trapped error.

stack: The array of StackInfo representing the (filtered) call stack.

Returns one of the following strings:

"go": The user clicked the Go button. "goUntilReturn": The user clicked the Go
Until Return button. "goUntilError": The user clicked the Go Until Error button.

If the user clicked Stop, the error string DebugTerminatedError is raised.
------------------------------------------------------------------------------]]

local EvalHelpText = [[One or more expressions separated by commas, or "."
followed by one or more statements]]
EvalHelpText = EvalHelpText:gsub ("%c", " ")

function showWindow (what, names, args, results, err, stack)
return LrFunctionContext.callWithContext ("", function (context)
    local prop = LrBinding.makePropertyTable (context)

    if not names then names = {} end
    if not args then args = {}; args.n = 0 end
    if not results then results = {}; results.n = 0 end

    prop.what = what
    prop.names = names
    prop.args = args
    prop.results = results
    prop.stack = stack
    
    if prefs.debugInvokeEditor and prefs.debugEditorCommandLine then
        invokeEditorStackInfo (stack [1])
        end

        --[[ Format the Stack and Edit fields ]]
    local s = ""
    for i, si in ipairs (stack) do s = s .. formatStackInfo (si) .. Newline end    
    prop.stackListing = s        
    prop.edit = formatStackInfo (stack [1])
    prop.editIndex = 1

        --[[ Construct single array of values, varNames, and displayNames.
        varNames are the variables to be used by Eval.  displayNames are the
        names to be shown to the user. ]]
    local values = {}
    local varNames = {}
    local displayNames = {}
    local j = 1
    local n = 0

    local nArgs
    if names [#names] == "..." and #names > args.n then
        nArgs = #names - 1
    else
        nArgs = math.max (#names, args.n)
        end

    for i = 1, nArgs do
        values [i] = args [i]
        if what == "paused" and 
           not (names [i] and names [i]:match ("^[%a_][%w_]-$"))
        then
            varNames [i] = "_" .. j; j = j + 1
            displayNames [i] = varNames [#varNames] ..
                (names [i] and " (" .. names [i] .. ")" or "")
        elseif names [i] and names [i] ~= "..." then
            varNames [i] = names [i]
            displayNames [i] = names [i]
        else
            varNames [i] = "_" .. j; j = j + 1
            displayNames [i] = varNames [#varNames]
            end
        end
                
    j = 1
    for i = 1, results.n do
        values [nArgs + i] = results [i]
        varNames [nArgs + i] = "_r" .. j; j = j + 1
        displayNames [nArgs + i] = varNames [#varNames]
        end
        
    prop.values = values
    prop.varNames = varNames
    prop.displayNames = displayNames

        --[[ Construct Arguments and results field. ]]
    s = ""
    for i = 1, #displayNames do
        if i == nArgs + 1 then s = s .. "=>" .. Newline end
        s = s .. displayNames [i] .. " = " .. Debug.pp (values [i], 0, 75) 
            .. Newline
        end
    prop.arguments = s

        --[[ Display the main dialog. ]]
    local title, argsTitle
    if what == "paused" then
        title = "Paused"
        argsTitle = "Arguments:"
    elseif what == "called" then
        title = stack [1].funcName .. " called"
        argsTitle = "Arguments:"
    elseif what == "returned" then
        title = stack [1].funcName .. " returned"
        argsTitle = "Arguments and results:"
    elseif what == "failed" then
        title = stack [2].funcName .. " failed"
        argsTitle = "Arguments:"
        end
        
    if prefs.debugLogWindow then
        Debug.log:trace (("\n-----" .. title .. "-----\n" ..
            (what == "failed" and (err .. "\n") or "") ..
            "-----Stack-----:\n" .. prop.stackListing ..
            "-----" .. argsTitle .. "-----" .. "\n" .. 
            prop.arguments):gsub ("\r\n", "\n") .. "")
        end        
    
    prop.evaluate = prefs.debugEvaluate
    prop.evalInTask = prop.evalInTask or false
    
    local function actionWrap (func)
        return showErrors (function (button) func (button, prop) end)
        end

    local result = LrDialogs.presentModalDialog {
        title = "Debug > " .. title, resizable = true, actionVerb = "Go",
        cancelVerb = "Stop", save_frame = "debugWindowPosition", 
        contents = f:column {
        bind_to_object = prop, fill = 1,
        spacing = f:label_spacing (),
        
        f:static_text {title = title .. ":", font = "<system/bold>", 
            text_color = what == "failed" and LrColor ("red") or nil},
        what ~= "failed" and LrView.kIgnoredView or
            f:edit_field {height_in_lines = 3, wrap = true, immediate = true,
                value = err:gsub ("\n", Newline), fill_horizontal = 1}, 
        f:edit_field {height_in_lines = 5, fill = 1, immediate = true, 
            value = bind ("stackListing")},
        f:row {
            f:push_button {title = "Edit", action = actionWrap (editPush)},
            f:edit_field {width_in_chars = 20, fill = 1, immediate = true, 
                          value = bind ("edit")},
            f:push_button {title = "^", action = actionWrap (upPush)},
            f:push_button {title = "v", action = actionWrap (downPush)}},
        f:static_text {title = argsTitle, font = "<system/bold>"},
        f:edit_field {height_in_lines = 5, fill = 1, immediate = true,
            value = bind ("arguments")},
        f:row {
            f:static_text {title = "Evaluate:", font = "<system/bold>"},
            f:static_text {title = EvalHelpText, fill = 1, wrap = true, 
                width_in_chars = 10, height_in_lines = 2, 
                font = "<system/small>"}},
        f:edit_field {height_in_lines = 2, fill_horizontal = 1, 
            immediate = true, value = bind ("evaluate")},
        f:row {
            f:push_button {title = "Eval", action = actionWrap (evalPush)},
            f:checkbox {title = "Evaluate in a new task", 
                value = bind ("evalInTask")}},
        f:static_text {title = "Result:", font = "<system/bold>"},
        f:edit_field {height_in_lines = 5, fill = 1, immediate = true, 
            value = bind ("result")},
        f:row {
            f:push_button {title = "Function breaks", 
                action = actionWrap (breaksPush)},
            f:push_button {title = "Log", action = actionWrap (logPush)},
            f:push_button {title = "Options", 
                action = showErrors (Debug.showOptionsWindow)}},
        f:row {
            f:static_text {title = "Window is resizable", 
                font = "<system/small>"},
            f:push_button {title = "Go until error", place_horizontal = 1,
                action = actionWrap (goUntilErrorPush)},
            f:push_button {title = "Go until return", 
                action = actionWrap (goUntilReturnPush), 
                enabled = what == "called"}}}}

    prefs.debugEvaluate = prop.evaluate

    if result == "cancel" then error (Debug.DebugTerminatedError, 0) end

    return result == "ok" and "go" or result 
    end)  
    end


--[[----------------------------------------------------------------------------
public void 
showOptionsWindow ()

Displays the Debugger Options window.
------------------------------------------------------------------------------]]

local EditorText = [[Command line for a text editor invoked by Debug to display
a source location; the tokens {file} and {line} will get replaced by the full
file path and line number of the file Debug is displaying. Be sure to put
double quotes around the program path and the {file} token.]] 
EditorText = EditorText:gsub ("%c", " ")

local InvokeText = [[Automatically invoke the editor whenever the Debug window
opens]]
InvokeText = InvokeText:gsub ("%c", " ")

local ErrorsText = [[Due to limitations of the Lightroom SDK, with tasks other
than the main task, you can trap errors in Debug or show the full call stack,
but not both:]]
ErrorsText = ErrorsText:gsub ("%c", " ")

local LogText = [[Log everything shown in the Debug window to the debug log
file, which can be viewed with the Log button:]]
LogText = LogText:gsub ("%c", " ")

function Debug.showOptionsWindow ()
return LrFunctionContext.callWithContext ("", function (context)

    local prop = LrBinding.makePropertyTable (context)
    prop.editorCommandLine = prefs.debugEditorCommandLine
    prop.invokeEditor = prefs.debugInvokeEditor
    prop.trappingErrors = not not prefs.debugTrappingErrors 
    prop.logWindow = prefs.debugLogWindow
    
    local result = LrDialogs.presentModalDialog {
        title = "Debug > Options", contents = f:column {
        bind_to_object = prop, 
        spacing = f:control_spacing (),
        
        f:static_text {title = EditorText, width_in_chars = 50, wrap = true,
            height_in_lines = 3},
        f:edit_field {value = bind ("editorCommandLine"), immediate = true,
            width_in_chars = 50},
        f:checkbox {value = bind ("invokeEditor"), title = InvokeText,
            width_in_chars = 35, wrap = true},
        f:separator {fill_horizontal = 1},
        f:static_text {title = ErrorsText, wrap = true, height_in_lines = 2,
            width_in_chars = 50},
        f:radio_button {title = "Trap errors in Debug",
            value = bind ("trappingErrors"), checked_value = true},
        f:radio_button {title = "Show the full call stack",
            value = bind ("trappingErrors"), checked_value = false},
        f:separator {fill_horizontal = 1},
        f:static_text {title = LogText, wrap = true, height_in_lines = 2, 
            width_in_chars = 50},
        f:checkbox {title = "Log Debug window to debug log", 
            value = bind ("logWindow")}}}
        
    if result == "cancel" then return end

    prefs.debugEditorCommandLine = prop.editorCommandLine
    prefs.debugInvokeEditor = prop.invokeEditor
    prefs.debugTrappingErrors = prop.trappingErrors
    prefs.debugLogWindow = prop.logWindow
    end)
    end
 

--[[----------------------------------------------------------------------------
private void
editPush (button, mainProp)

Implements the Edit button of the debugger window.  "mainProp" is the
property table for that window.
------------------------------------------------------------------------------]]

function editPush (button, mainProp)
    invokeEditorStackInfo (mainProp.stack [mainProp.editIndex])
    end


--[[----------------------------------------------------------------------------
private void
upPush (button, prop)

Implements the ^ (Up) button of the debugger window.  "prop" is the
property table for that window.
------------------------------------------------------------------------------]]

function upPush (button, prop)
    local i = prop.editIndex - 1
    while true do
        if i < 1 then return end
        if prop.stack [i].lineNumber > 0 then break end
        i = i - 1
        end
    prop.editIndex = i
    prop.edit = formatStackInfo (prop.stack [prop.editIndex])
    if prefs.debugInvokeEditor and prefs.debugEditorCommandLine then
        invokeEditorStackInfo (prop.stack [prop.editIndex])
        end
    end


--[[----------------------------------------------------------------------------
private void
downPush (button, prop)

Implements the V (Down) button of the debugger window.  "prop" is the
property table for that window.
------------------------------------------------------------------------------]]

function downPush (button, prop)
    local i = prop.editIndex + 1
    while true do
        if i > #prop.stack then return end
        if prop.stack [i].lineNumber > 0 then break end
        i = i + 1
        end
    prop.editIndex = i
    prop.edit = formatStackInfo (prop.stack [prop.editIndex])
    if prefs.debugInvokeEditor and prefs.debugEditorCommandLine then
        invokeEditorStackInfo (prop.stack [prop.editIndex])
        end
    end


--[[----------------------------------------------------------------------------
private void
evalPush (button, prop)

Implements the Eval button of the debugger window. "prop" is the property table
for that window.
------------------------------------------------------------------------------]]

function evalPush (button, prop)
    local evaluate = LrStringUtils.trimWhitespace (prop.evaluate or "")
    if evaluate == "" then return end

    local c = evaluate:sub (1, 1)
    if c == "." then evaluate = evaluate:sub (2) end

    local funcStr = "return function (" .. table.concat (prop.varNames, ", ") 
        .. ") " .. (c ~= "." and "return " or "") .. evaluate .. " end"

    local f, e = loadstring (funcStr)
    if not f then 
        prop.result = e
        return
        end
        
    local function callAndShow ()      
        local function pack (...) return {...}, select ("#", ...) end
        local originalMetatable = getmetatable (_G)
        setmetatable (_G, nil)
        local v, n = pack (LrTasks.pcall (f (), 
                            unpack (prop.values, 1, #prop.varNames))) 
        setmetatable (_G, originalMetatable)
        if v [1] then
            prop.result = ""
            for i = 2, n do 
                prop.result = prop.result .. 
                    Debug.pp (v [i]):gsub ("\n", Newline) .. Newline
                end
            if prefs.debugLogWindow then 
                Debug.log:trace (("Eval: " .. evaluate .. "\n" .. prop.result):
                                 gsub ("\r\n", "\n") .. "")
                end                
        else
            prop.result = v [2]
            end
        end

    if prop.evalInTask then 
        LrTasks.startAsyncTask (
            Debug.showErrors (function () callAndShow () end))
    else
        callAndShow ()
        end
    end


--[[----------------------------------------------------------------------------
private void
breaksPush (button, prop)

Implements the "Function breaks" button of the debugger window.  "prop" is the
property table for that window.
------------------------------------------------------------------------------]]

local BreaksText = [[Enter the names of globally accessible functions to break,
e.g. "myFunc" for a global function or "MyNamespace.myFunc" for a function in a
module. The optional break conditions are Lua expressions referring to
parameters and globally accessible names.]]
BreaksText = BreaksText:gsub (
"%c", " ")

function breaksPush (button, prop)

    if not prefs.debugFuncNames then prefs.debugFuncNames = {} end
    if not prefs.debugExprs then prefs.debugExprs = {} end

    local funcNameFields, exprFields = {}, {}
    for i = 1, 20 do
        funcNameFields [i] = f:edit_field {value = "", width_in_chars = 20,
                                immediate = true}
        exprFields [i] = f:edit_field {value = "", width_in_chars = 35,
                                immediate = true}
        end
        
    local n = 0
    local includedFuncNames = {}
    for i, fi in ipairs (namedBreaks ()) do 
        if n >= #funcNameFields then 
            LrDialogs.message ("Too many functions with breaks -- the " ..
                "remainder will be ignored.")
            break
            end
        n = n + 1
        funcNameFields [n].value = fi.funcName
        exprFields [n].value = fi.expr
        includedFuncNames [fi.funcName] = true
        end
        
    for i, fne in ipairs (prefs.debugFuncNameExprs or {}) do
        if not includedFuncNames [fne.funcName] then
            if n >= #funcNameFields then break end 
            n = n + 1
            funcNameFields [n].value = fne.funcName
            exprFields [n].value = fne.expr
            includedFuncNames [fne.funcName] = true
            end
        end

    while true do
        local result = LrDialogs.presentModalDialog {
            title = "Debug > Function Breaks", contents = f:column {
            bind_to_object = prop, 
            spacing = f:control_spacing (),
            f:static_text {title = BreaksText, height_in_lines = 3, 
                width_in_chars = 55, wrap = true},
            f:row {
                f:column {
                    f:static_text {title = "Function:"},
                    f:column (table.shallowcopy (funcNameFields))},
                f:column {
                    f:static_text {title = "Break condition:"},
                    f:column (table.shallowcopy (exprFields))}}}}
    
        if result == "cancel" then return end        
        
        clearNamedBreaks ()

        local errors = false
        for i = 1, #funcNameFields do
            if (funcNameFields [i].value or "") ~= "" then
                local f, e = Debug.breakFunc (funcNameFields [i].value, 
                                exprFields [i].value)
                if f then 
                    funcNameFields [i].font = "<system>"
                    exprFields [i].font = "<system>"
                else
                    errors = true
                    LrDialogs.message ("Can't break function " .. 
                        funcNameFields [i].value, e)
                    funcNameFields [i].font = "<system/bold>"
                    exprFields [i].font = "<system/bold>"
                    end
                end
            end
        if not errors then break end
        end
    
    local funcNameExprs = {}
    for i = 1, #funcNameFields do
        if (funcNameFields [i].value or "") ~= "" then
            table.insert (funcNameExprs, {funcName = funcNameFields [i].value,
                                          expr = exprFields [i].value})
            end
        end
    prefs.debugFuncNameExprs = funcNameExprs
    end            


--[[----------------------------------------------------------------------------
private void
logPush (button, prop)

Implements the "Log" button of the debugger window.  "prop" is the property
table for that window.
------------------------------------------------------------------------------]]

function logPush (button, prop)
    Debug.invokeEditor (logFilename, 1000000)
    end


--[[----------------------------------------------------------------------------
private void
goUntilReturnPush (button, prop)

Implements the "Go Until Return" button of the debugger window.  "prop" is the
property table for that window.  Causes the window to exit with the value
"goUntilReturn".
------------------------------------------------------------------------------]]

function goUntilReturnPush (button, prop)
    breakCallReturn = false
    LrDialogs.stopModalWithResult (button, "goUntilReturn")
    end


--[[----------------------------------------------------------------------------
private void
goUntilErrorPush (button, prop)

Implements the "Go Until Error" button of the debugger window.  "prop" is the
property table for that window.  Causes the window to exit with the value
"goUntilError".
------------------------------------------------------------------------------]]

function goUntilErrorPush (button, prop)
    breakCallReturn = false
    LrDialogs.stopModalWithResult (button, "goUntilError")
    end


--[[----------------------------------------------------------------------------
private boolean
isSDKObject (x)

Returns true if "x" is an object implemented by the LR SDK. In LR 3, those
objects are tables with a string for a metatable, but in LR 4 beta,
getmetatable() raises an error for such objects.  

NOTE: This is also in Util.lua.
------------------------------------------------------------------------------]]

local majorVersion = LrApplication.versionTable ().major

local function isSDKObject (x)
    if type (x) ~= "table" then
        return false
    elseif majorVersion < 4 then
        return type (getmetatable (x)) == "string"
    else
        local success, value = pcall (getmetatable, x)
        return not success or type (value) == "string"
        end
    end


--[[----------------------------------------------------------------------------
public string
pp (value, int indent, int maxChars, int maxLines)

Returns "value" pretty printed into a string.  The string is guaranteed not
to end in a newline.

indent (default 4): If "indent" is greater than zero, then it is the number of
characters to use for indenting each level.  If "indent" is 0, then the value is
pretty-printed all on one line with no newlines.

maxChars (default maxLines * 100): The output is guaranteed to be no longer than
this number of characters.  If it exceeds maxChars - 3, then the last three
characters will be "..." to indicate truncation.

maxLines (default 5000): The output is guaranteed to have no more than this many
lines. If it is truncated, the last line will end with "..."

------------------------------------------------------------------------------]]

function Debug.pp (value, indent, maxChars, maxLines)
    if not indent then indent = 4 end
    if not maxLines then maxLines = 5000 end
    if not maxChars then maxChars = maxLines * 100 end
    
    local s = ""
    local lines = 1
    local tableLabel = {}
    local nTables = 0    

    local function addNewline (i)
        if #s >= maxChars or lines >= maxLines then return true end
        if indent > 0 then
            s = s .. "\n" .. string.rep (" ", i)
            lines = lines + 1
            end
        return false
        end

    local function pp1 (x, i)
        if type (x) == "string" then
            s = s .. string.format ("%q", x):gsub ("\n", "n")
            
        elseif type (x) ~= "table" then
            s = s .. tostring (x)
            
        elseif isSDKObject (x) then
            s = s .. tostring (x)
            
        else
            if tableLabel [x] then
                s = s .. tableLabel [x] 
                return false
                end
            
            local isEmpty = true
            for k, v in pairs (x) do isEmpty = false; break end
            if isEmpty then 
                s = s .. "{}"
                return false
                end

            nTables = nTables + 1
            local label = "table: " .. nTables
            tableLabel [x] = label
            
            s = s .. "{" 
            if indent > 0 then s = s .. "--" .. label end
            local first = true
            for k, v in pairs (x) do
                if first then
                    first = false
                else
                    s = s .. ", "
                    end
                if addNewline (i + indent) then return true end 
                if type (k) == "string" and k:match ("^[_%a][_%w]*$") then
                    s = s .. k
                else 
                    s = s .. "["
                    if pp1 (k, i + indent) then return true end
                    s = s .. "]"
                    end
                s = s .. " = "
                if pp1 (v, i + indent) then return true end
                end
            s = s .. "}"
            end

        return false
        end
    
    local truncated = pp1 (value, 0)
    if truncated or #s > maxChars then 
        s = s:sub (1, math.max (0, maxChars - 3)) .. "..."
        end
    return s
    end
        
--[[----------------------------------------------------------------------------
public LrLogger log

The "log" is an LrLogger log file that by default writes to the file "debug.log"
in the current plugin directory.
------------------------------------------------------------------------------]]

Debug.log = LrLogger ("com.johnrellis.logger")
    --[[ This apparently must be unique across all of Lightroom and plugins.]]

logFilename = LrPathUtils.child (_PLUGIN.path, "debug.log")

Debug.log:enable (function (msg)
    local f = io.open (logFilename, "a")
    if f == nil then return end
    f:write (
        LrDate.timeToUserFormat (LrDate.currentTime (), "%y/%m/%d %H:%M:%S"), 
        msg, Newline)
    f:close ()
    end)
    

--[[----------------------------------------------------------------------------
public void
setLogFilename (string)

Sets the filename of the log to be something other than the default
(_PLUGIN.path/debug.log).
------------------------------------------------------------------------------]]

function Debug.setLogFilename (filename)
    logFilename = filename
    end


--[[----------------------------------------------------------------------------
public void
logn (...)

Writes all of the arguments to the log, separated by spaces on a single line,
using tostring() to convert to a string.  Useful for low-level debugging.
------------------------------------------------------------------------------]]

function Debug.logn (...)
    local s = ""
    for i = 1, select ("#", ...) do
        local v = select (i, ...)
        s = s .. (i > 1 and " " or "") .. tostring (v) 
        end
    Debug.log:trace (s)
    end

--[[----------------------------------------------------------------------------
public void
lognpp (...)

Pretty prints all of the arguments to the log, separated by spaces or newlines.  Useful
------------------------------------------------------------------------------]]

function Debug.lognpp (...)
    local s = ""
    local sep = " "
    for i = 1, select ("#", ...) do
        local v = select (i, ...)
        local pp = Debug.pp (v)
        s = s .. (i > 1 and sep or "") .. pp
        if lineCount (pp) > 1 then sep = "\n" end
        end
    Debug.log:trace (s)
    end

--[[----------------------------------------------------------------------------
private int
lineCount (string s)

Counts the number of lines in "s".  The last line may or may not end
with a newline, but it counts as a line.
------------------------------------------------------------------------------]]

function lineCount (s)
    local l = 0
    for i = 1, #s do if s:sub (i, i) == "\n" then l = l + 1 end end
    if #s > 0 and s:sub (-1, -1) ~= "\n" then l = l + 1 end
    return l
    end

--[[----------------------------------------------------------------------------
public void
stackTrace ()

Write a raw stack trace to the log.
------------------------------------------------------------------------------]]

function Debug.stackTrace ()
    local s = "\nStack trace:"
    local i = 2
    while true do
        local info = debug.getinfo (i)
        if not info then break end
        s = string.format ("%s\n%s [%s %s]", s, info.name, info.source, 
                           info.currentline)
        i = i + 1
        end
    Debug.log:trace (s)
    end

--[[----------------------------------------------------------------------------
public function
profileFunc (function func, string funcName)

Returns "func" wrapped with simple profiling, recording the total time used, the
total number of calls, and the number of top-level (non-recursive) calls.

Usage:

    myFunc1 = Debug.profileFunc (myFunc1, "myFunc1")
    myFunc2 = Debug.profileFunc (myFunc2, "myFunc2")
    ...
    ...run the code to be profile...
    logn (Debug.profileResults ()) -- record the results to the log
    
Limitation:

- A call to a function that occurs in thread B while another call to the same
function is active in thread A will be treated as a recursive (non-top-level)
call.  There doesn't appear to be any efficient way of identifying the 
current task.
------------------------------------------------------------------------------]]

local funcNameResult = {}

function Debug.profileFunc (func, funcName)
    local nCalls, nTopCalls, totalTime = 0, 0, 0
    local active = false

    local function results ()
        return {funcName = funcName, nCalls = nCalls, nTopCalls = nTopCalls, 
                totalTime = totalTime}
        end

    local function wrapped (...)
        local t
        nCalls = nCalls + 1
        
        local function recordResults (success, ...)
            totalTime = totalTime + (LrDate.currentTime () - t) 
            active = false
            if success then 
                return ...
            else
                error (select (1, ...), 0)
                end
            end
        
        if not active then 
            active = true
            nTopCalls = nTopCalls + 1
            t = LrDate.currentTime ()
            if LrTasks.canYield () then
                return recordResults (LrTasks.pcall (func, ...))
            else 
                return recordResults (pcall (func, ...))
                end
        else
            return func (...)
            end
        end
        
    funcNameResult [funcName] = results
    return wrapped
    end
    
--[[----------------------------------------------------------------------------
public string
profileResults ()

Returns the profiling results of profiled functions, nicely formatted.
------------------------------------------------------------------------------]]

function Debug.profileResults ()
    local s = ""
    s = s .. string.format ("\n%-25s %10s %10s %10s %10s %10s", "Function", 
        "calls", "top calls", "time", "time/call", "time/top")
    for funcName, results in pairs (funcNameResult) do
        local r = results ()
        s = s .. string.format ("\n%-25s %10d %10d %10.5f %10.5f %10.5f", 
            funcName, r.nCalls, r.nTopCalls, r.totalTime, 
            r.nCalls > 0 and r.totalTime / r.nCalls or 0.0,
            r.nTopCalls > 0 and r.totalTime / r.nTopCalls or 0.0)
        end
    return s
    end

--[[----------------------------------------------------------------------------
------------------------------------------------------------------------------]]

Debug.init ()

return Debug    