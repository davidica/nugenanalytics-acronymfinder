# =====================================================================
# Invoke-AcronymFinderValidation.ps1
# =====================================================================
#
# Purpose:
#   Execute the complete NugenAnalytics AcronymFinder validation suite.
#
# Executes:
#   1. Validate-AcronymFinderRepository.ps1
#   2. Test-AcronymFinderApplication.ps1
#
# Behavior:
#   - Read-only orchestration
#   - Stops only after all validation stages have been attempted
#   - Captures individual stage results
#   - Produces one consolidated PASS / FAIL result
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

function Invoke-ValidationStage {
    param (
        [Parameter(Mandatory)]
        [string]$StageName,

        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [string]$RepositoryRoot
    )

    Write-Section -Text $StageName

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {

        Write-Fail -Message "Validation script not found: $ScriptPath"

        return [PSCustomObject]@{
            StageName = $StageName
            Script    = $ScriptPath
            ExitCode  = 1
            Result    = 'FAIL'
        }
    }

    Write-Host "Script : $ScriptPath"
    Write-Host ''

    & $ScriptPath `
        -RepositoryRoot $RepositoryRoot

    $StageExitCode = $LASTEXITCODE

    if ($null -eq $StageExitCode) {
        $StageExitCode = 0
    }

    Write-Host ''

    if ($StageExitCode -eq 0) {

        Write-Pass -Message "$StageName completed successfully."

        return [PSCustomObject]@{
            StageName = $StageName
            Script    = $ScriptPath
            ExitCode  = 0
            Result    = 'PASS'
        }
    }
    else {

        Write-Fail -Message (
            "$StageName returned exit code $StageExitCode."
        )

        return [PSCustomObject]@{
            StageName = $StageName
            Script    = $ScriptPath
            ExitCode  = $StageExitCode
            Result    = 'FAIL'
        }
    }
}

# =====================================================================
# MAIN
# =====================================================================

try {

    Write-Banner -Text 'NugenAnalytics AcronymFinder Validation Suite'

    # -----------------------------------------------------------------
    # Determine Repository Root
    # -----------------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {

        if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {

            throw 'Unable to determine the validation script directory.'
        }

        $AutomationRoot = Split-Path -Parent $PSScriptRoot
        $RepositoryRoot = Split-Path -Parent $AutomationRoot
    }

    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

    Write-Section -Text 'Validation Configuration'

    Write-Host "Repository Root : $RepositoryRoot"
    Write-Host "Automation Root : $PSScriptRoot"

    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {

        throw "Repository root does not exist: $RepositoryRoot"
    }

    Write-Pass -Message 'Repository root validated.'

    # =================================================================
    # VALIDATION SCRIPTS
    # =================================================================

    $RepositoryValidator = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath 'Validate-AcronymFinderRepository.ps1'

    $ApplicationTester = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath 'Test-AcronymFinderApplication.ps1'

    # =================================================================
    # PARSER VALIDATION
    # =================================================================

    Write-Section -Text 'Validation Script Parser Check'

    $ValidationScripts = @(
        $RepositoryValidator,
        $ApplicationTester
    )

    $ParserFailureCount = 0

    foreach ($ScriptPath in $ValidationScripts) {

        if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {

            Write-Fail -Message (
                "Required validation script missing: $ScriptPath"
            )

            $ParserFailureCount++
            continue
        }

        $Tokens = $null
        $ParserErrors = $null

        [System.Management.Automation.Language.Parser]::ParseFile(
            $ScriptPath,
            [ref]$Tokens,
            [ref]$ParserErrors
        ) | Out-Null

        if ($ParserErrors.Count -eq 0) {

            Write-Pass -Message (
                "Parser check passed: {0}" -f
                (Split-Path -Leaf $ScriptPath)
            )
        }
        else {

            Write-Fail -Message (
                "Parser errors detected: {0}" -f
                (Split-Path -Leaf $ScriptPath)
            )

            $ParserFailureCount++

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

    if ($ParserFailureCount -gt 0) {

        throw (
            "$ParserFailureCount validation script parser failure(s) detected."
        )
    }

    # =================================================================
    # EXECUTE VALIDATION STAGES
    # =================================================================

    $Results = @()

    $Results += Invoke-ValidationStage `
        -StageName 'Stage 1 - Repository Validation' `
        -ScriptPath $RepositoryValidator `
        -RepositoryRoot $RepositoryRoot

    $Results += Invoke-ValidationStage `
        -StageName 'Stage 2 - Application Testing' `
        -ScriptPath $ApplicationTester `
        -RepositoryRoot $RepositoryRoot

    # =================================================================
    # CONSOLIDATED RESULTS
    # =================================================================

    Write-Banner -Text 'AcronymFinder Consolidated Validation Summary'

    $PassedStages = @(
        $Results |
            Where-Object {
                $_.Result -eq 'PASS'
            }
    )

    $FailedStages = @(
        $Results |
            Where-Object {
                $_.Result -eq 'FAIL'
            }
    )

    Write-Host 'Validation Stages:'
    Write-Host ''

    foreach ($Result in $Results) {

        if ($Result.Result -eq 'PASS') {

            Write-Host (
                "  [PASS] {0}" -f
                $Result.StageName
            ) -ForegroundColor Green
        }
        else {

            Write-Host (
                "  [FAIL] {0} (Exit Code {1})" -f
                $Result.StageName,
                $Result.ExitCode
            ) -ForegroundColor Red
        }
    }

    Write-Host ''
    Write-Host 'Suite Metrics:'
    Write-Host "  Stages executed : $($Results.Count)"
    Write-Host "  Stages passed   : $($PassedStages.Count)"
    Write-Host "  Stages failed   : $($FailedStages.Count)"
    Write-Host ''

    if ($FailedStages.Count -eq 0) {

        Write-Host '=====================================================================' `
            -ForegroundColor Green
        Write-Host '[PASS] AcronymFinder validation suite completed successfully.' `
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
            "[FAIL] AcronymFinder validation suite detected " +
            "$($FailedStages.Count) failed stage(s)."
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
    Write-Host 'ACRONYMFINDER VALIDATION SUITE ERROR' `
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