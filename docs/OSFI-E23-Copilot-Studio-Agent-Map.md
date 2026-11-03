**RESPONSIBLE AGENT TOOLKIT \| CANADIAN FINANCIAL SERVICES**

**OSFI E-23 and Copilot Studio Agents**

Mapping OSFI Guideline E-23 (Model Risk Management) to Copilot Studio, the Copilot Agent Kit and the Responsible Agent Toolkit

|                                                                                                                                                                                                                                                                                                                                                                       |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Important:** This is a practitioner’s working map, not legal or regulatory advice. It is based on the public text of Guideline E-23 and Microsoft’s public documentation as of October 2026. Each institution’s model risk management (MRM) function decides how E-23 applies to its own agents. Verify product features in your own tenant before relying on them. |

# **1. Why this matters now**

OSFI’s revised Guideline E-23 on Model Risk Management takes effect on May 1, 2027. It applies to federally regulated financial institutions in Canada: banks, foreign bank branches, insurers, and trust and loan companies. Its definition of a model explicitly includes AI and machine learning methods, and it expects model risk to be managed across the whole enterprise, across the whole model lifecycle, with intensity matched to risk.

Copilot Studio agents sit right in the path of that expectation. They take input (a user’s question plus grounding data), process it with one or more large language models, and produce results (answers, decisions, actions). Many institutions are building agents faster than their model inventories can track them. This document maps what E-23 expects to what Copilot Studio and the Copilot Agent Kit already provide, and shows where you have to add something yourself.

## **E-23 at a glance**

| **Outcome**                                                            | **Principles**                                                                                                                                                     |
|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **1. Model risk is well understood and managed across the enterprise** | 1.1 Organizational enablement \| 1.2 MRM framework \| 1.3 Use of models                                                                                            |
| **2. Model risk is managed using a risk-based approach**               | 2.1 Model identification \| 2.2 Model risk rating \| 2.3 Risk management intensity                                                                                 |
| **3. Model governance covers the entire model lifecycle**              | 3.1 Policies, procedures and controls \| 3.2 Model data \| 3.3 Model development \| 3.4 Independent review \| 3.5 Deployment \| 3.6 Monitoring and decommissioning |

# **2. Is a Copilot Studio agent a model?**

E-23 describes a model as having three parts: a data input component, a processing component, and a result component. It also notes that an AI system can be built on one model or several. A Copilot Studio agent maps onto that structure closely:

| **E-23 component** | **In a Copilot Studio agent**                                                                                                                   |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| **Data input**     | The user’s message, conversation history, knowledge sources (SharePoint, files, websites, Dataverse), and data returned by tools and connectors |
| **Processing**     | The orchestration (classic topics or generative orchestration), the underlying large language model(s), prompts and instructions                |
| **Result**         | The answer shown to the user, and any action the agent takes (sending, creating, updating records, triggering flows)                            |

So the practical question is rarely "is this a model?" but "is its inherent risk negligible?" E-23 allows institutions to create a negligible-risk category that is exempt from full lifecycle governance, as long as there is a robust process to approve and track what goes into it. That is the decision most agents will turn on.

## **Suggested triage questions**

An agent is a candidate for the negligible category only if every answer below is "no". Any "yes" means it should be inventoried and rated. Agree the final criteria with your MRM function.

1.  Does the agent, or the person relying on it, make or influence a decision about a customer, a transaction, credit, pricing, capital, or a regulatory obligation?

2.  Can the agent write, send, create, update or delete anything in another system?

3.  Does it act on a trigger or schedule without a person starting the conversation?

4.  Is it available to customers, partners or anyone outside the institution?

5.  Does it use Confidential or Restricted data, or personal information?

6.  Would a wrong answer reasonably cause financial loss, operational disruption, a customer harm or a reputational event?

*Even negligible-category agents should still appear in an inventory: E-23 expects minimum details (ID, name, rating, owner, developer, origin) for every identified model.*

# **3. Principle-by-principle map**

Coverage shows how much of the expectation existing Microsoft tools meet on their own. "Partial" and "Gap" rows are where your institution has to add process, data or tooling.

