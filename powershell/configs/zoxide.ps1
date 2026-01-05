Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

Register-ArgumentCompleter -Native -CommandName "cd" -ScriptBlock {
    param(
        $WordToComplete,
        $CommandAst,
        $CursorPosition
    )

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    # The user could have moved the cursor backwards on the command-line.
    # We only show completions when the cursor is at the end of the line
    if ($Command.Length -gt $CursorPosition) {
        return
    }

    $Program,$Arguments = $Command.Split(" ",2)

    # If we don't have any parameter, just use the default completion (Which is Set-Location)
    if([string]::IsNullOrEmpty($Arguments)) {
        return
    }

    $QueryArgs = $Arguments.Split(" ")

    # If the last parameter is complete (there is a space following it)
    if ($WordToComplete -eq "" -And ( -Not $IsEqualFlag )) {
        # Normally, we would invoke the interactive query. Unfortunally it is not possible to invoke an
        # interactive command in a powershell argument completer. Therefore, we just return in that case to the
        # default completion strategy.
        # zoxide query -i -- @QueryArgs
        return
    } else {
        $result = zoxide query --exclude "$(__zoxide_pwd)" -l -- @QueryArgs
    }

    $result | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($($_ | __zoxide_escapeStringWithSpecialChars), "$($_)", 'ParameterValue', "$($_)")
    }
}
