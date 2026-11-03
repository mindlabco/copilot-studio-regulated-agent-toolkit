<#
.SYNOPSIS
    Creates the Dataverse tables for the Responsible Agent Toolkit app
    (Agent Register, fact sheet details, approvals, reviews and evaluations).

.DESCRIPTION
    Uses the Dataverse Web API to create, in one unmanaged solution:
      - a publisher and solution (if they do not exist)
      - 20 global choices
      - 9 tables with their columns
      - lookups between the tables, and to users (owners, reviewers, approvers)
      - optionally, a lookup to the Copilot Agent Kit's Agent Details table

    Safe to re-run: anything that already exists is skipped, never changed or deleted.
    Run it in a DEVELOPMENT environment first.

    After it finishes you still build, by hand:
      - the model-driven app, forms and views
      - the Power Automate flows (see "Agent Register Extension" document)
      - security roles

.PARAMETER EnvironmentUrl
    Your Dataverse environment URL, e.g. https://yourorg-dev.crm3.dynamics.com

.PARAMETER AccessToken
    Optional. A bearer token for the environment. If omitted, the script gets one
    from the Azure CLI (run "az login" first) or, failing that, from the Az PowerShell
    module (run "Connect-AzAccount" first).

.PARAMETER AgentDetailsTable
    Optional. Logical name of the Copilot Agent Kit's Agent Details table in this
    environment. Find it in make.powerapps.com > Tables > Agent Details > Properties >
    Tools > Copy logical name. If given and found, the Agent Register gets a lookup to it.

.PARAMETER WhatIf
    Dry run. Prints what would be created and calls nothing. No token needed.

.EXAMPLE
    ./Build-AgentGovernanceTables.ps1 -EnvironmentUrl https://contoso-dev.crm3.dynamics.com -WhatIf

.EXAMPLE
    az login
    ./Build-AgentGovernanceTables.ps1 -EnvironmentUrl https://contoso-dev.crm3.dynamics.com -AgentDetailsTable cat_agentdetails

.NOTES
    Responsible Agent Toolkit | v1 | Requires PowerShell 7+
    Requires System Customizer or System Administrator in the target environment.
    Provided as-is. Review before running in any shared environment.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$EnvironmentUrl,
    [string]$AccessToken,
    [string]$PublisherUniqueName = 'responsibleagenttoolkit',
    [string]$PublisherFriendlyName = 'Responsible Agent Toolkit',
    [ValidatePattern('^[a-z][a-z0-9]{1,7}$')][string]$Prefix = 'rat',
    [ValidateRange(10000, 99999)][int]$OptionValuePrefix = 47210,
    [string]$SolutionUniqueName = 'ResponsibleAgentToolkit',
    [string]$SolutionFriendlyName = 'Responsible Agent Toolkit',
    [string]$AgentDetailsTable,
    [int]$LanguageCode = 1033,
    [switch]$SkipPublish,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$EnvironmentUrl = $EnvironmentUrl.TrimEnd('/')
$Api = "$EnvironmentUrl/api/data/v9.2"
$script:Created = 0
$script:Skipped = 0

# ---------------------------------------------------------------- helpers

function Write-Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }
function Write-Done($msg) { Write-Host "   + $msg" -ForegroundColor Green; $script:Created++ }
function Write-Skip($msg) { Write-Host "   = $msg (exists, skipped)" -ForegroundColor DarkGray; $script:Skipped++ }
function Write-Plan($msg) { Write-Host "   ? would create $msg" -ForegroundColor Yellow }