| **Principle**                         | **What E-23 expects (paraphrased)**                                                                                       | **Copilot Studio and Power Platform**                                                               | **Copilot Agent Kit**                                                                       | **Toolkit template**                                                      | **What you still have to add**                                                                   | **Coverage** |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|--------------|
| 1.1 Organizational enablement         | Clear MRM roles and accountability, staff with the right skills (including for AI), reporting to the board                | Not a product feature                                                                               | Compliance admin group set as an environment variable                                       | Register defines owner, reviewer and approver roles                       | Name an accountable MRM role for agents; add agent risk to board and senior management reporting | Gap          |
| 1.2 MRM framework                     | Framework aligned to risk appetite, covering identification, inventory, rating, lifecycle and third-party models and data | Managed Environments, environment groups and data policies (DLP) express parts of the risk appetite | Compliance Hub thresholds and action policies encode which agent attributes are acceptable  | Tiering rules; fact sheet records vendor model origin                     | Write agents into the MRM policy explicitly; treat foundation models as third-party models       | Partial      |
| 1.3 Use of models                     | Use models only where they add value and work as intended; modify, replace or retire them when they no longer do          | Analytics show usage and outcomes                                                                   | Agent Inventory shows published state and last change                                       | Fact sheet purpose and expected benefit; periodic "still needed?" review  | Decommissioning criteria and an owner who acts on them                                           | Partial      |
| 2.1 Model identification              | Find and track every model in use, including vendor models; triage; provisional rating for new models                     | Admin agent inventory in the Power Platform admin center                                            | Agent Inventory scans environments daily and records 44 attributes per agent                | Register extension adds triage result and provisional rating              | Triage step; coverage of agents built outside Copilot Studio                                     | Partial      |
| 2.2 Model risk rating                 | Rate inherent risk with clear quantitative and qualitative criteria; revisit after trigger events                         | None                                                                                                | Compliance Hub risk levels describe rule violations, not the agent’s inherent risk          | Illustrative rating matrix (Section 5)                                    | Institution-approved rating criteria and a rating on every agent                                 | Gap          |
| 2.3 Risk management intensity         | Scope and intensity of oversight match the risk rating                                                                    | None                                                                                                | Action policies vary SLAs and enforcement by risk level                                     | Test counts, release gates and review intervals vary by tier              | Tie approval authority and documentation depth to the rating                                     | Partial      |
| 3.1 Policies, procedures and controls | Consistent controls, clear accountability, early stakeholder involvement, independence, coverage of autonomous AI         | Environment strategy, solutions, role-based access                                                  | Admin review of cases with audit notes                                                      | Maker cannot approve own agent; tiered approvers                          | An agent development and review standard                                                         | Partial      |
| 3.2 Model data                        | Data is accurate, relevant, lawful, traceable and timely; quality checks; bias considered                                 | Knowledge source configuration; data policies                                                       | Agent Inventory lists knowledge sources; Compliance Hub intake captures data classification | Fact sheet knowledge source table: classification, owner, refresh         | Content ownership and quality checks for knowledge sources; lineage                              | Partial      |
| 3.3 Model development                 | Repeatable development standards: documentation, testing, explainability, performance criteria                            | Development environments and solutions                                                              | Test sets with six test types                                                               | Evaluation pack; fact sheet configuration summary                         | Written performance criteria per agent before build                                              | Partial      |
| 3.4 Independent review                | Conceptual soundness and performance reviewed by someone independent of development                                       | Agent evaluation with built-in and custom graders                                                   | Test runs, AI-judge rubrics, human-vs-AI grade alignment                                    | Evaluation pack requires a reviewer who is not the maker for Tier 2 and 3 | Named independent reviewers; evidence that AI graders themselves were checked                    | Partial      |
| 3.5 Deployment                        | Quality and change controls, production testing, documented approval hierarchy                                            | Pipelines, managed solutions, separate environments                                                 | None specific                                                                               | Register approval as a pre-deployment gate                                | A pipeline check that blocks unapproved agents                                                   | Partial      |
| 3.6 Monitoring and decommissioning    | Thresholds, drift, usage and dependency tracking, contingency plans, AI-specific risks, formal retirement                 | Analytics and transcripts (where enabled)                                                           | Daily compliance scan; quarantine or delete when SLAs are missed; repeatable test runs      | Regression log; review reminders; retirement status                       | Contingency plan if an agent fails; re-test when the underlying model changes                    | Partial      |

# **4. Inventory crosswalk**

E-23 lists minimum fields for every identified model, and more fields for models with non-negligible risk. The table compares them with the columns the Copilot Agent Kit’s Agent Inventory collects automatically. The automatic inventory is strong on technical facts (IDs, dependencies, data sources) and weak on everything else: ownership, judgement and review history, which no scan can infer. That is exactly what the Agent Fact Sheet and register extension are for.

