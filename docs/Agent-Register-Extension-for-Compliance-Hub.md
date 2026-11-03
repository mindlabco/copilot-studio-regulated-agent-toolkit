**RESPONSIBLE AGENT TOOLKIT**

**Agent Register Extension**

A small Dataverse add-on that sits beside the Copilot Agent Kit’s Agent Inventory and Compliance Hub

|                                                                                                                                                                                                                                                                                                                                                                                                                            |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Design principle:** Do not rebuild what the Kit already does. Agent Inventory discovers agents and records their technical facts. The Compliance Hub checks them against your rules, opens cases and enforces deadlines. This extension adds only what a regulated institution needs on top: an inherent risk rating, an accountable owner, tiered approval, scheduled reviews and the remaining model inventory fields. |

# **1. What the Kit covers and what this adds**

| **Need**                                | **Copilot Agent Kit**                                                                    | **This extension**                                                                  |
|-----------------------------------------|------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| **Find every agent**                    | Agent Inventory, daily scan                                                              | — (uses Agent Inventory)                                                            |
| **Record technical facts**              | Agent Details table (authentication, knowledge, tools, orchestration, triggers and more) | — (reads Agent Details)                                                             |
| **Check agents against rules**          | Compliance Hub thresholds and cases                                                      | — (uses Compliance Hub)                                                             |
| **Enforce deadlines**                   | Action policies: reminder, quarantine, delete                                            | Recommends quarantine as the strongest automatic action                             |
| **Short business intake**               | Justification, data classification, expected users                                       | Links to the full Agent Fact Sheet                                                  |
| **Inherent risk rating on every agent** | Not covered (case risk levels describe rule violations)                                  | Rating, rationale, date and rater                                                   |
| **Accountable owner**                   | Not covered (created and modified by only)                                               | Business owner and technical owner                                                  |
| **Tiered approval**                     | Single admin approve or reject per case                                                  | Required approvers by tier                                                          |
| **Scheduled review**                    | Not covered (event driven)                                                               | Review interval by tier, reminders, re-attestation                                  |
| **Model inventory fields**              | Partial                                                                                  | Approved uses, reviewer, approver, deployment date, review dates, monitoring status |
| **Retirement with retention**           | Not covered                                                                              | Retired status; fact sheet and evaluation evidence kept                             |

*Based on Microsoft’s documentation for the Kit as of October 2026. Check your installed version before building; the Kit is updated often.*

# **2. Data model**

One main table, linked one-to-one to Agent Inventory’s Agent Details by agent ID, plus two child tables. Keep them in your own solution, separate from the Kit, so Kit upgrades do not overwrite them.

## **2.1 Agent Register**

| **Column**                          | **Type**               | **Notes**                                                                                 |
|-------------------------------------|------------------------|-------------------------------------------------------------------------------------------|
| **Agent**                           | Lookup (Agent Details) | One register row per agent; created automatically by flow                                 |
| **Agent ID**                        | Text                   | Copied from Agent Details for reporting and pipeline checks                               |
| **Business owner**                  | Lookup (User)          | Accountable for outcomes and re-attestation                                               |
| **Technical owner**                 | Lookup (User)          | Developer and maintainer                                                                  |
| **Triage result**                   | Choice                 | Negligible / In inventory                                                                 |
| **Risk tier**                       | Choice                 | Tier 1 Low / Tier 2 Medium / Tier 3 High                                                  |
| **Rating rationale**                | Multiline text         | Scores by dimension or explanation                                                        |
| **Rated on, Rated by**              | Date, Lookup (User)    | Who assigned or last confirmed the rating                                                 |
| **Approved uses**                   | Multiline text         | Mirrors fact sheet section 2                                                              |
| **Foundation model**                | Text                   | Selected model or "platform default"                                                      |
| **Fact sheet**                      | URL                    | Link to the completed Agent Fact Sheet                                                    |
| **Latest evaluation pass rate**     | Decimal                | From the most recent evaluation run                                                       |
| **Critical evaluation failures**    | Whole number           | Must be 0 to submit                                                                       |
| **Independent reviewer**            | Lookup (User)          | Required for Tier 2 and Tier 3                                                            |
| **Status**                          | Choice                 | Draft / Submitted / Changes requested / Approved / Rejected / Live / Review due / Retired |
| **First deployed to production**    | Date                   | Set when status first moves to Live                                                       |
| **Approved on**                     | Date                   | Set when the final approval is recorded                                                   |
| **Last review, Next review due**    | Date, Date             | Next review = last review + interval for tier                                             |
| **Monitoring status**               | Choice                 | Normal / Exceptions                                                                       |
| **Approved configuration snapshot** | Multiline text         | JSON of key Agent Details columns at approval, used to detect changes                     |

## **2.2 Agent Approval**

| **Column**         | **Type**       | **Notes**                                 |
|--------------------|----------------|-------------------------------------------|
| **Agent Register** | Lookup         | Parent record                             |
| **Reviewer role**  | Choice         | Platform / Security / Privacy / Risk      |
| **Reviewer**       | Lookup (User)  | Who responded                             |
| **Decision**       | Choice         | Approve / Reject / Changes requested      |
| **Comments**       | Multiline text | Required for Reject and Changes requested |
| **Decided on**     | Date and time  | Set by flow                               |