function New-Label([string]$text) {
    [ordered]@{
        '@odata.type'     = 'Microsoft.Dynamics.CRM.Label'
        LocalizedLabels   = @([ordered]@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'
            Label         = $text
            LanguageCode  = $LanguageCode
        })
    }
}
function New-Required([string]$level = 'None') {
    [ordered]@{ Value = $level; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyrequirementlevelsettings' }
}

function Get-Token {
    if ($AccessToken) { return $AccessToken }
    $az = Get-Command az -ErrorAction SilentlyContinue
    if ($az) {
        $t = & az account get-access-token --resource $EnvironmentUrl --query accessToken -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $t) { return $t.Trim() }
    }
    if (Get-Command Get-AzAccessToken -ErrorAction SilentlyContinue) {
        $r = Get-AzAccessToken -ResourceUrl $EnvironmentUrl
        if ($r.Token -is [securestring]) { return [System.Net.NetworkCredential]::new('', $r.Token).Password }
        return $r.Token
    }
    throw 'No access token. Run "az login" (Azure CLI) or "Connect-AzAccount" (Az module), or pass -AccessToken.'
}

function Invoke-Dv {
    param([string]$Method, [string]$Path, $Body, [switch]$ReturnRepresentation)
    $headers = @{
        Authorization                 = "Bearer $script:Token"
        'OData-MaxVersion'            = '4.0'
        'OData-Version'               = '4.0'
        Accept                        = 'application/json'
        'MSCRM.SolutionUniqueName'    = $SolutionUniqueName
    }
    if ($ReturnRepresentation) { $headers['Prefer'] = 'return=representation' }
    $params = @{ Method = $Method; Uri = "$Api/$Path"; Headers = $headers }
    if ($null -ne $Body) {
        $params.Body = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Body -Depth 30 -Compress))
        $params.ContentType = 'application/json; charset=utf-8'
    }
    try { return Invoke-RestMethod @params }
    catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        throw "Dataverse call failed (HTTP $code): $Method $Path`n$detail"
    }
}

function Test-Dv([string]$Path) {
    try { Invoke-Dv -Method GET -Path $Path | Out-Null; return $true }
    catch { if ("$_" -match 'HTTP 404|does not exist|Could not find|not found') { return $false }; throw }
}

# ---------------------------------------------------------------- schema

$p = $Prefix
function OV([int]$i) { return ($OptionValuePrefix * 10000) + $i }

# Global choices: name => display, options
$Choices = [ordered]@{
    status            = @('Agent status', @('Draft', 'Submitted', 'Changes requested', 'Approved', 'Rejected', 'Live', 'Review due', 'Retired'))
    risktier          = @('Risk tier', @('Tier 1 - Low', 'Tier 2 - Medium', 'Tier 3 - High'))
    triageresult      = @('Triage result', @('Negligible', 'In inventory'))
    audience          = @('Agent audience', @('Internal staff', 'Specific team', 'Customers', 'Partners'))
    channel           = @('Agent channel', @('Teams', 'Microsoft 365 Copilot', 'Website', 'Other'))
    dataclass         = @('Data classification', @('Public', 'Internal', 'Confidential', 'Restricted'))
    ratinglevel       = @('Rating level', @('Low', 'Medium', 'High'))
    authtype          = @('End-user authentication', @('Microsoft Entra ID', 'None', 'Other'))
    monitoringstatus  = @('Monitoring status', @('Normal', 'Exceptions'))
    reviewerrole      = @('Reviewer role', @('Platform', 'Security', 'Privacy', 'Risk'))
    decision          = @('Approval decision', @('Approve', 'Reject', 'Changes requested'))
    sourcetype        = @('Knowledge source type', @('SharePoint', 'File', 'Website', 'Dataverse', 'Connector', 'Other'))
    readwrite         = @('Read or write', @('Read', 'Write'))
    runas             = @('Runs as', @('User', 'Maker', 'Service account'))
    testcategory      = @('Test category', @('Core', 'Paraphrase', 'Edge case', 'Out of scope', 'Adversarial', 'Sensitive data', 'Multi-turn', 'Action', 'Escalation'))
    score             = @('Score', @('0 - Fail', '1 - Partial', '2 - Pass', 'N/A'))
    caseresult        = @('Test result', @('Pass', 'Fail', 'Critical fail'))
    runtrigger        = @('Evaluation trigger', @('New agent', 'Configuration change', 'Knowledge change', 'Model change', 'Performance breach', 'Scheduled review'))
    releasedecision   = @('Release decision', @('Release', 'Release with conditions', 'Block'))
    refresh           = @('Refresh cycle', @('Live', 'Daily', 'Weekly', 'Monthly', 'Ad hoc'))
}

