# =====================================================================
# Test-AcronymFinderApplication.ps1
# =====================================================================
#
# Purpose:
#   Perform read-only application-level validation for the
#   NugenAnalytics AcronymFinder application.
#
# Validates:
#   - Required application files
#   - JSON parsing
#   - Acronym dataset structure
#   - Blank/null acronym values
#   - Blank/null definitions
#   - Duplicate acronyms
#   - Duplicate definitions
#   - Suspicious whitespace
#   - HTML/CSS/JavaScript references
#   - JavaScript reference to acronyms.json
#   - Basic browser-facing HTML elements
#   - Git working tree status
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

function Register-Pass {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:PassCount++
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Register-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:WarnCount++
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Register-Fail {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:FailCount++
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-PropertyValue {
    param (
        [Parameter(Mandatory)]
        [object]$Object,

        [Parameter(Mandatory)]
        [string[]]$CandidateNames
    )

    foreach ($Name in $CandidateNames) {

        $Property = $Object.PSObject.Properties |
            Where-Object {
                $_.Name -ieq $Name
            } |
            Select-Object -First 1

        if ($null -ne $Property) {
            return $Property.Value
        }
    }

    return $null
}

# =====================================================================
# COUNTERS
# =====================================================================

$PassCount = 0
$WarnCount = 0
$FailCount = 0

# =====================================================================
# MAIN
# =====================================================================

try {

    Write-Banner -Text 'NugenAnalytics AcronymFinder Application Test'

    # -----------------------------------------------------------------
    # Determine Repository Root
    # -----------------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {

        if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            throw 'Unable to determine the application test script directory.'
        }

        $AutomationRoot = Split-Path -Parent $PSScriptRoot
        $RepositoryRoot = Split-Path -Parent $AutomationRoot
    }

    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)

    Write-Section -Text 'Application Configuration'

    Write-Host "Repository Root : $RepositoryRoot"
    Write-Host "Test Script Root: $PSScriptRoot"

    if (Test-Path -LiteralPath $RepositoryRoot -PathType Container) {

        Register-Pass -Message 'Repository root exists.'
    }
    else {

        Register-Fail -Message 'Repository root does not exist.'
        throw "Repository root not found: $RepositoryRoot"
    }

    # =================================================================
    # REQUIRED APPLICATION FILES
    # =================================================================

    Write-Section -Text 'Required Application Files'

    $RequiredFiles = @(
        'index.html',
        'acronymfinder.css',
        'acronymfinder.js',
        'acronyms.json'
    )

    foreach ($File in $RequiredFiles) {

        $Path = Join-Path `
            -Path $RepositoryRoot `
            -ChildPath $File

        if (Test-Path -LiteralPath $Path -PathType Leaf) {

            $FileInfo = Get-Item -LiteralPath $Path

            if ($FileInfo.Length -gt 0) {

                Register-Pass -Message (
                    "Application file exists: {0} ({1} bytes)" -f
                    $File,
                    $FileInfo.Length
                )
            }
            else {

                Register-Fail -Message "Application file is empty: $File"
            }
        }
        else {

            Register-Fail -Message "Application file missing: $File"
        }
    }

    # =================================================================
    # JSON PARSING
    # =================================================================

    Write-Section -Text 'Acronym Dataset Parsing'

    $JsonPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronyms.json'

    $AcronymData = $null

    if (Test-Path -LiteralPath $JsonPath -PathType Leaf) {

        try {

            $RawJson = Get-Content `
                -LiteralPath $JsonPath `
                -Raw

            $AcronymData = $RawJson |
                ConvertFrom-Json

            Register-Pass -Message 'acronyms.json parsed successfully.'
        }
        catch {

            Register-Fail -Message (
                "acronyms.json parsing failed: {0}" -f
                $_.Exception.Message
            )
        }
    }

    if ($null -eq $AcronymData) {

        throw 'Acronym dataset could not be loaded. Remaining data tests cannot continue.'
    }

    # =================================================================
    # NORMALIZE DATASET
    # =================================================================

    Write-Section -Text 'Acronym Dataset Structure'

    $Records = @()

    if ($AcronymData -is [System.Array]) {

        $Records = @($AcronymData)

        Register-Pass -Message (
            "Dataset root is an array containing {0} record(s)." -f
            $Records.Count
        )
    }
    elseif ($AcronymData.PSObject.Properties.Count -gt 0) {

        $PossibleCollections = @(
            'acronyms',
            'items',
            'data',
            'records',
            'entries'
        )

        $DetectedCollection = $null

        foreach ($CollectionName in $PossibleCollections) {

            $Property = $AcronymData.PSObject.Properties |
                Where-Object {
                    $_.Name -ieq $CollectionName
                } |
                Select-Object -First 1

            if ($null -ne $Property) {

                if ($Property.Value -is [System.Array]) {

                    $DetectedCollection = $Property.Value

                    Register-Pass -Message (
                        "Dataset collection detected: {0}" -f
                        $Property.Name
                    )

                    break
                }
            }
        }

        if ($null -ne $DetectedCollection) {

            $Records = @($DetectedCollection)
        }
        else {

            Register-Warn -Message (
                'Dataset root is an object and no standard collection ' +
                'property was detected.'
            )

            $Records = @($AcronymData)
        }
    }

    if ($Records.Count -gt 0) {

        Register-Pass -Message (
            "Acronym dataset contains {0} record(s)." -f
            $Records.Count
        )
    }
    else {

        Register-Fail -Message 'Acronym dataset contains no records.'
    }

    # =================================================================
    # FIELD DISCOVERY
    # =================================================================

    Write-Section -Text 'Dataset Field Validation'

    $AcronymCandidates = @(
        'acronym',
        'abbr',
        'abbreviation',
        'shortName',
        'short'
    )

    $DefinitionCandidates = @(
        'definition',
        'meaning',
        'description',
        'fullForm',
        'fullName',
        'term'
    )

    $ResolvedRecords = @()

    $RecordNumber = 0

    foreach ($Record in $Records) {

        $RecordNumber++

        $AcronymValue = Get-PropertyValue `
            -Object $Record `
            -CandidateNames $AcronymCandidates

        $DefinitionValue = Get-PropertyValue `
            -Object $Record `
            -CandidateNames $DefinitionCandidates

        if ($null -eq $AcronymValue) {

            Register-Fail -Message (
                "Record $RecordNumber does not contain a recognized acronym field."
            )
        }

        if ($null -eq $DefinitionValue) {

            Register-Fail -Message (
                "Record $RecordNumber does not contain a recognized definition field."
            )
        }

        $ResolvedRecords += [PSCustomObject]@{
            RecordNumber = $RecordNumber
            Acronym      = $AcronymValue
            Definition   = $DefinitionValue
            Original     = $Record
        }
    }

    if ($ResolvedRecords.Count -eq $Records.Count) {

        Register-Pass -Message 'Dataset records were normalized for validation.'
    }

    # =================================================================
    # BLANK VALUES
    # =================================================================

    Write-Section -Text 'Blank Value Validation'

    $BlankAcronyms = @(
        $ResolvedRecords |
            Where-Object {
                $null -eq $_.Acronym -or
                [string]::IsNullOrWhiteSpace([string]$_.Acronym)
            }
    )

    if ($BlankAcronyms.Count -eq 0) {

        Register-Pass -Message 'No blank acronym values detected.'
    }
    else {

        Register-Fail -Message (
            "{0} record(s) contain blank acronym values." -f
            $BlankAcronyms.Count
        )

        foreach ($Item in $BlankAcronyms) {
            Write-Host "       Record: $($Item.RecordNumber)"
        }
    }

    $BlankDefinitions = @(
        $ResolvedRecords |
            Where-Object {
                $null -eq $_.Definition -or
                [string]::IsNullOrWhiteSpace([string]$_.Definition)
            }
    )

    if ($BlankDefinitions.Count -eq 0) {

        Register-Pass -Message 'No blank definition values detected.'
    }
    else {

        Register-Fail -Message (
            "{0} record(s) contain blank definitions." -f
            $BlankDefinitions.Count
        )

        foreach ($Item in $BlankDefinitions) {

            Write-Host (
                "       Record {0}: {1}" -f
                $Item.RecordNumber,
                $Item.Acronym
            )
        }
    }

    # =================================================================
    # DUPLICATE ACRONYMS
    # =================================================================

    Write-Section -Text 'Duplicate Acronym Validation'

    $DuplicateAcronyms = @(
        $ResolvedRecords |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_.Acronym
                )
            } |
            Group-Object {
                ([string]$_.Acronym).Trim().ToUpperInvariant()
            } |
            Where-Object {
                $_.Count -gt 1
            }
    )

    if ($DuplicateAcronyms.Count -eq 0) {

        Register-Pass -Message 'No duplicate acronym keys detected.'
    }
    else {

        Register-Warn -Message (
            "{0} duplicate acronym group(s) detected." -f
            $DuplicateAcronyms.Count
        )

        foreach ($Duplicate in $DuplicateAcronyms) {

            Write-Host (
                "       {0} : {1} records" -f
                $Duplicate.Name,
                $Duplicate.Count
            )
        }
    }

    # =================================================================
    # DUPLICATE DEFINITIONS
    # =================================================================

    Write-Section -Text 'Duplicate Definition Validation'

    $DuplicateDefinitions = @(
        $ResolvedRecords |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_.Definition
                )
            } |
            Group-Object {
                ([string]$_.Definition).Trim().ToUpperInvariant()
            } |
            Where-Object {
                $_.Count -gt 1
            }
    )

    if ($DuplicateDefinitions.Count -eq 0) {

        Register-Pass -Message 'No exact duplicate definitions detected.'
    }
    else {

        Register-Warn -Message (
            "{0} duplicate definition group(s) detected." -f
            $DuplicateDefinitions.Count
        )

        foreach ($Duplicate in $DuplicateDefinitions) {

            $Examples = $Duplicate.Group |
                Select-Object -First 5

            Write-Host "       Duplicate definition used by:"

            foreach ($Example in $Examples) {

                Write-Host (
                    "         - {0}" -f
                    $Example.Acronym
                )
            }
        }
    }

    # =================================================================
    # WHITESPACE VALIDATION
    # =================================================================

    Write-Section -Text 'Whitespace Validation'

    $WhitespaceIssues = @()

    foreach ($Item in $ResolvedRecords) {

        if ($null -ne $Item.Acronym) {

            $AcronymText = [string]$Item.Acronym

            if ($AcronymText -ne $AcronymText.Trim()) {

                $WhitespaceIssues += (
                    "Record {0} acronym '{1}'" -f
                    $Item.RecordNumber,
                    $AcronymText
                )
            }
        }

        if ($null -ne $Item.Definition) {

            $DefinitionText = [string]$Item.Definition

            if ($DefinitionText -ne $DefinitionText.Trim()) {

                $WhitespaceIssues += (
                    "Record {0} definition for '{1}'" -f
                    $Item.RecordNumber,
                    $Item.Acronym
                )
            }
        }
    }

    if ($WhitespaceIssues.Count -eq 0) {

        Register-Pass -Message 'No leading or trailing whitespace detected.'
    }
    else {

        Register-Warn -Message (
            "{0} whitespace issue(s) detected." -f
            $WhitespaceIssues.Count
        )

        $WhitespaceIssues |
            Select-Object -First 20 |
            ForEach-Object {
                Write-Host "       $_"
            }

        if ($WhitespaceIssues.Count -gt 20) {

            Write-Host (
                "       Additional issues omitted: {0}" -f
                ($WhitespaceIssues.Count - 20)
            )
        }
    }

    # =================================================================
    # HTML VALIDATION
    # =================================================================

    Write-Section -Text 'HTML Application Validation'

    $IndexPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'index.html'

    if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {

        $Html = Get-Content `
            -LiteralPath $IndexPath `
            -Raw

        if ($Html -match '(?i)<!doctype\s+html') {

            Register-Pass -Message 'HTML5 DOCTYPE detected.'
        }
        else {

            Register-Warn -Message 'HTML5 DOCTYPE was not detected.'
        }

        if ($Html -match '(?i)<html') {

            Register-Pass -Message '<html> element detected.'
        }
        else {

            Register-Fail -Message '<html> element not detected.'
        }

        if ($Html -match '(?i)<head') {

            Register-Pass -Message '<head> element detected.'
        }
        else {

            Register-Fail -Message '<head> element not detected.'
        }

        if ($Html -match '(?i)<body') {

            Register-Pass -Message '<body> element detected.'
        }
        else {

            Register-Fail -Message '<body> element not detected.'
        }

        if ($Html -match '(?i)<title[^>]*>.*?</title>') {

            Register-Pass -Message 'HTML document title detected.'
        }
        else {

            Register-Warn -Message 'HTML document title was not detected.'
        }

        if ($Html -match '(?i)acronymfinder\.css') {

            Register-Pass -Message 'HTML references acronymfinder.css.'
        }
        else {

            Register-Fail -Message 'HTML does not reference acronymfinder.css.'
        }

        if ($Html -match '(?i)acronymfinder\.js') {

            Register-Pass -Message 'HTML references acronymfinder.js.'
        }
        else {

            Register-Fail -Message 'HTML does not reference acronymfinder.js.'
        }
    }

    # =================================================================
    # JAVASCRIPT VALIDATION
    # =================================================================

    Write-Section -Text 'JavaScript Application Validation'

    $JavaScriptPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronymfinder.js'

    if (Test-Path -LiteralPath $JavaScriptPath -PathType Leaf) {

        $JavaScript = Get-Content `
            -LiteralPath $JavaScriptPath `
            -Raw

        if ($JavaScript -match '(?i)acronyms\.json') {

            Register-Pass -Message 'JavaScript references acronyms.json.'
        }
        else {

            Register-Fail -Message 'JavaScript does not reference acronyms.json.'
        }

        if ($JavaScript -match '(?i)\bfetch\s*\(') {

            Register-Pass -Message 'JavaScript contains a fetch operation.'
        }
        else {

            Register-Warn -Message (
                'No fetch operation detected. Verify how acronyms.json is loaded.'
            )
        }

        if ($JavaScript -match 'console\.log\s*\(') {

            Register-Warn -Message (
                'console.log statement(s) detected in application JavaScript.'
            )
        }
        else {

            Register-Pass -Message 'No console.log statements detected.'
        }

        if ($JavaScript -match '(?i)\beval\s*\(') {

            Register-Warn -Message 'eval() usage detected.'
        }
        else {

            Register-Pass -Message 'No eval() usage detected.'
        }
    }

    # =================================================================
    # CSS VALIDATION
    # =================================================================

    Write-Section -Text 'CSS Application Validation'

    $CssPath = Join-Path `
        -Path $RepositoryRoot `
        -ChildPath 'acronymfinder.css'

    if (Test-Path -LiteralPath $CssPath -PathType Leaf) {

        $Css = Get-Content `
            -LiteralPath $CssPath `
            -Raw

        if ([string]::IsNullOrWhiteSpace($Css)) {

            Register-Fail -Message 'acronymfinder.css contains no content.'
        }
        else {

            Register-Pass -Message 'acronymfinder.css contains stylesheet content.'
        }

        if ($Css -match '@media') {

            Register-Pass -Message 'Responsive CSS media query detected.'
        }
        else {

            Register-Warn -Message (
                'No CSS media query detected. Review responsive behavior manually.'
            )
        }
    }

    # =================================================================
    # GIT STATUS
    # =================================================================

    Write-Section -Text 'Git Working Tree'

    $GitCommand = Get-Command git `
        -ErrorAction SilentlyContinue

    if ($null -eq $GitCommand) {

        Register-Warn -Message 'Git executable is unavailable.'
    }
    else {

        Push-Location $RepositoryRoot

        try {

            $GitStatus = @(git status --short)

            if ($LASTEXITCODE -ne 0) {

                Register-Fail -Message 'Unable to obtain Git working-tree status.'
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

    # =================================================================
    # SUMMARY
    # =================================================================

    Write-Banner -Text 'AcronymFinder Application Test Summary'

    Write-Host "Repository Root:"
    Write-Host $RepositoryRoot
    Write-Host ''

    Write-Host 'Application Metrics:'
    Write-Host "  Dataset records : $($Records.Count)"
    Write-Host "  Passed          : $PassCount"
    Write-Host "  Warnings        : $WarnCount"
    Write-Host "  Failed          : $FailCount"
    Write-Host ''

    if ($FailCount -eq 0) {

        Write-Host '=====================================================================' `
            -ForegroundColor Green
        Write-Host '[PASS] AcronymFinder application testing completed successfully.' `
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
            "[FAIL] AcronymFinder application testing detected " +
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
    Write-Host 'ACRONYMFINDER APPLICATION TEST ERROR' `
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