## **2.3 Agent Review**

| **Column**                          | **Type**      | **Notes**                      |
|-------------------------------------|---------------|--------------------------------|
| **Agent Register**                  | Lookup        | Parent record                  |
| **Review date**                     | Date          |                                |
| **Still needed?**                   | Yes/No        | No moves the agent to Retired  |
| **Material change since approval?** | Yes/No        | Yes requires resubmission      |
| **Evaluation re-run pass rate**     | Decimal       | From the latest regression run |
| **Attested by**                     | Lookup (User) | Business owner                 |

# **3. Risk tiers**

Rate inherent risk with the matrix in the OSFI E-23 map, or your institution’s own criteria. The tier then drives everything else:

| **Tier**            | **Required approvers**               | **Evaluation**                         | **Review interval** |
|---------------------|--------------------------------------|----------------------------------------|---------------------|
| **Tier 1 – Low**    | Platform                             | Tier 1 minimums; maker may self-review | 12 months           |
| **Tier 2 – Medium** | Platform + Security                  | Tier 2 minimums; independent reviewer  | 12 months           |
| **Tier 3 – High**   | Platform + Security + Privacy + Risk | Tier 3 minimums; independent reviewer  | 6 months            |

*Approvers and intervals are illustrative. Set them with your risk function and store them as environment variables, not in flow logic.*

# **4. Flows**

## **4.1 New agent detected**

*Trigger: a row is added to Agent Details (Agent Inventory’s daily scan).*

1.  Create an Agent Register row with Status Draft, linked to the agent.

2.  Notify the agent’s creator: name a business owner, complete the fact sheet and request a rating.

3.  If no owner is named within an agreed period, notify the platform team.

## **4.2 Submit for approval**

*Trigger: Status changes to Submitted.*

1.  Check required fields, the fact sheet link, the evaluation pass rate, zero critical failures and, for Tier 2 and 3, an independent reviewer who is not the technical owner. On failure, return to Draft with reasons.

2.  Look up required approvers for the tier and start an approval in which all must respond.

3.  Write one Agent Approval row per response.

4.  All approve: set Approved, Approved on, Next review due, and save the approved configuration snapshot. Any reject: set Rejected. Otherwise: Changes requested.

5.  Notify both owners of the outcome.

## **4.3 Change detection**

*Trigger: scheduled, daily, after Agent Inventory completes.*

1.  For each Live agent, compare current Agent Details values (instructions, orchestration type, tools, connections, knowledge sources, triggers, authentication) with the approved snapshot.

2.  If anything material changed, notify the owners and require a regression run; for Tier 2 and 3, move Status to Review due.

*This catches configuration changes. It cannot see a change in the platform’s default model; cover that with scheduled re-testing and release-note monitoring.*

## **4.4 Review reminders and ownership**

*Trigger: scheduled, daily.*

1.  Remind business owners 30 days before Next review due.

2.  Past due: set Review due and notify owners and the platform team.

3.  Flag agents whose owners are disabled in Microsoft Entra ID for reassignment.

# **5. Working alongside the Compliance Hub**

- Add a Compliance Hub threshold for agents that have no approved register entry, so the Hub’s case and SLA process chases unregistered agents for you.

- Show open Compliance Hub cases on the register form, so reviewers see rule violations and inherent risk together.

- Consider changing the High risk action policy from Delete to Quarantine, and retire agents through the register so the fact sheet and evaluation evidence are kept. Model risk guidance such as OSFI E-23 expects decommissioned models and their documentation to be retained.

- Use the register’s Status in your deployment pipeline: only Approved or Live agents may be promoted to production.

# **6. Build checklist**

| **\#** | **Task**                                                                                                | **Done** |
|--------|---------------------------------------------------------------------------------------------------------|----------|
| 1      | Install the Copilot Agent Kit with Agent Inventory and Compliance Hub, and confirm the daily scan works |          |
| 2      | Create a separate solution and publisher for the extension                                              |          |
| 3      | Create the three tables from Section 2                                                                  |          |
| 4      | Create environment variables for approver groups and review intervals                                   |          |
| 5      | Add register views and forms to a model-driven app, including the Compliance Hub case subgrid           |          |
| 6      | Build flows 4.1 to 4.4 and test each tier                                                               |          |
| 7      | Add the Compliance Hub threshold for unregistered agents                                                |          |
| 8      | Review the High risk action policy with your risk function                                              |          |
| 9      | Add the pipeline status check                                                                           |          |
| 10     | Pilot with agents from two different tiers, then roll out                                               |          |

# **Sources**

- [<u>Copilot Agent Kit: Compliance Hub</u>](https://learn.microsoft.com/en-au/microsoft-copilot-studio/guidance/kit-configure-compliance-hub)

- [<u>Copilot Agent Kit: Agent Inventory data source</u>](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-agent-inventory-data-source)

- [<u>OSFI Guideline E-23 (2027)</u>](https://www.osfi-bsif.gc.ca/en/guidance/guidance-library/guideline-e-23-model-risk-management-2027)