# Column shorthand: name, display, kind, extra
# kinds: text, url, memo, bigmemo, int, decimal, bool, date, datetime, choice:<name>, multi:<name>
$Tables = [ordered]@{
    agentregister = @{
        Display = 'Agent Register'; Plural = 'Agent Register'; PrimaryDisplay = 'Agent name'
        Description = 'One row per Copilot Studio agent: ownership, fact sheet, risk rating, approval and review status.'
        Columns = @(
            @('agentid', 'Agent ID', 'text'),
            @('environment', 'Environment', 'text'),
            @('channels', 'Channels', 'multi:channel'),
            @('audience', 'Audience', 'choice:audience'),
            @('status', 'Status', 'choice:status'),
            @('factsheetversion', 'Fact sheet version', 'text'),
            # Purpose and boundaries
            @('businesspurpose', 'What it does', 'memo'),
            @('approveduses', 'Approved uses', 'memo'),
            @('intendedusers', 'Intended users', 'memo'),
            @('expectedbenefit', 'Expected benefit', 'memo'),
            @('outofscope', 'Out of scope', 'memo'),
            @('decisionsnotmade', 'Decisions it does not make', 'memo'),
            @('datanever', 'Data it must never return', 'memo'),
            # Risk classification
            @('triageresult', 'Triage result', 'choice:triageresult'),
            @('risktier', 'Risk tier', 'choice:risktier'),
            @('ratingrationale', 'Rating rationale', 'memo'),
            @('ratedon', 'Rated on', 'date'),
            @('dimbusinessuse', 'Rating: business use', 'choice:ratinglevel'),
            @('dimcustomerimpact', 'Rating: customer impact', 'choice:ratinglevel'),
            @('dimautonomy', 'Rating: complexity and autonomy', 'choice:ratinglevel'),
            @('diminputdata', 'Rating: input data', 'choice:ratinglevel'),
            @('dimregulatory', 'Rating: regulatory exposure', 'choice:ratinglevel'),
            @('dimscale', 'Rating: scale and impact', 'choice:ratinglevel'),
            @('dataclassification', 'Highest data classification', 'choice:dataclass'),
            @('usespersonalinfo', 'Uses personal information', 'bool'),
            @('performswrites', 'Performs write actions', 'bool'),
            @('actsautonomously', 'Acts autonomously', 'bool'),
            # Model origin and configuration
            @('foundationmodel', 'Foundation model', 'text'),
            @('orchestration', 'Orchestration', 'text'),
            @('authentication', 'End-user authentication', 'choice:authtype'),
            @('autonomoustriggers', 'Autonomous triggers', 'memo'),
            @('instructionssummary', 'Instructions summary', 'memo'),
            @('contentsafety', 'Content safety settings', 'memo'),
            @('knownlimitations', 'Known limitations', 'memo'),
            # Review, approval, evaluation
            @('firstdeployed', 'First deployed to production', 'date'),
            @('approvedon', 'Approved on', 'date'),
            @('lastreview', 'Most recent review', 'date'),
            @('nextreviewdue', 'Next review due', 'date'),
            @('latestpassrate', 'Latest evaluation pass rate (%)', 'decimal'),
            @('criticalfailures', 'Critical evaluation failures', 'int'),
            @('compliancecase', 'Open Compliance Hub case', 'text'),
            @('approvedsnapshot', 'Approved configuration snapshot', 'bigmemo'),
            # Monitoring and support
            @('escalationpath', 'Human escalation path', 'memo'),
            @('reportproblems', 'How users report problems', 'memo'),
            @('monitored', 'What is monitored', 'memo'),
            @('monitoringstatus', 'Monitoring status', 'choice:monitoringstatus'),
            @('fallback', 'If the agent fails', 'memo')
        )
        UserLookups = @(
            @('businessowner', 'Business owner'),
            @('technicalowner', 'Technical owner'),
            @('ratedby', 'Rated by'),
            @('independentreviewer', 'Independent reviewer')
        )
    }
    knowledgesource = @{
        Display = 'Agent Knowledge Source'; Plural = 'Agent Knowledge Sources'; PrimaryDisplay = 'Source'
        Description = 'Knowledge sources an agent uses, with classification, owner and refresh cycle.'
        Parent = 'agentregister'
        Columns = @(
            @('sourcetype', 'Type', 'choice:sourcetype'),
            @('classification', 'Classification', 'choice:dataclass'),
            @('contentowner', 'Content owner', 'text'),
            @('refresh', 'Refresh', 'choice:refresh')
        )
    }
    agenttool = @{
        Display = 'Agent Tool'; Plural = 'Agent Tools'; PrimaryDisplay = 'Action'
        Description = 'Tools, actions and connectors an agent can call.'
        Parent = 'agentregister'
        Columns = @(
            @('targetsystem', 'Target system', 'text'),
            @('readwrite', 'Read or write', 'choice:readwrite'),
            @('runas', 'Runs as', 'choice:runas'),
            @('userconfirms', 'User confirms first', 'bool')
        )
    }
    agentapproval = @{
        Display = 'Agent Approval'; Plural = 'Agent Approvals'; PrimaryDisplay = 'Approval'
        Description = 'One row per reviewer decision on an agent submission.'
        Parent = 'agentregister'
        Columns = @(
            @('reviewerrole', 'Reviewer role', 'choice:reviewerrole'),
            @('decision', 'Decision', 'choice:decision'),
            @('comments', 'Comments', 'memo'),
            @('decidedon', 'Decided on', 'datetime')
        )
        UserLookups = @(,@('reviewer', 'Reviewer'))
    }
    agentreview = @{
        Display = 'Agent Review'; Plural = 'Agent Reviews'; PrimaryDisplay = 'Review'
        Description = 'Periodic reviews and re-attestations.'
        Parent = 'agentregister'
        Columns = @(
            @('reviewdate', 'Review date', 'date'),
            @('stillneeded', 'Still needed', 'bool'),
            @('materialchange', 'Material change since approval', 'bool'),
            @('rerunpassrate', 'Evaluation re-run pass rate (%)', 'decimal'),
            @('notes', 'Notes', 'memo')
        )
        UserLookups = @(,@('attestedby', 'Attested by'))
    }
    changelog = @{
        Display = 'Agent Change'; Plural = 'Agent Changes'; PrimaryDisplay = 'Change'
        Description = 'Change log: instructions, knowledge, tools, model, audience and owners.'
        Parent = 'agentregister'
        Columns = @(
            @('changedate', 'Change date', 'date'),
            @('version', 'Version', 'text'),
            @('reevaluated', 'Re-evaluated', 'bool')
        )
        UserLookups = @(,@('changedby', 'Changed by'))
    }
    testcase = @{
        Display = 'Agent Test Case'; Plural = 'Agent Test Cases'; PrimaryDisplay = 'Test ID'
        Description = 'Evaluation test cases for an agent.'
        Parent = 'agentregister'
        Columns = @(
            @('category', 'Category', 'choice:testcategory'),
            @('userinput', 'User input', 'memo'),
            @('expectedbehaviour', 'Expected behaviour', 'memo'),
            @('approvedsource', 'Approved source', 'text'),
            @('grader', 'Grader or test type', 'text')
        )
    }
    evaluationrun = @{
        Display = 'Agent Evaluation Run'; Plural = 'Agent Evaluation Runs'; PrimaryDisplay = 'Run'
        Description = 'One row per evaluation or regression run, with the release decision.'
        Parent = 'agentregister'
        Columns = @(
            @('rundate', 'Run date', 'date'),
            @('agentversion', 'Agent version', 'text'),
            @('trigger', 'Trigger', 'choice:runtrigger'),
            @('whatchanged', 'What changed', 'memo'),
            @('casesrun', 'Cases run', 'int'),
            @('passrate', 'Pass rate (%)', 'decimal'),
            @('criticalfailures', 'Critical failures', 'int'),
            @('graderalignment', 'AI grader alignment (%)', 'decimal'),
            @('decision', 'Decision', 'choice:releasedecision')
        )
        UserLookups = @(,@('reviewer', 'Reviewer'))
    }
    testresult = @{
        Display = 'Agent Test Result'; Plural = 'Agent Test Results'; PrimaryDisplay = 'Result'
        Description = 'Score for one test case in one evaluation run.'
        Parent = 'evaluationrun'
        Columns = @(
            @('actualresponse', 'Actual response (summary)', 'memo'),
            @('scoreaccuracy', 'Accuracy', 'choice:score'),
            @('scoregrounding', 'Grounding', 'choice:score'),
            @('scorecompleteness', 'Completeness', 'choice:score'),
            @('scorescope', 'Scope and refusal', 'choice:score'),
            @('scoresafety', 'Safety and data handling', 'choice:score'),
            @('scoreaction', 'Action correctness', 'choice:score'),
            @('scoretone', 'Tone and clarity', 'choice:score'),
            @('result', 'Result', 'choice:caseresult')
        )
        ExtraLookups = @(,@('testcase', 'Test case', 'testcase'))
    }
}

