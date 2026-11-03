**RESPONSIBLE AGENT TOOLKIT**

**Agent Fact Sheet**

The human half of your agent inventory: what an agent is for, what it must not do, and who answers for it

|                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Why this exists:** Tools like the Copilot Agent Kit’s Agent Inventory can discover every agent and record its technical facts automatically. No scan can tell you who is accountable for an agent, what it is approved to do, what its limits are, or when it was last reviewed. Model risk guidelines such as OSFI E-23 require exactly those details. This fact sheet captures them, one page per agent. |

## **How to use it**

- Fields marked Auto in the Source column can be copied from Agent Inventory (column names shown). Fill the Manual fields yourself.

- The business owner completes the sheet before the agent is submitted for approval. The reviewer checks it against the agent itself.

- Store it with the agent’s register record and update it whenever the agent’s purpose, data, tools, model or owners change.

- Replace every grey placeholder. Keep answers short and plain.

# **1. Identity**

| **Field**                       | **Entry**                                                      | **Source**             |
|---------------------------------|----------------------------------------------------------------|------------------------|
| **Agent name**                  | *\[Name as shown in Copilot Studio\]*                          | Auto: Name             |
| **Agent ID**                    | *\[Agent ID\]*                                                 | Auto: Agent ID         |
| **Environment**                 | *\[Production environment name\]*                              | Auto: Environment Name |
| **Channels**                    | *\[Teams / Microsoft 365 Copilot / Website / Other\]*          | Manual                 |
| **Version and last published**  | *\[Your version label\] / \[date\]*                            | Auto: Published Date   |
| **Business owner**              | *\[Name, role\] – accountable for outcomes and re-attestation* | Manual                 |
| **Technical owner (developer)** | *\[Name, role\] – builds and maintains the agent*              | Manual                 |
| **Status**                      | *\[Draft / Approved / Live / Retired\]*                        | Manual                 |

# **2. Purpose and approved uses**

| **Field**            | **Entry**                                                                                  | **Source** |
|----------------------|--------------------------------------------------------------------------------------------|------------|
| **What it does**     | *\[One or two sentences: the problem it solves and for whom\]*                             | Manual     |
| **Approved uses**    | *\[The specific uses that were approved, e.g. answer staff questions about leave policy\]* | Manual     |
| **Intended users**   | *\[Who may use it and how they get access\]*                                               | Manual     |
| **Expected benefit** | *\[Time saved, calls deflected, faster answers – with a measure\]*                         | Manual     |

# **3. What it does not do**

*List the boundaries explicitly. Reviewers and users rely on this section as much as on the purpose.*

| **Field**                      | **Entry**                                                                   | **Source** |
|--------------------------------|-----------------------------------------------------------------------------|------------|
| **Out of scope**               | *\[Topics or requests it must decline\]*                                    | Manual     |
| **Decisions it does not make** | *\[e.g. does not approve, deny or advise on individual customer cases\]*    | Manual     |
| **Data it must never return**  | *\[e.g. other people’s personal data, credentials, internal-only content\]* | Manual     |

# **4. Risk classification**

| **Field**                  | **Entry**                                                                        | **Source**           |
|----------------------------|----------------------------------------------------------------------------------|----------------------|
| **Triage result**          | *\[Negligible risk / In inventory\] – see triage questions in the OSFI E-23 map* | Manual               |
| **Inherent risk rating**   | *\[Tier 1 Low / Tier 2 Medium / Tier 3 High\]*                                   | Manual               |
| **Rating rationale**       | *\[Scores by dimension, or a short explanation\]*                                | Manual               |
| **Date rated and by whom** | *\[Date, name\]*                                                                 | Manual               |
| **Open compliance cases**  | *\[None / case reference\]*                                                      | Auto: Compliance Hub |

# **5. Model origin and configuration**

