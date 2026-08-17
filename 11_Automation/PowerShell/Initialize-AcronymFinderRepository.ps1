# =====================================================================
# Initialize-AcronymFinderRepository.ps1
# =====================================================================
#
# Purpose:
#   Initialize and validate the lightweight repository structure for
#   NugenAnalytics AcronymFinder.
#
# Repository:
#   nugenanalytics-acronymfinder
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

function Write-Info {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Ensure-Directory {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {

        New-Item `
            -ItemType Directory `
            -Path $Path `
            -Force |
            Out-Null

        Write-Host "Created : $Path" -ForegroundColor Green

        return 'Created'
    }
    else {

        Write-Host "Exists  : $Path" -ForegroundColor DarkGray

        return 'Exists'
    }
}

# =====================================================================
# INITIALIZATION
# =====================================================================

try {

    Write-Banner -Text 'NugenAnalytics AcronymFinder Repository Initializer'

    # -----------------------------------------------------------------
    # Determine Repository Root
    # -----------------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {

        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {

            $CandidateRoot = $PSScriptRoot

            # Script expected location:
            # <RepositoryRoot>\11_Automation\PowerShell

            if (
                (Split-Path -Leaf $CandidateRoot) -eq 'PowerShell' -and
                (Split-Path -Leaf (Split-Path -Parent $CandidateRoot)) -eq
                    '11_Automation'
            ) {

                $RepositoryRoot = Split-Path `
                    -Parent `
                    (Split-Path -Parent $CandidateRoot)
            }
            else {

                $RepositoryRoot = (Get-Location).Path
            }
        }
        else {

            $RepositoryRoot = (Get-Location).Path
        }
    }

    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

    Write-Section -Text 'Repository Configuration'

    Write-Host "Repository Root : $RepositoryRoot"

    if (-not (Test-Path -LiteralPath $RepositoryRoot)) {
        throw "Repository root does not exist: $RepositoryRoot"
    }

    # =================================================================
    # CORE APPLICATION FILES
    # =================================================================

    Write-Section -Text 'Core Application Validation'

    $CoreFiles = @(
        'index.html',
        'acronymfinder.css',
        'acronymfinder.js',
        'acronyms.json'
    )

    $MissingCoreFiles = @()

    foreach ($File in $CoreFiles) {

        $FullPath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $File

        if (Test-Path -LiteralPath $FullPath) {

            Write-Pass -Message "Core file found: $File"
        }
        else {

            Write-Warn -Message "Core file missing: $File"
            $MissingCoreFiles += $File
        }
    }

    # =================================================================
    # REPOSITORY STRUCTURE
    # =================================================================

    Write-Section -Text 'Repository Structure Initialization'

    $Directories = @(
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

    $CreatedCount = 0
    $ExistingCount = 0

    foreach ($Directory in $Directories) {

        $DirectoryPath = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $Directory

        $Result = Ensure-Directory -Path $DirectoryPath

        if ($Result -eq 'Created') {
            $CreatedCount++
        }
        else {
            $ExistingCount++
        }
    }

    # =================================================================
    # JSON VALIDATION
    # =================================================================

    Write-Section -Text 'Acronym Data Validation'

    $JsonPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronyms.json'

    if (Test-Path -LiteralPath $JsonPath) {

        try {

            Get-Content `
                -LiteralPath $JsonPath `
                -Raw |
                ConvertFrom-Json |
                Out-Null

            Write-Pass -Message 'acronyms.json contains valid JSON.'
        }
        catch {

            throw "acronyms.json validation failed: $($_.Exception.Message)"
        }
    }
    else {

        Write-Warn -Message 'acronyms.json could not be validated because it is missing.'
    }

    # =================================================================
    # HTML ASSET REFERENCES
    # =================================================================

    Write-Section -Text 'Application Reference Validation'

    $IndexPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'index.html'

    if (Test-Path -LiteralPath $IndexPath) {

        $IndexContent = Get-Content `
            -LiteralPath $IndexPath `
            -Raw

        foreach ($Asset in @(
            'acronymfinder.css',
            'acronymfinder.js'
        )) {

            if ($IndexContent -match [regex]::Escape($Asset)) {

                Write-Pass -Message "index.html references $Asset"
            }
            else {

                Write-Warn -Message "index.html does not reference $Asset"
            }
        }
    }

    $JavaScriptPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronymfinder.js'

    if (Test-Path -LiteralPath $JavaScriptPath) {

        $JavaScriptContent = Get-Content `
            -LiteralPath $JavaScriptPath `
            -Raw

        if ($JavaScriptContent -match 'acronyms\.json') {

            Write-Pass -Message 'acronymfinder.js references acronyms.json'
        }
        else {

            Write-Warn -Message 'acronymfinder.js does not reference acronyms.json'
        }
    }

    # =================================================================
    # GIT VALIDATION
    # =================================================================

    Write-Section -Text 'Git Repository Validation'

    $GitDirectory = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath '.git'

    if (Test-Path -LiteralPath $GitDirectory) {

        Write-Pass -Message '.git repository found.'

        $GitCommand = Get-Command git `
            -ErrorAction SilentlyContinue

        if ($null -ne $GitCommand) {

            Push-Location $RepositoryRoot

            try {

                $Branch = git branch --show-current

                if (-not [string]::IsNullOrWhiteSpace($Branch)) {

                    Write-Host "Current branch : $Branch"
                }

                $GitStatus = git status --short

                if ([string]::IsNullOrWhiteSpace(
                    ($GitStatus -join [Environment]::NewLine)
                )) {

                    Write-Pass -Message 'Git working tree is clean.'
                }
                else {

                    Write-Warn -Message 'Git working tree contains changes.'

                    $GitStatus |
                        ForEach-Object {
                            Write-Host "       $_"
                        }
                }
            }
            finally {

                Pop-Location
            }
        }
        else {

            Write-Warn -Message 'Git executable was not found in PATH.'
        }
    }
    else {

        Write-Warn -Message '.git directory was not found.'
    }

    # =================================================================
    # SUMMARY
    # =================================================================

    Write-Banner -Text 'AcronymFinder Repository Initialization Complete'

    Write-Host "Repository Root:"
    Write-Host $RepositoryRoot -ForegroundColor White
    Write-Host ''

    Write-Host 'Initialization Metrics:'
    Write-Host "  Directories created : $CreatedCount"
    Write-Host "  Directories existing: $ExistingCount"
    Write-Host "  Core files expected : $($CoreFiles.Count)"
    Write-Host "  Core files missing  : $($MissingCoreFiles.Count)"
    Write-Host ''

    if ($MissingCoreFiles.Count -eq 0) {

        Write-Pass -Message `
            'NugenAnalytics AcronymFinder repository initialized successfully.'
    }
    else {

        Write-Warn -Message `
            'Repository structure initialized, but one or more core application files are missing.'
    }

    Write-Host ''
}
catch {

    Write-Host ''
    Write-Host '=====================================================================' `
        -ForegroundColor Red
    Write-Host 'ACRONYMFINDER REPOSITORY INITIALIZATION ERROR' `
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