# ---------------------------------------------------------------- builders

function Get-AttributeBody($col) {
    $name, $display, $kind = $col
    $schema = "${p}_$name"
    $common = { param($h) $h.SchemaName = $schema; $h.DisplayName = (New-Label $display); $h.Description = (New-Label $display); $h.RequiredLevel = (New-Required) ; $h }
    switch -Regex ($kind) {
        '^text$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'; AttributeType = 'String'; AttributeTypeName = @{ Value = 'StringType' }; MaxLength = 200; FormatName = @{ Value = 'Text' } }
            return & $common $h
        }
        '^url$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'; AttributeType = 'String'; AttributeTypeName = @{ Value = 'StringType' }; MaxLength = 500; FormatName = @{ Value = 'Url' } }
            return & $common $h
        }
        '^memo$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'; AttributeType = 'Memo'; AttributeTypeName = @{ Value = 'MemoType' }; Format = 'TextArea'; ImeMode = 'Disabled'; MaxLength = 4000 }
            return & $common $h
        }
        '^bigmemo$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'; AttributeType = 'Memo'; AttributeTypeName = @{ Value = 'MemoType' }; Format = 'TextArea'; ImeMode = 'Disabled'; MaxLength = 100000 }
            return & $common $h
        }
        '^int$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.IntegerAttributeMetadata'; AttributeType = 'Integer'; AttributeTypeName = @{ Value = 'IntegerType' }; Format = 'None'; MinValue = 0; MaxValue = 1000000 }
            return & $common $h
        }
        '^decimal$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.DecimalAttributeMetadata'; AttributeType = 'Decimal'; AttributeTypeName = @{ Value = 'DecimalType' }; Precision = 2; MinValue = 0; MaxValue = 100 }
            return & $common $h
        }
        '^bool$' {
            $h = [ordered]@{
                '@odata.type' = 'Microsoft.Dynamics.CRM.BooleanAttributeMetadata'; AttributeType = 'Boolean'; AttributeTypeName = @{ Value = 'BooleanType' }; DefaultValue = $false
                OptionSet = [ordered]@{
                    '@odata.type' = 'Microsoft.Dynamics.CRM.BooleanOptionSetMetadata'
                    TrueOption    = [ordered]@{ Value = 1; Label = (New-Label 'Yes') }
                    FalseOption   = [ordered]@{ Value = 0; Label = (New-Label 'No') }
                    OptionSetType = 'Boolean'
                }
            }
            return & $common $h
        }
        '^date$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'; AttributeType = 'DateTime'; AttributeTypeName = @{ Value = 'DateTimeType' }; Format = 'DateOnly'; DateTimeBehavior = @{ Value = 'DateOnly' } }
            return & $common $h
        }
        '^datetime$' {
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'; AttributeType = 'DateTime'; AttributeTypeName = @{ Value = 'DateTimeType' }; Format = 'DateAndTime'; DateTimeBehavior = @{ Value = 'UserLocal' } }
            return & $common $h
        }
        '^choice:(.+)$' {
            $os = "${p}_$($Matches[1])"
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'; AttributeType = 'Picklist'; AttributeTypeName = @{ Value = 'PicklistType' } }
            $h = & $common $h
            $h['GlobalOptionSet@odata.bind'] = "/GlobalOptionSetDefinitions($($script:OptionSetIds[$os]))"
            return $h
        }
        '^multi:(.+)$' {
            $os = "${p}_$($Matches[1])"
            $h = [ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.MultiSelectPicklistAttributeMetadata'; AttributeType = 'Virtual'; AttributeTypeName = @{ Value = 'MultiSelectPicklistType' } }
            $h = & $common $h
            $h['GlobalOptionSet@odata.bind'] = "/GlobalOptionSetDefinitions($($script:OptionSetIds[$os]))"
            return $h
        }
        default { throw "Unknown column kind '$kind' for $name" }
    }
}

