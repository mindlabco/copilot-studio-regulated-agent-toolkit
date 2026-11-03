# Responsible Agent Toolkit for Copilot Studio

Governance templates for teams running Microsoft Copilot Studio agents in regulated industries, with a focus on Canadian financial services and OSFI Guideline E-23 (Model Risk Management).

The toolkit is designed to sit **beside** Microsoft's [Copilot Agent Kit](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-overview) (formerly the Copilot Studio Kit), not replace it. The Kit's Agent Inventory and Compliance Hub capture a lot of technical detail about your agents. This toolkit adds the governance layer a model risk function will ask for: ownership, approved uses, risk rating, evaluation evidence, review dates and retirement records.

> **Not legal or regulatory advice.** These are a practitioner's working templates. Risk-rating matrices, test counts, thresholds, approvers and review intervals are **illustrative examples, not standards**. Your institution's model risk management, compliance and legal teams decide how E-23 or any other rule applies to your agents. Verify product features in your own tenant before relying on them.

## What's inside

| Piece | What it is | Format |
|---|---|---|
| [OSFI E-23 and Copilot Studio Agents](docs/OSFI-E23-Copilot-Studio-Agent-Map.md) | Each E-23 principle mapped to what Copilot Studio and the Kit already cover, and what you still need to add. Includes triage questions, an inventory field crosswalk, an example risk-rating matrix and review triggers for agents. | [Word](docs/OSFI-E23-Copilot-Studio-Agent-Map.docx) |
| [Agent Fact Sheet](docs/Agent-Fact-Sheet-Template-v2.md) | One page per agent: purpose, owners, approved and prohibited uses, model and data sources, risk rating, evaluation results and review dates. Every field is marked **Auto** (copy from the Kit's Agent Inventory) or **Manual** (only a person can answer). | [Word](docs/Agent-Fact-Sheet-Template-v2.docx) |
| [Agent Evaluation Pack](docs/Agent-Evaluation-Pack-v2.md) | Scoring areas mapped to Copilot Studio's built-in graders and the Kit's test types, with minimum test sets by risk tier and an independent-reviewer rule for higher-risk agents. | [Word](docs/Agent-Evaluation-Pack-v2.docx) |
| [Agent Register Extension](docs/Agent-Register-Extension-for-Compliance-Hub.md) | The data model and flows that add only what the Kit's Compliance Hub doesn't hold: risk tier, approvals, attestations, change detection, review reminders and retirement. | [Word](docs/Agent-Register-Extension-for-Compliance-Hub.docx) |
| [Build-AgentGovernanceTables.ps1](scripts/Build-AgentGovernanceTables.ps1) | Creates the register's Dataverse tables, choices and relationships in one re-runnable step. Safe to re-run; it skips anything that already exists. | PowerShell |

The Markdown files are for reading on GitHub. The Word files are the source versions, ready to adapt.

## Getting started

1. **Read the E-23 map first.** It explains why a Copilot Studio agent can fall inside E-23's definition of a model, and which agents are candidates for a negligible-risk category.
2. **Install the Copilot Agent Kit** in a development environment and run Agent Inventory, so the Auto fields have a source.
3. **Pilot the Fact Sheet** on one or two agents with their business owners.
4. **Agree your own thresholds** for the rating matrix and evaluation minimums with your model risk team.
5. **Build the register** when you're ready to run it as an app (see below).

## Running the Dataverse script

Requires PowerShell 7 and either the Azure CLI (`az login`) or the Az PowerShell module (`Connect-AzAccount`). Run it in a **development** environment first.

```powershell
# Dry run: shows what would be created, calls nothing, needs no sign-in
./scripts/Build-AgentGovernanceTables.ps1 -EnvironmentUrl https://yourorg-dev.crm3.dynamics.com -WhatIf

# Create the tables
./scripts/Build-AgentGovernanceTables.ps1 -EnvironmentUrl https://yourorg-dev.crm3.dynamics.com

# Optional: add a lookup to the Kit's Agent Details table
./scripts/Build-AgentGovernanceTables.ps1 -EnvironmentUrl https://yourorg-dev.crm3.dynamics.com -AgentDetailsTable <logical name>
```

The script creates the tables, choices and relationships only. You still build the model-driven app, forms, views, flows and security roles yourself, using the Register Extension document as the specification.

## Contributing

Issues and pull requests are welcome, especially from people working in model risk, audit, compliance and Power Platform governance. Useful contributions include:

- Corrections to the E-23 mapping, or mappings to other regulations
- Field changes as the Copilot Agent Kit evolves
- Forms, views and flows built on the Dataverse tables
- Examples of how you've adapted the rating matrix (anonymised)

Please don't include anything that identifies your employer, clients or internal systems.

## Sources

- [OSFI Guideline E-23: Model Risk Management (2027)](https://www.osfi-bsif.gc.ca/en/guidance/guidance-library/guideline-e-23-model-risk-management-2027)
- [Copilot Agent Kit: Compliance Hub](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-configure-compliance-hub)
- [Copilot Agent Kit: Agent Inventory data source](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-agent-inventory-data-source)
- [Copilot Agent Kit: Configure tests](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-configure-tests)

## About

Maintained by Paras Dodhia, a Copilot Studio and Power Platform architect working on AI agents in regulated industries. This is a personal community project and isn't affiliated with, sponsored by or endorsed by Microsoft or any employer.

- LinkedIn: [linkedin.com/in/mindlab](https://www.linkedin.com/in/mindlab)
- Blog: [The Signal](https://blog.dodhia.co)

## Licence

Code (`scripts/`) is licensed under the [MIT License](LICENSE). Documents (`docs/`) are licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/): you can share and adapt them, including commercially, with credit.