| **E-23 inventory field**                       | **Required for** | **Agent Inventory column(s)**                                                           | **Coverage** | **Where to capture the rest**                            |
|------------------------------------------------|------------------|-----------------------------------------------------------------------------------------|--------------|----------------------------------------------------------|
| Model ID                                       | All models       | Agent ID (cat_agentid)                                                                  | Covered      | —                                                        |
| Name and description of key features and use   | All models       | Name, Description, Instructions                                                         | Partial      | Fact sheet: purpose, intended users, what it does not do |
| Model risk rating                              | All models       | None (Compliance Hub risk level is a rule violation, not a rating)                      | Gap          | Register extension                                       |
| Model owner                                    | All models       | None (Created By is not the accountable owner)                                          | Gap          | Register extension and fact sheet                        |
| Model developer                                | All models       | Agent Created By, Agent Modified By                                                     | Partial      | Fact sheet technical owner                               |
| Model origin                                   | All models       | Type; Uses Deep Reasoning Models                                                        | Partial      | Fact sheet: platform and foundation model provider       |
| Model version                                  | Inventory        | Agent Modified Date, Published Date, Managed State                                      | Partial      | Fact sheet version and change log                        |
| Date deployed to production                    | Inventory        | Published Date (latest, not first production release)                                   | Partial      | Register extension                                       |
| Model reviewer                                 | Inventory        | None                                                                                    | Gap          | Register extension; evaluation pack                      |
| Model approver                                 | Inventory        | Compliance Hub case approver, only when a case was raised                               | Partial      | Register extension                                       |
| Model dependencies                             | Inventory        | Connections, Knowledge Sources, Uses MCP, HTTP Request Actions, Prompts, Agent Triggers | Covered      | Fact sheet actions table adds read/write and run-as      |
| Data sources and description                   | Inventory        | Knowledge Sources, Classic Data Sources                                                 | Partial      | Fact sheet: classification, content owner, refresh       |
| Approved uses                                  | Inventory        | None                                                                                    | Gap          | Fact sheet                                               |
| Limitations, exceptions and extra requirements | Inventory        | None                                                                                    | Gap          | Fact sheet                                               |
| Date of most recent review                     | Inventory        | None                                                                                    | Gap          | Register extension                                       |
| Monitoring status, with exceptions             | Inventory        | Compliance case status only                                                             | Partial      | Register extension; regression log                       |
| Next review date                               | Inventory        | None                                                                                    | Gap          | Register extension                                       |

*Column names are from Microsoft’s Agent Inventory data source documentation. Check the columns in your installed version; the Kit changes often.*

# **5. Rating an agent’s inherent risk**

E-23 expects ratings to rest on clear, measurable criteria that combine quantitative factors (size, financial and operational impact) with qualitative ones (business use, complexity and autonomy, input data reliability, customer impact, regulatory risk). The matrix below translates those factors into agent attributes, most of which the Kit already collects. It is an illustrative starting point for your MRM function, not a standard.

| **Dimension**               | **Low (1)**                                  | **Medium (2)**                                | **High (3)**                                                            | **Evidence**                                                                |
|-----------------------------|----------------------------------------------|-----------------------------------------------|-------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| **Business use**            | General information or productivity          | Supports an internal business process         | Supports decisions on customers, credit, pricing, capital or compliance | Fact sheet purpose; intake business justification                           |
| **Customer impact**         | No customer contact, no customer data        | Staff use outputs in customer interactions    | Customers or partners use the agent directly                            | Intake audience; channels                                                   |
| **Complexity and autonomy** | Answers only; user starts every conversation | Generative orchestration with read-only tools | Autonomous triggers, or write actions without user confirmation         | Autonomous Agent, Agent Triggers, Orchestration Type, Uses Tools            |
| **Input data**              | Public or Internal; curated sources          | Confidential; or broad, uncurated sources     | Restricted or personal information; external HTTP or MCP sources        | Intake data classification; Knowledge Sources; Uses HTTP Requests; Uses MCP |
| **Regulatory exposure**     | None identified                              | Touches a regulated process indirectly        | Output is part of a regulated obligation or disclosure                  | Compliance review                                                           |
| **Scale and impact**        | Small team; error is easy to spot and fix    | Department-wide; moderate effort to correct   | Enterprise-wide or high volume; errors costly or hard to reverse        | Intake expected users; analytics                                            |

**Illustrative scoring:** add the six scores. 6–8 = Tier 1 Low, 9–13 = Tier 2 Medium, 14–18 = Tier 3 High. A score of 3 on Customer impact or on Complexity and autonomy sets a floor of Tier 2. Re-rate after any trigger event in Section 6.

# **6. Review triggers for agents**

E-23 expects a review when a model is new, modified, breaching performance thresholds, facing significant data changes, or due for its scheduled review. For agents, those triggers look like this:

| **E-23 trigger**                   | **Agent equivalent**                                                                                 | **How you would detect it**                                                  |
|------------------------------------|------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| **New model**                      | New agent, or an existing agent published to a new audience or channel                               | Agent Inventory; register intake                                             |
| **Modification**                   | Changed instructions, orchestration type, tools, connectors, MCP servers, prompts, or selected model | Agent Modified Date; dependency columns compared with last approved snapshot |
| **Change in the underlying model** | The foundation model behind the agent changes, including when the platform updates a default model   | Platform release notes; model setting on the agent; scheduled re-test        |
| **Performance breach**             | Evaluation pass rate drops, escalations or negative feedback rise, or a compliance case opens        | Regression runs; analytics; Compliance Hub cases                             |
| **Significant data change**        | A knowledge source is added, removed, or materially rewritten                                        | Knowledge Sources column; content owner notification                         |
| **Scheduled review**               | Periodic re-attestation by tier                                                                      | Register next review date                                                    |