function New-Relationship([string]$referenced, [string]$referencedId, [string]$referencing, [string]$lookupName, [string]$lookupDisplay, [string]$deleteBehaviour) {
    $relSchema = "${referencing}_${lookupName}".ToLower()
    $lookupSchema = "${p}_$lookupName"
    if ($WhatIf) { Write-Plan "lookup $referencing.$lookupSchema -> $referenced"; return }
    if (Test-Dv "RelationshipDefinitions(SchemaName='$relSchema')?`$select=SchemaName") { Write-Skip "lookup $lookupSchema on $referencing"; return }
    $body = [ordered]@{
        '@odata.type'              = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
        SchemaName                 = $relSchema
        ReferencedEntity           = $referenced
        ReferencedAttribute        = $referencedId
        ReferencingEntity          = $referencing
        AssociatedMenuConfiguration = [ordered]@{ Behavior = 'UseCollectionName'; Group = 'Details'; Label = (New-Label $lookupDisplay); Order = 10000 }
        CascadeConfiguration       = [ordered]@{ Assign = 'NoCascade'; Delete = $deleteBehaviour; Merge = 'NoCascade'; Reparent = 'NoCascade'; Share = 'NoCascade'; Unshare = 'NoCascade' }
        Lookup                     = [ordered]@{
            '@odata.type'     = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            AttributeType     = 'Lookup'
            AttributeTypeName = @{ Value = 'LookupType' }
            SchemaName        = $lookupSchema
            DisplayName       = (New-Label $lookupDisplay)
            Description       = (New-Label $lookupDisplay)
            RequiredLevel     = (New-Required)
        }
    }
    Invoke-Dv -Method POST -Path 'RelationshipDefinitions' -Body $body | Out-Null
    Write-Done "lookup $lookupSchema on $referencing -> $referenced"
}