| **Field**                   | **Entry**                                                              | **Source**                             |
|-----------------------------|------------------------------------------------------------------------|----------------------------------------|
| **Platform**                | *Microsoft Copilot Studio*                                             | Manual                                 |
| **Foundation model(s)**     | *\[Model and provider selected for the agent, or "platform default"\]* | Manual                                 |
| **Orchestration**           | *\[Classic / Generative\]*                                             | Auto: Orchestration Type               |
| **Autonomous triggers**     | *\[None, or what starts the agent without a user\]*                    | Auto: Autonomous Agent, Agent Triggers |
| **End-user authentication** | *\[Microsoft Entra ID / None / Other\]*                                | Auto: End-User Authentication Type     |
| **Instructions summary**    | *\[Two or three lines summarizing the agent’s instructions\]*          | Auto: Instructions (summarize)         |
| **Content safety settings** | *\[Moderation level and any custom settings\]*                         | Manual                                 |

# **6. Knowledge sources**

| **Source**                | **Type**                                      | **Classification** | **Content owner** | **Refresh**         |
|---------------------------|-----------------------------------------------|--------------------|-------------------|---------------------|
| *\[e.g. HR policy site\]* | *\[SharePoint / file / website / Dataverse\]* | *\[Internal\]*     | *\[Name\]*        | *\[Live / weekly\]* |
|                           |                                               |                    |                   |                     |
|                           |                                               |                    |                   |                     |

*Source names are Auto (Knowledge Sources column). Classification, owner and refresh are Manual.*

# **7. Tools, actions and connectors**

| **Action**                      | **Target system** | **Read / Write** | **Runs as**                          | **User confirms first?** |
|---------------------------------|-------------------|------------------|--------------------------------------|--------------------------|
| *\[e.g. Submit leave request\]* | *\[System\]*      | *\[Write\]*      | *\[User / maker / service account\]* | *\[Yes / No\]*           |
|                                 |                   |                  |                                      |                          |
|                                 |                   |                  |                                      |                          |

*Connections, HTTP requests and MCP use are Auto. Read or write, run-as identity and confirmation are Manual.*

# **8. Known limitations**

*Known limits written down are a control. Known limits left unwritten are a risk.*

- *\[e.g. Answers only from policies published after a given date\]*

- *\[e.g. Struggles with questions that span several policies\]*

# **9. Review, approval and evaluation**

| **Field**                             | **Entry**                                                 | **Source** |
|---------------------------------------|-----------------------------------------------------------|------------|
| **Independent reviewer**              | *\[Name, role – not the developer\]*                      | Manual     |
| **Approver(s)**                       | *\[Names or committee, as the tier requires\]*            | Manual     |
| **Date first deployed to production** | *\[Date\]*                                                | Manual     |
| **Last evaluation**                   | *\[Date\] – \[pass rate\] – \[critical failures\]*        | Manual     |
| **Evaluation record**                 | *\[Link to the evaluation run or Agent Evaluation Pack\]* | Manual     |
| **Most recent review**                | *\[Date\]*                                                | Manual     |
| **Next review due**                   | *\[Date\]*                                                | Manual     |

# **10. Monitoring and support**

| **Field**                     | **Entry**                                                                 | **Source** |
|-------------------------------|---------------------------------------------------------------------------|------------|
| **Human escalation path**     | *\[When and how users are handed to a person or queue\]*                  | Manual     |
| **How users report problems** | *\[Feedback option, support channel, ticket category\]*                   | Manual     |
| **What is monitored**         | *\[Usage, satisfaction, escalations, errors, cost – and who reviews it\]* | Manual     |
| **Monitoring status**         | *\[Normal / Exceptions: describe\]*                                       | Manual     |
| **If the agent fails**        | *\[Fallback for users if the agent is unavailable or switched off\]*      | Manual     |

# **11. Change log**

| **Date** | **Version** | **Change** | **Re-evaluated?** | **By** |
|----------|-------------|------------|-------------------|--------|
|          |             |            |                   |        |
|          |             |            |                   |        |
|          |             |            |                   |        |
|          |             |            |                   |        |

*Log changes to instructions, knowledge, tools, model, audience and owners. A change of foundation model counts, even if nobody edited the agent.*

# **12. Sign-off**

| **Role**                 | **Name** | **Date** |
|--------------------------|----------|----------|
| **Business owner**       |          |          |
| **Technical owner**      |          |          |
| **Independent reviewer** |          |          |
| **Approver**             |          |          |