|                                                                                                                                                                                                                                                                                                                                           |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **The trigger most teams miss:** an agent can change behaviour without anyone in your institution editing it, because the large language model underneath it can change. Treat a change in the underlying model as a modification that requires re-testing, and keep the last approved evaluation run as the baseline to compare against. |

# **7. Third-party models**

The large language models behind Copilot Studio are third-party models from the institution’s point of view. E-23 expects external models to be inside the MRM framework, recorded in the inventory with their origin, rated on a standalone basis, and covered by reviews, consistent with OSFI’s third-party risk guideline (B-10). In practice:

- Record origin as both the platform (Copilot Studio) and the foundation model provider and model, where known.

- Rely on Microsoft’s published documentation (such as transparency and application cards) as vendor evidence, but test the agent as configured; vendor documentation describes the platform, not your agent.

- Decide in advance what you will do if a model you depend on is retired or replaced.

# **8. Lifecycle walk-through**

| **Lifecycle stage**    | **What to produce for each agent**                                                  | **Where it lives**                             |
|------------------------|-------------------------------------------------------------------------------------|------------------------------------------------|
| **Rationale**          | Purpose, scope, intended users, business case, out-of-scope uses                    | Agent Fact Sheet, sections 1–3                 |
| **Data**               | Knowledge sources with classification, owner and refresh cycle                      | Agent Fact Sheet, section 4                    |
| **Development**        | Configuration summary, test plan, performance criteria agreed before build          | Fact sheet section 6; Evaluation Pack          |
| **Independent review** | Test results scored by someone other than the maker; rating confirmed or challenged | Evaluation Pack; Kit or native evaluation runs |
| **Approval**           | Approval of use and of the risk rating, by the authority the tier requires          | Register extension; Compliance Hub case        |
| **Deployment**         | Promotion through a pipeline that checks approval status                            | Power Platform pipelines                       |
| **Monitoring**         | Scheduled regression runs, analytics review, compliance scan results                | Regression log; Compliance Hub                 |
| **Decommissioning**    | Owner decision, user notice, agent switched off, documentation retained             | Register status Retired; fact sheet archived   |

# **9. Questions to settle with your MRM function**

1.  Do all Copilot Studio agents fall under E-23, or only those above an agreed triage threshold?

2.  What exactly qualifies an agent for the negligible-risk category, and who approves that classification?

3.  Who counts as an independent reviewer for agents, and is a platform team independent enough?

4.  Can AI-graded evaluations count as review evidence, and what proof is needed that the graders themselves are reliable?

5.  How will changes to the underlying model be detected, and do they trigger a full or partial review?

6.  Do agents built in other Microsoft tools (for example Microsoft 365 Copilot agent builder) follow the same process?

# **Sources**

- [<u>OSFI – Guideline E-23: Model Risk Management (2027)</u>](https://www.osfi-bsif.gc.ca/en/guidance/guidance-library/guideline-e-23-model-risk-management-2027)

- [<u>Microsoft Learn – Copilot Agent Kit: Agent Inventory data source</u>](https://learn.microsoft.com/microsoft-copilot-studio/guidance/kit-agent-inventory-data-source)

- [<u>Microsoft Learn – Copilot Agent Kit: Compliance Hub</u>](https://learn.microsoft.com/en-au/microsoft-copilot-studio/guidance/kit-configure-compliance-hub)

- [<u>Microsoft Learn – Copilot Agent Kit: Configure tests</u>](https://learn.microsoft.com/en-au/microsoft-copilot-studio/guidance/kit-configure-tests)

- [<u>Microsoft Learn – Copilot Agent Kit: Rubrics</u>](https://learn.microsoft.com/en-gb/microsoft-Copilot-studio/guidance/kit-rubrics-reference)

- [<u>Microsoft – Custom graders in Copilot Studio</u>](https://www.microsoft.com/en-us/microsoft-copilot/blog/?p=7370)

- [<u>Microsoft Learn – Application Card: Microsoft Copilot Studio</u>](https://learn.microsoft.com/en-za/microsoft-Copilot-studio/system-service-card-copilot-studio)

- [<u>FSI-AgentGov (US-focused agent governance framework, for comparison)</u>](https://judeper.github.io/FSI-AgentGov/controls/pillar-2-management/2.6-model-risk-management-alignment-with-occ-2011-12-sr-11-7/)