# ---------------------------------------------------------------- run

Write-Host "Responsible Agent Toolkit - Dataverse build" -ForegroundColor White
Write-Host "Environment: $EnvironmentUrl"
Write-Host "Solution:    $SolutionUniqueName  (prefix '$p', option values from $(OV 0))"
if ($WhatIf) { Write-Host "DRY RUN - nothing will be created." -ForegroundColor Yellow }
else { $script:Token = Get-Token }

# 1. Publisher and solution
Write-Step 'Publisher and solution'
if ($WhatIf) {
    Write-Plan "publisher '$PublisherUniqueName' and solution '$SolutionUniqueName'"
} else {
    $pub = Invoke-Dv -Method GET -Path "publishers?`$select=publisherid,customizationprefix&`$filter=uniquename eq '$PublisherUniqueName'"
    if ($pub.value.Count -gt 0) {
        $publisherId = $pub.value[0].publisherid
        if ($pub.value[0].customizationprefix -ne $p) { throw "Publisher '$PublisherUniqueName' exists with prefix '$($pub.value[0].customizationprefix)', not '$p'. Use -Prefix $($pub.value[0].customizationprefix) or another publisher name." }
        Write-Skip "publisher $PublisherUniqueName"
    } else {
        $r = Invoke-Dv -Method POST -Path 'publishers' -ReturnRepresentation -Body ([ordered]@{
            uniquename = $PublisherUniqueName; friendlyname = $PublisherFriendlyName
            customizationprefix = $p; customizationoptionvalueprefix = $OptionValuePrefix
            description = 'Publisher for the Responsible Agent Toolkit'
        })
        $publisherId = $r.publisherid
        Write-Done "publisher $PublisherUniqueName"
    }
    $sol = Invoke-Dv -Method GET -Path "solutions?`$select=solutionid&`$filter=uniquename eq '$SolutionUniqueName'"
    if ($sol.value.Count -gt 0) { Write-Skip "solution $SolutionUniqueName" }
    else {
        Invoke-Dv -Method POST -Path 'solutions' -Body ([ordered]@{
            uniquename = $SolutionUniqueName; friendlyname = $SolutionFriendlyName; version = '1.0.0.0'
            description = 'Agent register, fact sheet, approvals, reviews and evaluations for Copilot Studio agents'
            'publisherid@odata.bind' = "/publishers($publisherId)"
        }) | Out-Null
        Write-Done "solution $SolutionUniqueName"
    }
}

