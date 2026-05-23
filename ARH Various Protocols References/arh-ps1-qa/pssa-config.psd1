# ARH PSScriptAnalyzer Settings
# Apply: Invoke-ScriptAnalyzer -Path . -Settings .\pssa-config.psd1

@{
    IncludeRules = @(
        # Correctness
        'PSAvoidUsingCmdletAliases',
        'PSAvoidDefaultValueSwitchParameter',
        'PSMisleadingBacktick',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars',
        'PSReviewUnusedParameter',

        # Security
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingComputerNameHardcoded',
        'PSUsePSCredentialType',

        # Style / Maintainability
        'PSProvideCommentHelp',
        'PSUseCorrectCasing',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidTrailingWhitespace',
        'PSUseOutputTypeCorrectly'
    )

    # PSAvoidUsingWriteHost excluded — ARH uses Write-Host intentionally
    # for colored console output in non-pipeline scripts
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )

    Severity = @('Error', 'Warning')
}
