# =====================================================================
# Validate-AcronymFinderRepository.ps1
# =====================================================================
#
# Purpose:
#   Perform read-only validation of the NugenAnalytics AcronymFinder
#   repository structure, core application files, JSON data, application
#   references, automation files, and Git repository state.
#
# Repository:
#   nugenanalytics-acronymfinder
#
# Expected Location:
#   <RepositoryRoot>\11_Automation\PowerShell\
#
# =====================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =====================================================================
# FUNCTIONS
# =====================================================================

function Write-Banner {
    param (
        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host ''
    Write-Host '=====================================================================' `
        -ForegroundColor Cyan
    Write-Host $Text `
        -ForegroundColor Cyan
    Write-Host '=====================================================================' `
        -ForegroundColor Cyan
    Write-Host ''
}

function Write-Section {
    param (
        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host ''
    Write-Host $Text -ForegroundColor Yellow
    Write-Host ('-' * 69) -ForegroundColor DarkGray
}

function Write-Pass {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-Fail {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# =====================================================================
# VALIDATION COUNTERS
# =====================================================================

$PassCount = 0
$FailCount = 0
$WarnCount = 0

function Register-Pass {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:PassCount++
    Write-Pass -Message $Message
}

function Register-Fail {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:FailCount++
    Write-Fail -Message $Message
}

function Register-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:WarnCount++
    Write-Warn -Message $Message
}

# =====================================================================
# MAIN VALIDATION
# =====================================================================

try {

    Write-Banner -Text 'NugenAnalytics AcronymFinder Repository Validator'

    # -----------------------------------------------------------------
    # Determine Repository Root
    # -----------------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {

        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {

            $PowerShellRoot = $PSScriptRoot
            $AutomationRoot = Split-Path -Parent $PowerShellRoot
            $RepositoryRoot = Split-Path -Parent $AutomationRoot
        }
        else {

            throw 'Unable to determine the validator script directory.'
        }
    }

    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

    Write-Section -Text 'Repository Configuration'

    Write-Host "Repository Root : $RepositoryRoot"
    Write-Host "Validator Root  : $PSScriptRoot"

    if (Test-Path -LiteralPath $RepositoryRoot -PathType Container) {

        Register-Pass -Message 'Repository root exists.'
    }
    else {

        Register-Fail -Message "Repository root does not exist: $RepositoryRoot"
        throw 'Repository root validation failed.'
    }

    # =================================================================
    # CORE APPLICATION FILES
    # =================================================================

    Write-Section -Text 'Core Application Files'

    $CoreFiles = @(
        'index.html',
        'acronymfinder.css',
        'acronymfinder.js',
        'acronyms.json'
    )

    foreach ($File in $CoreFiles) {

        $FilePath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $File

        if (Test-Path -LiteralPath $FilePath -PathType Leaf) {

            $FileInfo = Get-Item -LiteralPath $FilePath

            if ($FileInfo.Length -gt 0) {

                Register-Pass -Message (
                    "Core file exists: {0} ({1} bytes)" -f
                    $File,
                    $FileInfo.Length
                )
            }
            else {

                Register-Fail -Message "Core file is empty: $File"
            }
        }
        else {

            Register-Fail -Message "Core file missing: $File"
        }
    }

    # =================================================================
    # CONTROLLED DIRECTORY STRUCTURE
    # =================================================================

    Write-Section -Text 'Controlled Repository Structure'

    $RequiredDirectories = @(
        '00_Project_Management',
        '01_Documentation',
        '11_Automation',
        '11_Automation\PowerShell',
        '11_Automation\Logs',
        '12_Audit_and_History',
        '12_Audit_and_History\01_Execution_Logs',
        '12_Audit_and_History\02_Run_History',
        '12_Audit_and_History\03_Change_History',
        '12_Audit_and_History\03_Change_History\PowerShell',
        '13_Backups',
        '13_Backups\Before_Major_Release'
    )

    foreach ($Directory in $RequiredDirectories) {

        $DirectoryPath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $Directory

        if (Test-Path -LiteralPath $DirectoryPath -PathType Container) {

            Register-Pass -Message "Directory exists: $Directory"
        }
        else {

            Register-Fail -Message "Directory missing: $Directory"
        }
    }

    # =================================================================
    # AUTOMATION FILES
    # =================================================================

    Write-Section -Text 'Repository Automation'

    $AutomationFiles = @(
        '11_Automation\PowerShell\Initialize-AcronymFinderRepository.ps1',
        '11_Automation\PowerShell\Validate-AcronymFinderRepository.ps1'
    )

    foreach ($AutomationFile in $AutomationFiles) {

        $AutomationPath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $AutomationFile

        if (Test-Path -LiteralPath $AutomationPath -PathType Leaf) {

            Register-Pass -Message "Automation file exists: $AutomationFile"
        }
        else {

            Register-Fail -Message "Automation file missing: $AutomationFile"
        }
    }

    # =================================================================
    # POWERSHELL PARSER VALIDATION
    # =================================================================

    Write-Section -Text 'PowerShell Parser Validation'

    foreach ($AutomationFile in $AutomationFiles) {

        $AutomationPath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $AutomationFile

        if (-not (Test-Path -LiteralPath $AutomationPath -PathType Leaf)) {
            continue
        }

        $Tokens = $null
        $ParserErrors = $null

        [System.Management.Automation.Language.Parser]::ParseFile(
            $AutomationPath,
            [ref]$Tokens,
            [ref]$ParserErrors
        ) | Out-Null

        if ($ParserErrors.Count -eq 0) {

            Register-Pass -Message (
                "Parser validation passed: {0}" -f
                (Split-Path -Leaf $AutomationPath)
            )
        }
        else {

            Register-Fail -Message (
                "Parser errors detected: {0}" -f
                (Split-Path -Leaf $AutomationPath)
            )

            foreach ($ParserError in $ParserErrors) {

                Write-Host (
                    "       Line {0}, Column {1}: {2}" -f
                    $ParserError.Extent.StartLineNumber,
                    $ParserError.Extent.StartColumnNumber,
                    $ParserError.Message
                ) -ForegroundColor Red
            }
        }
    }

    # =================================================================
    # JSON VALIDATION
    # =================================================================

    Write-Section -Text 'Acronym Data Validation'

    $JsonPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronyms.json'

    if (Test-Path -LiteralPath $JsonPath -PathType Leaf) {

        try {

            $JsonContent = Get-Content `
                -LiteralPath $JsonPath `
                -Raw

            $JsonObject = $JsonContent |
                ConvertFrom-Json

            Register-Pass -Message 'acronyms.json contains valid JSON.'

            if ($null -ne $JsonObject) {

                Register-Pass -Message 'acronyms.json produced a valid data object.'
            }
            else {

                Register-Fail -Message 'acronyms.json produced no data object.'
            }
        }
        catch {

            Register-Fail -Message (
                "acronyms.json validation failed: {0}" -f
                $_.Exception.Message
            )
        }
    }
    else {

        Register-Fail -Message 'acronyms.json is missing.'
    }

    # =================================================================
    # HTML REFERENCES
    # =================================================================

    Write-Section -Text 'HTML Asset References'

    $IndexPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'index.html'

    if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {

        $IndexContent = Get-Content `
            -LiteralPath $IndexPath `
            -Raw

        $RequiredAssets = @(
            'acronymfinder.css',
            'acronymfinder.js'
        )

        foreach ($Asset in $RequiredAssets) {

            if ($IndexContent -match [regex]::Escape($Asset)) {

                Register-Pass -Message "index.html references $Asset"
            }
            else {

                Register-Fail -Message "index.html does not reference $Asset"
            }
        }
    }
    else {

        Register-Fail -Message 'Unable to validate HTML references because index.html is missing.'
    }

    # =================================================================
    # JAVASCRIPT DATA REFERENCE
    # =================================================================

    Write-Section -Text 'JavaScript Data Reference'

    $JavaScriptPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronymfinder.js'

    if (Test-Path -LiteralPath $JavaScriptPath -PathType Leaf) {

        $JavaScriptContent = Get-Content `
            -LiteralPath $JavaScriptPath `
            -Raw

        if ($JavaScriptContent -match 'acronyms\.json') {

            Register-Pass -Message 'acronymfinder.js references acronyms.json.'
        }
        else {

            Register-Fail -Message 'acronymfinder.js does not reference acronyms.json.'
        }
    }
    else {

        Register-Fail -Message 'Unable to validate JavaScript data reference.'
    }

    # =================================================================
    # GIT VALIDATION
    # =================================================================

    Write-Section -Text 'Git Repository Validation'

    $GitPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath '.git'

    if (Test-Path -LiteralPath $GitPath -PathType Container) {

        Register-Pass -Message '.git repository exists.'
    }
    else {

        Register-Fail -Message '.git repository is missing.'
    }

    $GitCommand = Get-Command git `
        -ErrorAction SilentlyContinue

    if ($null -ne $GitCommand) {

        Register-Pass -Message 'Git executable is available.'

        Push-Location $RepositoryRoot

        try {

            $CurrentBranch = git branch --show-current

            if ($LASTEXITCODE -eq 0 -and
                -not [string]::IsNullOrWhiteSpace($CurrentBranch)) {

                Register-Pass -Message "Current Git branch: $CurrentBranch"
            }
            else {

                Register-Warn -Message 'Unable to determine current Git branch.'
            }

            $GitStatus = @(git status --short)

            if ($LASTEXITCODE -ne 0) {

                Register-Fail -Message 'git status command failed.'
            }
            elseif ($GitStatus.Count -eq 0) {

                Register-Pass -Message 'Git working tree is clean.'
            }
            else {

                Register-Warn -Message 'Git working tree contains changes.'

                foreach ($StatusLine in $GitStatus) {

                    Write-Host "       $StatusLine"
                }
            }
        }
        finally {

            Pop-Location
        }
    }
    else {

        Register-Warn -Message 'Git executable was not found in PATH.'
    }

    # =================================================================
    # VALIDATION SUMMARY
    # =================================================================

    Write-Banner -Text 'AcronymFinder Repository Validation Summary'

    Write-Host "Repository Root:"
    Write-Host $RepositoryRoot
    Write-Host ''

    Write-Host 'Validation Metrics:'
    Write-Host "  Passed   : $PassCount"
    Write-Host "  Warnings : $WarnCount"
    Write-Host "  Failed   : $FailCount"
    Write-Host ''

    if ($FailCount -eq 0) {

        Write-Host '=====================================================================' `
            -ForegroundColor Green
        Write-Host '[PASS] AcronymFinder repository validation completed successfully.' `
            -ForegroundColor Green
        Write-Host '=====================================================================' `
            -ForegroundColor Green
        Write-Host ''

        exit 0
    }
    else {

        Write-Host '=====================================================================' `
            -ForegroundColor Red
        Write-Host (
            "[FAIL] AcronymFinder repository validation detected " +
            "$FailCount failure(s)."
        ) -ForegroundColor Red
        Write-Host '=====================================================================' `
            -ForegroundColor Red
        Write-Host ''

        exit 1
    }
}
catch {

    Write-Host ''
    Write-Host '=====================================================================' `
        -ForegroundColor Red
    Write-Host 'ACRONYMFINDER REPOSITORY VALIDATION ERROR' `
        -ForegroundColor Red
    Write-Host '=====================================================================' `
        -ForegroundColor Red
    Write-Host ''

    Write-Host "Line number : $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Command     : $($_.InvocationInfo.Line)"
    Write-Host ''
    Write-Host "Message     : $($_.Exception.Message)" `
        -ForegroundColor Red
    Write-Host ''

    exit 1
}