# 2. Global choices
Write-Step 'Choices'
$script:OptionSetIds = @{}
foreach ($key in $Choices.Keys) {
    $name = "${p}_$key"
    $display, $labels = $Choices[$key]
    if ($WhatIf) { Write-Plan "choice $name ($($labels -join ', '))"; $script:OptionSetIds[$name] = '00000000-0000-0000-0000-000000000000'; continue }
    $existing = $null
    try { $existing = Invoke-Dv -Method GET -Path "GlobalOptionSetDefinitions(Name='$name')?`$select=MetadataId" } catch { if ("$_" -notmatch 'HTTP 404|not found|Could not find|does not exist') { throw } }
    if ($existing) { $script:OptionSetIds[$name] = $existing.MetadataId; Write-Skip "choice $name"; continue }
    $i = 0
    $options = @(foreach ($l in $labels) { [ordered]@{ Value = (OV $i); Label = (New-Label $l) }; $i++ })
    Invoke-Dv -Method POST -Path 'GlobalOptionSetDefinitions' -Body ([ordered]@{
        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
        Name = $name; DisplayName = (New-Label $display); Description = (New-Label $display)
        OptionSetType = 'Picklist'; IsGlobal = $true; Options = $options
    }) | Out-Null
    $osResult = Invoke-Dv -Method GET -Path "GlobalOptionSetDefinitions(Name='$name')?`$select=MetadataId"
    $script:OptionSetIds[$name] = $osResult.MetadataId
    Write-Done "choice $name"
}

# 3. Tables with primary name column
Write-Step 'Tables'
foreach ($key in $Tables.Keys) {
    $t = $Tables[$key]; $logical = "${p}_$key"
    if ($WhatIf) { Write-Plan "table $logical ($($t.Display))"; continue }
    if (Test-Dv "EntityDefinitions(LogicalName='$logical')?`$select=LogicalName") { Write-Skip "table $logical"; continue }
    $body = [ordered]@{
        '@odata.type'          = 'Microsoft.Dynamics.CRM.EntityMetadata'
        SchemaName             = $logical
        DisplayName            = (New-Label $t.Display)
        DisplayCollectionName  = (New-Label $t.Plural)
        Description            = (New-Label $t.Description)
        OwnershipType          = 'UserOwned'
        IsActivity             = $false
        HasActivities          = $false
        HasNotes               = $true
        PrimaryNameAttribute   = "${p}_name"
        Attributes             = @([ordered]@{
            '@odata.type'     = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
            AttributeType     = 'String'
            AttributeTypeName = @{ Value = 'StringType' }
            SchemaName        = "${p}_name"
            IsPrimaryName     = $true
            MaxLength         = 200
            FormatName        = @{ Value = 'Text' }
            RequiredLevel     = (New-Required 'ApplicationRequired')
            DisplayName       = (New-Label $t.PrimaryDisplay)
            Description       = (New-Label $t.PrimaryDisplay)
        })
    }
    Invoke-Dv -Method POST -Path 'EntityDefinitions' -Body $body | Out-Null
    Write-Done "table $logical ($($t.Display))"
}

