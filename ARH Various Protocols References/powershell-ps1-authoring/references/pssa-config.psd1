# ARH PSScriptAnalyzer Settings
# Apply: Invoke-ScriptAnalyzer -Path . -Settings .\pssa-config.psd1

@{
    # Rules to include (override default)
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

    # Rules excluded from ARH scripts
    # PSAvoidUsingWriteHost: ARH intentionally uses Write-Host for colored console output
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )

    # Severity thresholds
    # Errors block merge; warnings are reviewed; information is noise-filtered
    Severity = @('Error', 'Warning')
}