# 4. Columns
Write-Step 'Columns'
foreach ($key in $Tables.Keys) {
    $t = $Tables[$key]; $logical = "${p}_$key"
    foreach ($col in $t.Columns) {
        $attr = "${p}_$($col[0])"
        if ($WhatIf) { Write-Plan "column $logical.$attr ($($col[2]))"; continue }
        if (Test-Dv "EntityDefinitions(LogicalName='$logical')/Attributes(LogicalName='$attr')?`$select=LogicalName") { Write-Skip "column $logical.$attr"; continue }
        Invoke-Dv -Method POST -Path "EntityDefinitions(LogicalName='$logical')/Attributes" -Body (Get-AttributeBody $col) | Out-Null
        Write-Done "column $logical.$attr"
    }
}

# 5. Lookups
Write-Step 'Lookups'
foreach ($key in $Tables.Keys) {
    $t = $Tables[$key]; $logical = "${p}_$key"
    if ($t.Parent) {
        $parent = "${p}_$($t.Parent)"
        # Restrict: a register entry cannot be deleted while its records exist (keeps evidence for retention).
        $parentLookup = if ($t.Parent -eq 'agentregister') { 'agent' } else { 'run' }
        $parentDisplay = if ($t.Parent -eq 'agentregister') { 'Agent' } else { 'Evaluation run' }
        New-Relationship -referenced $parent -referencedId "${parent}id" -referencing $logical -lookupName $parentLookup -lookupDisplay $parentDisplay -deleteBehaviour 'Restrict'
    }
    foreach ($lk in @($t.ExtraLookups)) {
        if (-not $lk) { continue }
        $target = "${p}_$($lk[2])"
        New-Relationship -referenced $target -referencedId "${target}id" -referencing $logical -lookupName $lk[0] -lookupDisplay $lk[1] -deleteBehaviour 'Restrict'
    }
    foreach ($u in @($t.UserLookups)) {
        if (-not $u) { continue }
        New-Relationship -referenced 'systemuser' -referencedId 'systemuserid' -referencing $logical -lookupName $u[0] -lookupDisplay $u[1] -deleteBehaviour 'RemoveLink'
    }
}

# 6. Optional link to Copilot Agent Kit Agent Details
if ($AgentDetailsTable) {
    Write-Step "Link to Copilot Agent Kit table '$AgentDetailsTable'"
    if ($WhatIf) { Write-Plan "lookup ${p}_agentregister.${p}_agentdetails -> $AgentDetailsTable" }
    else {
        $ad = $null
        try { $ad = Invoke-Dv -Method GET -Path "EntityDefinitions(LogicalName='$AgentDetailsTable')?`$select=LogicalName,PrimaryIdAttribute" } catch { }
        if (-not $ad) {
            Write-Warning "Table '$AgentDetailsTable' not found in this environment. Install the Copilot Agent Kit with Agent Inventory here, or check the logical name, then re-run."
        } else {
            New-Relationship -referenced $AgentDetailsTable -referencedId $ad.PrimaryIdAttribute -referencing "${p}_agentregister" -lookupName 'agentdetails' -lookupDisplay 'Agent (inventory)' -deleteBehaviour 'RemoveLink'
        }
    }
}

# 7. Publish
if (-not $WhatIf -and -not $SkipPublish) {
    Write-Step 'Publishing customizations (can take a few minutes)'
    Invoke-Dv -Method POST -Path 'PublishAllXml' -Body @{} | Out-Null
    Write-Done 'published'
}

Write-Host "`nFinished. Created: $script:Created  Skipped: $script:Skipped" -ForegroundColor White
if (-not $WhatIf) {
    Write-Host "Next: open make.powerapps.com > Solutions > $SolutionFriendlyName, then build the model-driven app, forms, views and flows." -ForegroundColor White
}
