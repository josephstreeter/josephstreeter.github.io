# Azure DevOps Team Guide for Work Management

## Table of Contents

1. [Overview](#overview)
2. [Team Structure & Roles](#team-structure--roles)
3. [Work Item Structure](#work-item-structure)
4. [Sprint Management](#sprint-management)
5. [Processes & Workflows](#processes--workflows)
6. [Meetings & Schedule](#-meetings--schedule)
7. [Tools & Reporting](#-tools--reporting)
8. [Onboarding Checklist](#onboarding-checklist)
9. [FAQ](#faq)

## Overview

This guide outlines how a team can use Azure DevOps to manage work across key operational areas. It defines team roles, work item structures, processes, and best practices to ensure efficient and effective work management.

### Team Mission

We manage critical identity services including Active Directory, Certificate Management, Exchange, Identity Management, operational work, and request management through an agile methodology using Azure DevOps.

### Goals

- Improve visibility into work progress across all IAM domains
- Track bugs and issues more effectively in our scripts and tools
- Structure sprint planning and retrospectives for better team coordination
- Clarify ownership and accountability for different work areas
- Provide consistent methodology for new team members and other teams

## Team Structure & Roles

### Core Roles

- **Manager** (La Grew)
  - Sets high-level direction and strategy for the team
  - Represents team in management meetings
  - Ensures alignment with organizational goals
  - Oversees resource allocation and budget
  - Coordinates with other teams and departments to remove blockers

- **Project Manager** (Memeh)
  - Facilitates all team meetings and ceremonies
  - Manages timelines and coordinates with external dependencies
  - Updates MS Project Online with progress
  - Ensures team follows processes and identifies blockers

- **Product Owner** (Streeter)
  - Oversees team operations and strategy
  - Ensures alignment with department goals
  - Prioritizes backlog and defines sprint goals
  - Accepts completed work and provides feedback
  - Makes decisions on feature scope and priorities
  - Interface with stakeholders and management

- **Process Champion** (Camp)
  - Maintains work item hygiene
  - Helps ensure tickets are complete, traceable, and standardized
  - Ensures adherence to Azure DevOps best practices

- **Team Members**
  - All team members can work on any area but have specific expertise
  - Each member has primary responsibility for one or more domains. All other members assist as needed:
    - **Active Directory**: Primary contact for AD-related work
    - **Certificate Management**: PKI and certificate lifecycle management
    - **Exchange**: Email and Exchange server administration
    - **Identity Management**: User lifecycle and access management
    - **Operational Work**: Day-to-day operations and maintenance
    - **Request Management**: ServiceNow and user request processing

### Responsibilities Matrix

| Role | Sprint Planning | Daily Work | Sprint Review | Retrospective | Backlog Management |
|------|----------------|------------|---------------|---------------|-------------------|
| Product Owner | Defines priorities | Accepts work | Demos results | Provides feedback | Owns backlog |
| Project Manager | Facilitates | Tracks progress | Facilitates | Facilitates | Updates timeline |
| Team Members | Estimates work | Executes tasks | Presents work | Shares insights | Provides input |

## Work Item Structure

Our team uses a hierarchical structure to organize work from high-level initiatives down to specific tasks.

### Work Item Types & Usage

#### Epics (Strategic Level)

High-level categories representing our core operational domains:

- **Active Directory**: All AD-related infrastructure, maintenance, and improvements
- **Certificate Management**: PKI operations, certificate lifecycle, and renewals
- **Exchange**: Email system administration and improvements
- **Identity Management**: User lifecycle, access management, and provisioning
- **Operational Work**: Day-to-day operations, monitoring, and maintenance
- **Request Management**: ServiceNow integration and user request processing

#### Features (Initiative Level)

Features represent major initiatives or deliverables within an Epic that typically span multiple sprints and deliver significant business value. They serve as the bridge between high-level strategic Epics and specific User Stories.

**When to Create a Feature:**

- Initiative will take more than one sprint to complete
- Multiple User Stories are needed to deliver the complete capability
- Cross-functional coordination is required
- Significant business value or impact is expected
- Project requires milestone tracking and reporting

> [!NOTE]
> **Feature Size Guideline**: A Feature should typically contain 3-8 User Stories and span 2-6 sprints for optimal management.

**Feature Creation Process:**

1. **Identify the Need**
   - Strategic initiative from management
   - Large improvement identified during retrospectives
   - Complex request from ServiceNow that requires multiple deliverables
   - Technical debt that affects multiple areas

2. **Define the Feature**
   - **Title**: Clear, concise description of the initiative
   - **Description**: Detailed explanation including business context
   - **Acceptance Criteria**: High-level success criteria for the entire Feature
   - **Business Value**: Expected benefits and impact
   - **Dependencies**: External systems, teams, or resources required

3. **Link to Epic**
   - Assign to appropriate Epic (AD, Exchange, Certificate Management, etc.)
   - Document relationship to overall strategic goals

4. **Break Down into User Stories**
   - Identify discrete deliverables that provide user value
   - Ensure each User Story can be completed within a sprint
   - Maintain logical sequence and dependencies

**Feature Examples with Breakdown:**

##### Example 1: "Implement automated certificate renewal process"

- Epic: Certificate Management
- User Stories:
  - "As an admin, I want to receive alerts 30 days before cert expiration"
  - "As a system, I want to automatically renew non-critical certificates"
  - "As an admin, I want a dashboard showing renewal status and history"
  - "As a system, I want to log all renewal activities for audit purposes"

##### Example 2: "Upgrade domain controllers to Windows Server 2022"

- Epic: Active Directory
- User Stories:
  - "As an admin, I want a pre-upgrade assessment of current environment"
  - "As a system, I want staged upgrade of secondary DCs first"
  - "As an admin, I want rollback procedures documented and tested"
  - "As a system, I want post-upgrade validation and performance monitoring"

**Feature Planning Considerations:**

- **Timeline**: Realistic estimate considering team capacity and dependencies
- **Risk Assessment**: Technical, business, and operational risks
- **Resource Requirements**: Special skills, tools, or external resources needed
- **Success Metrics**: Measurable outcomes to determine completion
- **Communication Plan**: Stakeholder updates and milestone reporting

> [!TIP]
> Use Features to communicate progress to management and stakeholders. They provide the right level of detail for executive reporting without getting into technical task specifics.

**Feature Management Best Practices:**

- **Regular Review**: Assess progress during sprint planning and retrospectives
- **Scope Management**: Be prepared to adjust User Story scope while maintaining Feature goals
- **Dependency Tracking**: Monitor external dependencies that could impact timeline
- **Stakeholder Communication**: Provide regular updates on Feature progress
- **Documentation**: Maintain decision logs and architectural notes at Feature level

> [!IMPORTANT]
> Features should always deliver complete business value. Avoid creating Features that leave the system in a partially implemented state.

#### User Stories (Work Unit Level)

User Stories represent the smallest units of work that deliver value to end users. They serve as the primary work items for sprint planning and execution, bridging the gap between high-level Features and detailed technical Tasks.

**User Story Format**:

Standard format: "As a [user type], I want [capability] so that [benefit/outcome]"

**Components of a Well-Written User Story**:

1. **User Type**: Who will benefit from this work
   - Administrator/Admin
   - End User
   - System
   - Auditor
   - Manager
   - Helpdesk

2. **Capability**: What functionality or improvement is needed
3. **Benefit**: Why this work provides value

**User Story Creation Process**:

1. **Identify the Need**
   - ServiceNow requests requiring technical implementation
   - Operational improvements identified by team
   - Compliance or security requirements
   - Automation opportunities
   - Bug fixes that deliver user value

2. **Define the User Story**
   - **Title**: Concise description of the capability
   - **Description**: Detailed explanation using the standard format
   - **Acceptance Criteria**: Specific, testable conditions for completion
   - **Priority**: Business value and urgency assessment
   - **Effort Estimate**: Story points or hours required

3. **Add Context**
   - **Tags**: Area (AD, Exchange, etc.), type, priority
   - **Attachments**: Requirements documents, screenshots, logs
   - **Links**: Related User Stories, parent Feature, ServiceNow tickets

**IAM Team User Story Examples**:

##### Certificate Management Examples

**User Story**: "As an administrator, I want automated alerts for expiring certificates so that I can renew them proactively"

**Acceptance Criteria**:

- Alert sent 30 days before certificate expiration
- Alert includes certificate details (name, location, expiration date)
- Alert sent to appropriate team member based on certificate type
- Alert includes renewal instructions or links
- System logs all alert activities

**User Story**: "As a system, I want to automatically renew non-critical certificates so that services remain operational without manual intervention"

**Acceptance Criteria**:

- System identifies non-critical certificates eligible for auto-renewal
- Renewal process validates new certificate before deployment
- Original certificate backed up before replacement
- All renewal activities logged for audit
- Notification sent upon successful renewal

##### Active Directory Examples

**User Story**: "As a manager, I want to receive monthly reports of user access changes so that I can verify appropriate permissions"

**Acceptance Criteria**:

- Report includes all users in manager's department
- Shows added, removed, and modified permissions
- Includes timestamps and who made changes
- Report delivered via email in readable format
- Option to request detailed investigation of specific changes

**User Story**: "As an administrator, I want automated detection of inactive user accounts so that I can maintain security compliance"

**Acceptance Criteria**:

- System scans for accounts inactive for 90+ days
- Report excludes service accounts and approved exceptions
- Report includes last login date and account details
- Recommendations provided for each account (disable, delete, investigate)
- Process integrates with HR system for employment status

##### Exchange Examples

**User Story**: "As a user, I want self-service password reset so that I don't need to contact helpdesk"

**Acceptance Criteria**:

- User can initiate reset from login screen
- Multi-factor authentication required for verification
- New password meets complexity requirements
- User receives confirmation of successful reset
- All reset attempts logged for security monitoring

**User Story**: "As an administrator, I want automated mailbox quota monitoring so that I can prevent service disruptions"

**Acceptance Criteria**:

- System monitors all mailboxes hourly
- Alerts sent when mailbox reaches 80% capacity
- Escalation alerts at 90% and 95%
- Dashboard shows quota status across all mailboxes
- Historical trending data available for capacity planning

##### Identity Management Examples

**User Story**: "As an HR representative, I want automated user provisioning for new employees so that they have access on their start date"

**Acceptance Criteria**:

- Integration with HR system for new employee data
- Automatic account creation based on role/department
- Standard group memberships assigned automatically
- Manager approval required for elevated permissions
- Welcome email sent with login instructions

##### Request Management Examples

**User Story**: "As a helpdesk agent, I want to track ServiceNow ticket resolution in Azure DevOps so that I can provide accurate status updates"

**Acceptance Criteria**:

- Manual linking process documented and followed
- Status updates synchronized between systems
- Resolution details captured in both systems
- Escalation path defined for complex requests
- Reporting available on ticket resolution times

**User Story Sizing Guidelines**:

> [!TIP]
> **Ideal User Story Size**: Should be completable within one sprint (1-2 weeks) by a single team member or pair.

#### Story Points Methodology for IAM Teams

Story points are a relative estimation technique that helps teams understand the complexity, effort, and risk involved in completing User Stories. For our IAM team, we use a modified Fibonacci sequence (1, 2, 3, 5, 8, 13, 21) to estimate work complexity rather than time.

**Why Story Points Over Hours:**

- **Account for Uncertainty**: Story points handle unknown complexity better than time estimates
- **Team Consistency**: Relative sizing reduces individual estimation bias
- **Velocity Tracking**: Enables better sprint planning and capacity management
- **Focus on Value**: Emphasizes problem complexity over implementation time
- **Learning Adaptation**: Estimation accuracy improves over time with team experience

**IAM Team Story Point Scale:**

##### 1 Point - Trivial

**Characteristics**:

- Very simple, well-understood work
- Minimal or no research required
- Low technical risk
- Clear implementation path
- Can be completed in 2-4 hours

**IAM Examples**:

- Update existing PowerShell script parameters
- Simple configuration changes in existing tools
- Documentation updates for known procedures
- Basic email template modifications
- Adding new users to existing AD groups

**Sample User Story**: "As an administrator, I want to add new team members to the Certificate Management AD group so they can access certificate tools"

##### 2 Points - Simple

**Characteristics**:

- Straightforward work with clear requirements
- Minor research or investigation needed
- Some technical complexity but well-understood
- Implementation approach is obvious
- Can be completed in 4-8 hours

**IAM Examples**:

- Small enhancements to existing scripts
- Simple report generation from existing data sources
- Basic integration with familiar APIs
- Standard troubleshooting and bug fixes
- Minor workflow improvements

**Sample User Story**: "As an administrator, I want enhanced logging in the certificate renewal script so I can troubleshoot failures more effectively"

##### 3 Points - Moderate

**Characteristics**:

- Moderate complexity requiring some analysis
- Some research and investigation required
- Multiple components or systems involved
- Clear but not trivial implementation
- Can be completed in 8-16 hours

**IAM Examples**:

- New PowerShell scripts with moderate complexity
- Integration with new but well-documented APIs
- Moderate database queries and reporting
- Cross-system data synchronization
- Security policy implementation

**Sample User Story**: "As an administrator, I want automated daily reports of certificate expiration status so I can proactively manage renewals"

##### 5 Points - Standard

**Characteristics**:

- Standard complexity for experienced team members
- Requires analysis and design work
- Multiple technical components involved
- Some unknowns but manageable risk
- Typically completed in 16-24 hours

**IAM Examples**:

- Complex PowerShell modules with error handling
- New integrations with external systems
- Advanced reporting with multiple data sources
- Workflow automation with multiple steps
- Security tools with moderate complexity

**Sample User Story**: "As an administrator, I want automated detection and reporting of inactive user accounts so I can maintain security compliance"

##### 8 Points - Complex

**Characteristics**:

- High complexity requiring significant analysis
- Multiple unknowns and research required
- Cross-functional coordination needed
- Higher technical risk
- May require 24-40 hours of work

**IAM Examples**:

- Custom tools with user interfaces
- Complex integrations with multiple systems
- Advanced automation with decision logic
- New monitoring and alerting systems
- Significant architectural changes

**Sample User Story**: "As a manager, I want a dashboard showing real-time status of all IAM systems and processes so I can monitor operational health"

##### 13 Points - Very Complex

**Characteristics**:

- Very high complexity with many unknowns
- Extensive research and prototyping required
- Significant architectural decisions needed
- High technical and business risk
- Often 40+ hours of work

**IAM Examples**:

- Major system integrations
- Complete workflow redesigns
- New technology implementations
- Compliance system overhauls
- Cross-domain security implementations

**Sample User Story**: "As a security officer, I want comprehensive audit logging across all IAM systems so we can meet new compliance requirements"

> [!WARNING]
> **Stories Over 13 Points**: Consider breaking down into smaller User Stories or converting to a Feature with multiple User Stories.

##### 21 Points - Epic Level

**Characteristics**:

- Should be broken down into smaller User Stories
- Too large for a single sprint
- Contains multiple features or capabilities
- High uncertainty and risk

**Action Required**: Break down into multiple 1-8 point User Stories within a Feature.

**Story Point Estimation Process:**

#### Planning Poker for IAM Teams

**Meeting Structure** (30-45 minutes):

1. **Story Presentation** (5 minutes per story)
   - Product Owner reads User Story aloud
   - Clarifies acceptance criteria and business context
   - Team asks questions for understanding

2. **Individual Estimation** (2-3 minutes per story)
   - Each team member privately selects story point value
   - Consider complexity, effort, risk, and unknowns
   - Think about IAM-specific factors (see below)

3. **Reveal and Discuss** (5-10 minutes per story)
   - All team members reveal estimates simultaneously
   - Discuss differences (especially high/low outliers)
   - Clarify assumptions and requirements

4. **Re-estimate if Needed**
   - Second round of estimation after discussion
   - Aim for consensus (not necessarily unanimity)
   - Document any assumptions or dependencies

**IAM-Specific Estimation Factors:**

**Technical Complexity Factors**:

- **PowerShell Scripting**: Simple parameter changes vs. complex logic
- **System Integration**: Single system vs. multiple system coordination
- **Error Handling**: Basic logging vs. comprehensive error management
- **Security Requirements**: Standard permissions vs. complex security models
- **Testing Scope**: Unit testing vs. integration and user acceptance testing

**Domain-Specific Considerations**:

**Active Directory Work**:

- **Low Complexity**: User/group management, basic queries
- **Medium Complexity**: Group Policy changes, schema modifications
- **High Complexity**: Forest/domain changes, replication troubleshooting

**Certificate Management**:

- **Low Complexity**: Standard certificate operations, renewals
- **Medium Complexity**: Custom certificate templates, automation
- **High Complexity**: CA infrastructure changes, complex PKI policies

**Exchange Administration**:

- **Low Complexity**: Mailbox management, basic transport rules
- **Medium Complexity**: Advanced transport rules, compliance features
- **High Complexity**: Architecture changes, hybrid configurations

**Identity Management**:

- **Low Complexity**: Standard user provisioning, basic access reviews
- **Medium Complexity**: Complex provisioning workflows, role-based access
- **High Complexity**: Identity federation, advanced governance systems

**Risk and Uncertainty Factors**:

**Low Risk (1-3 points)**:

- Well-understood requirements
- Familiar technology and tools
- Clear implementation path
- Minimal external dependencies

**Medium Risk (5-8 points)**:

- Some requirement ambiguity
- Moderately familiar technology
- Some external coordination required
- Standard change management needed

**High Risk (13+ points)**:

- Unclear or changing requirements
- New or unfamiliar technology
- Multiple external dependencies
- Complex change management required

**Estimation Guidelines by Work Type:**

**Script Development**:

- **Simple Updates (1-2 points)**: Parameter changes, minor logic updates
- **New Scripts (3-5 points)**: New functionality with standard patterns
- **Complex Scripts (8-13 points)**: Advanced logic, multiple integrations

**System Integration**:

- **Existing APIs (2-3 points)**: Well-documented, familiar systems
- **New APIs (5-8 points)**: Documentation available, some learning required
- **Custom Integration (13+ points)**: Limited documentation, significant research

**Reporting and Monitoring**:

- **Standard Reports (1-3 points)**: Existing queries, known data sources
- **Custom Reports (3-5 points)**: New queries, familiar data sources
- **Dashboard/Analytics (8-13 points)**: Multiple sources, visualization requirements

**Common Estimation Pitfalls to Avoid:**

> [!CAUTION]
> **Estimation Anti-Patterns**:
>
> - **Goldplating**: Adding unnecessary features during estimation
> - **Perfect World Thinking**: Not accounting for interruptions and unknowns
> - **Individual Bias**: One person dominating estimation discussions
> - **Time Anchoring**: Converting hours to points instead of relative sizing

**Velocity Tracking and Improvement:**

**Team Velocity Calculation**:

```text
Sprint Velocity = Total Story Points Completed in Sprint
Team Capacity = Average Velocity over 3-5 Sprints
Sprint Planning = Team Capacity × Sprint Planning Factor (0.8-0.9)
```

**Velocity Improvement Strategies**:

**Initial Sprints (First 3-6 sprints)**:

- Focus on estimation accuracy over velocity
- Track actual vs. estimated effort
- Refine understanding of point values
- Build team estimation consensus

**Mature Process (After 6+ sprints)**:

- Use historical velocity for planning
- Identify and address estimation patterns
- Optimize work breakdown and dependencies
- Focus on value delivery over velocity increase

**Story Point Calibration Examples:**

**Reference Stories for Consistent Estimation:**

**1-Point Reference**: "Update certificate alert email template"

- Simple text changes to existing template
- No logic changes required
- Well-understood, quick implementation

**3-Point Reference**: "Add daily certificate expiration summary email"

- Enhance existing monitoring script
- Add email formatting and scheduling
- Moderate but familiar complexity

**5-Point Reference**: "Create automated user account cleanup reporting"

- New script with AD queries and logic
- Reporting output and error handling
- Standard complexity for team

**8-Point Reference**: "Implement ServiceNow ticket integration"

- API research and implementation
- Error handling and status synchronization
- Higher complexity with external dependencies

**Estimation Meeting Best Practices:**

**Before the Meeting**:

- [ ] Product Owner prepares clear User Story descriptions
- [ ] Acceptance criteria are well-defined
- [ ] Team members review stories in advance
- [ ] Reference stories available for comparison

**During the Meeting**:

- [ ] Time-box discussions (max 10 minutes per story)
- [ ] Focus on relative sizing, not absolute time
- [ ] Document assumptions and dependencies
- [ ] Ensure all team members participate

**After the Meeting**:

- [ ] Update User Stories with final estimates
- [ ] Document any follow-up questions or research needed
- [ ] Plan sprint capacity based on team velocity
- [ ] Track estimation accuracy for improvement

> [!IMPORTANT]
> **Estimation is a Team Activity**: All team members should participate in estimation to leverage diverse perspectives and build shared understanding of work complexity.

**Size Indicators for Quick Reference**:

- **Small (1-3 story points)**: Simple script updates, configuration changes, documentation updates
- **Medium (5-8 story points)**: New automation scripts, moderate integrations, standard reporting
- **Large (13+ story points)**: Complex tools, major process changes, significant integrations (consider breaking down)

**Acceptance Criteria Best Practices**:

> [!IMPORTANT]
> **INVEST Criteria**: User Stories should be Independent, Negotiable, Valuable, Estimable, Small, and Testable.

**Writing Effective Acceptance Criteria**:

1. **Use Given-When-Then Format** (when appropriate):
   - Given: Initial context or state
   - When: Action or event occurs
   - Then: Expected outcome

   Example:
   - Given: A certificate expires in 30 days
   - When: The monitoring system runs its daily check
   - Then: An alert email is sent to the certificate owner

2. **Be Specific and Measurable**:
   - Good: "Alert sent within 24 hours of expiration threshold"
   - Bad: "User gets notified soon"

3. **Include Negative Test Cases**:
   - What happens when expected inputs are missing?
   - How does the system handle errors?
   - What are the security considerations?

4. **Define "Done" Clearly**:
   - Include testing requirements
   - Specify documentation needs
   - Note deployment or configuration steps

**Common User Story Patterns for IAM Teams**:

**Monitoring and Alerting Pattern**:
"As a [role], I want [automated monitoring] so that [I can respond proactively]"

**Self-Service Pattern**:
"As a [end user], I want [self-service capability] so that [I can resolve issues without support]"

**Compliance Pattern**:
"As an [auditor/manager], I want [compliance reporting] so that [I can verify adherence to policies]"

**Automation Pattern**:
"As a [system/administrator], I want [automated process] so that [manual effort is reduced]"

**Integration Pattern**:
"As a [user/system], I want [system integration] so that [data flows seamlessly]"

**User Story Refinement Process**:

1. **Initial Creation**: Basic user story with minimal details
2. **Backlog Grooming**: Add acceptance criteria, estimates, dependencies
3. **Sprint Planning**: Final refinement, task breakdown if needed
4. **Sprint Execution**: Continuous clarification as work progresses

> [!WARNING]
> **Avoid These Common Mistakes**:
>
> - Writing tasks disguised as user stories ("As a developer, I want to update the database schema...")
> - Making stories too large for a single sprint
> - Vague acceptance criteria that can't be tested
> - Missing the "so that" benefit clause

**Dependencies and Relationships**:

- **Dependent User Stories**: Link stories that must be completed in sequence
- **Related User Stories**: Link stories that share common elements
- **Parent Feature**: Always link to the appropriate Feature (if applicable)
- **Epic Assignment**: Ensure proper Epic categorization

**Definition of Ready for User Stories**:

Before a User Story can be included in sprint planning:

- [ ] User story format followed (As a... I want... So that...)
- [ ] Acceptance criteria defined and testable
- [ ] Effort estimated by team
- [ ] Dependencies identified and documented
- [ ] Appropriate Epic and Feature assignments
- [ ] Business value and priority assessed
- [ ] Technical approach discussed (if complex)

> [!NOTE]
> **User Stories vs. Technical Tasks**: User Stories focus on user value and outcomes. If you're describing technical implementation details without user benefit, consider making it a Task under a User Story instead.

#### Tasks (Optional Breakdown)

Tasks represent the detailed technical work needed to complete a User Story. They provide granular tracking of specific activities and help break down complex User Stories into manageable units of work. While not always necessary, Tasks are valuable for complex User Stories that require multiple distinct activities or coordination between team members.

**When to Create Tasks:**

- User Story is complex and needs breakdown for better tracking
- Multiple team members will work on different aspects of the User Story
- Work involves distinct phases (development, testing, documentation, deployment)
- Detailed time tracking is needed for specific activities
- Learning purposes (new team members can see work breakdown)
- Risk management (identify potential blockers early)

> [!NOTE]
> **Task Guidelines**: Tasks should be small enough to complete in 1-2 days and specific enough that progress can be clearly measured.

**Task Creation Process:**

1. **Analyze the User Story**
   - Review acceptance criteria and identify distinct work activities
   - Consider dependencies between different types of work
   - Identify skills or expertise needed for different aspects

2. **Break Down into Logical Units**
   - **Technical Tasks**: Script development, configuration changes, system setup
   - **Testing Tasks**: Unit testing, integration testing, user acceptance testing
   - **Documentation Tasks**: Runbook updates, procedure documentation, knowledge transfer
   - **Deployment Tasks**: Production deployment, configuration rollout, monitoring setup

3. **Define Each Task**
   - **Title**: Clear, action-oriented description
   - **Description**: Detailed explanation of what needs to be done
   - **Acceptance Criteria**: Specific completion criteria for the task
   - **Effort Estimate**: Hours required to complete
   - **Dependencies**: Other tasks that must be completed first

**IAM Team Task Examples:**

##### Certificate Management User Story Breakdown

**User Story**: "As an administrator, I want automated alerts for expiring certificates so that I can renew them proactively"

**Tasks**:

1. **Research Certificate Monitoring Solutions**
   - **Description**: Investigate available tools and methods for certificate monitoring
   - **Acceptance Criteria**:

     - Document 3 potential monitoring solutions
     - Include pros/cons analysis for each
     - Recommend preferred approach with justification

   - **Estimate**: 4 hours

2. **Develop Certificate Scanning Script**
   - **Description**: Create PowerShell script to scan certificate stores and identify expiring certificates
   - **Acceptance Criteria**:
     - Script scans local machine and user certificate stores
     - Identifies certificates expiring within configurable timeframe
     - Outputs certificate details in structured format
     - Includes error handling and logging
   - **Estimate**: 8 hours

3. **Create Alert Notification System**
   - **Description**: Implement email notification system for certificate alerts
   - **Acceptance Criteria**:
     - Email template includes all required certificate details
     - Recipients determined by certificate type/location
     - Configurable alert thresholds (30, 14, 7 days)
     - Supports both individual and summary notifications
   - **Estimate**: 6 hours

4. **Implement Scheduling and Automation**
   - **Description**: Configure scheduled execution of monitoring script
   - **Acceptance Criteria**:
     - Daily automated execution via Task Scheduler
     - Logging of all execution results
     - Error notifications if script fails
     - Configuration file for easy parameter changes
   - **Estimate**: 3 hours

5. **Create Documentation and Runbook**
   - **Description**: Document installation, configuration, and troubleshooting procedures
   - **Acceptance Criteria**:
     - Installation guide with step-by-step instructions
     - Configuration reference documentation
     - Troubleshooting guide for common issues
     - Maintenance procedures and schedule
   - **Estimate**: 4 hours

6. **Conduct Testing and Validation**
   - **Description**: Test complete solution in development environment
   - **Acceptance Criteria**:
     - Test with various certificate types and expiration dates
     - Verify email notifications are sent correctly
     - Validate error handling scenarios
     - Performance testing with large certificate stores
   - **Estimate**: 6 hours

##### Active Directory User Story Breakdown

**User Story**: "As an administrator, I want automated detection of inactive user accounts so that I can maintain security compliance"

**Tasks**:

1. **Define Inactivity Criteria and Business Rules**
   - **Description**: Work with security team to establish inactivity detection rules
   - **Acceptance Criteria**:
     - Document inactivity threshold (e.g., 90 days)
     - Define exceptions (service accounts, executives, etc.)
     - Establish different rules for different account types
     - Get approval from security and compliance teams
   - **Estimate**: 4 hours

2. **Develop Account Activity Query Script**
   - **Description**: Create script to query AD for user account activity
   - **Acceptance Criteria**:
     - Query last logon timestamp across all domain controllers
     - Handle timezone differences and date calculations
     - Filter out service accounts and exceptions
     - Export results to structured format (CSV/JSON)
   - **Estimate**: 8 hours

3. **Integrate with HR System Data**
   - **Description**: Add employment status checking to prevent false positives
   - **Acceptance Criteria**:
     - Query HR system API for employment status
     - Cross-reference AD accounts with HR records
     - Handle discrepancies between systems
     - Log all data reconciliation activities
   - **Estimate**: 10 hours

4. **Create Reporting Dashboard**
   - **Description**: Build dashboard for viewing inactive account reports
   - **Acceptance Criteria**:
     - Web-based interface for report viewing
     - Filtering by department, account type, inactivity period
     - Export capabilities for further analysis
     - Drill-down details for each account
   - **Estimate**: 12 hours

5. **Implement Automated Recommendations**
   - **Description**: Add logic to recommend actions for each inactive account
   - **Acceptance Criteria**:
     - Categorize accounts by risk level
     - Suggest actions (disable, delete, investigate)
     - Include justification for each recommendation
     - Allow override of automatic recommendations
   - **Estimate**: 6 hours

6. **Setup Automated Execution and Alerts**
   - **Description**: Configure weekly automated execution and reporting
   - **Acceptance Criteria**:
     - Weekly execution via scheduled task
     - Automatic email delivery to security team
     - Exception reporting for failed executions
     - Archive historical reports for trend analysis
   - **Estimate**: 4 hours

**Task Management Best Practices:**

**Task Sizing Guidelines**:

- **Micro Tasks (1-2 hours)**: Simple configuration changes, minor script updates
- **Small Tasks (2-6 hours)**: Single script functions, basic testing, documentation updates
- **Medium Tasks (6-12 hours)**: Complex script development, integration work, comprehensive testing
- **Large Tasks (12+ hours)**: Consider breaking down further or converting to separate User Story

> [!TIP]
> **Ideal Task Size**: Most tasks should be completable in 4-8 hours. If a task takes longer than 12 hours, consider breaking it down further.

**Task Dependencies and Sequencing**:

**Sequential Dependencies**:

Tasks that must be completed in order:

1. Research and Design → Development → Testing → Documentation → Deployment

**Parallel Work**:

Tasks that can be done simultaneously:

- Documentation can often be written while development is in progress
- Testing scenarios can be developed while code is being written
- Configuration planning can happen alongside development

**Critical Path Planning**:

- Identify tasks that block other work
- Prioritize tasks that enable parallel work streams
- Plan for team member availability and expertise

**Task Status Tracking**:

**Status Definitions**:

- **New**: Task created but not started
- **In Progress**: Actively being worked on
- **Blocked**: Cannot proceed due to dependency or issue
- **Code Review**: Technical review in progress (if applicable)
- **Testing**: Validation and testing phase
- **Done**: Complete and accepted

**Progress Indicators**:

- **Remaining Work**: Update hours remaining as work progresses
- **Comments**: Daily updates on progress and any issues
- **Attachments**: Code snippets, test results, documentation drafts

> [!IMPORTANT]
> **Daily Updates**: Team members should update task status and remaining work daily to maintain visibility into sprint progress.

**Task Assignment Strategies**:

**Single Owner Model**:

- Each task assigned to one person for clear accountability
- Owner responsible for all aspects of the task
- Best for simple, self-contained tasks

**Collaborative Model**:

- Multiple people can work on related tasks
- Regular coordination required between team members
- Good for knowledge transfer and complex work

**Expertise-Based Assignment**:

- Match tasks to team member expertise areas
- AD tasks → AD specialist, Exchange tasks → Exchange specialist
- Ensures quality and efficiency

**Learning-Oriented Assignment**:

- Assign tasks to help team members learn new areas
- Pair experienced team member with learner
- Balance learning goals with delivery timelines

**Common Task Patterns for IAM Teams**:

**Development Pattern**:

1. Requirements Analysis Task
2. Design/Architecture Task
3. Development Task
4. Unit Testing Task
5. Integration Testing Task
6. Documentation Task

**Deployment Pattern**:

1. Environment Preparation Task
2. Deployment Planning Task
3. Deployment Execution Task
4. Verification Testing Task
5. Rollback Preparation Task
6. Go-Live Communication Task

**Integration Pattern**:

1. API/Interface Analysis Task
2. Connection Configuration Task
3. Data Mapping Task
4. Error Handling Implementation Task
5. End-to-End Testing Task
6. Monitoring Setup Task

**Task Quality Checklist**:

Before marking a task as complete:

- [ ] All acceptance criteria met
- [ ] Code reviewed (if applicable)
- [ ] Testing completed and documented
- [ ] Documentation updated
- [ ] No blocking issues for dependent tasks
- [ ] Time tracking updated accurately

> [!WARNING]
> **Avoid Task Anti-Patterns**:
>
> - Making tasks too vague ("Work on certificate script")
> - Creating tasks without clear acceptance criteria
> - Not updating task status regularly

**Task Integration with Azure DevOps**:

**Linking and Relationships**:

- All tasks must be linked to parent User Story
- Use "Child" relationship type in Azure DevOps
- Link related tasks with "Related" relationship
- Reference blocking tasks in task descriptions

**Time Tracking**:

- Use "Original Estimate" for initial planning
- Update "Remaining Work" daily
- Track "Completed Work" for historical analysis
- Use time data for future estimation improvement

**Board Management**:

- Tasks appear as child items on the User Story card
- Can be tracked separately on task board view
- Use task status to understand User Story progress
- Filter board views by task type or assignee

> [!NOTE]
> **Tasks vs. Subtasks**: In Azure DevOps, Tasks are work items that can stand alone. If you need even more granular tracking, use the Description field to list subtasks rather than creating additional work items.

#### Bugs

Bugs represent defects, errors, or unexpected behavior in our scripts, tools, automation, or systems. Unlike User Stories, Bugs are reactive work items that address problems rather than deliver new capabilities. Proper bug tracking is essential for maintaining system reliability and improving our development processes.

**When to Create a Bug:**

- Script failures or runtime errors in production
- Unexpected behavior in custom tools or automation
- Automation that doesn't work as designed or documented
- Regression issues after changes (functionality that previously worked)
- Security vulnerabilities in custom scripts or tools
- Performance issues in existing automation
- Data integrity problems caused by scripts

> [!NOTE]
> **Bug vs. Enhancement**: If it's working as originally designed but needs improvement, create a User Story for enhancement rather than a Bug.

**Bug Creation Process:**

1. **Identify and Reproduce the Issue**
   - Document exact steps to reproduce the problem
   - Capture error messages, logs, and screenshots
   - Identify affected systems, users, or processes
   - Determine severity and business impact

2. **Create the Bug Work Item**
   - **Title**: Clear, specific description of the problem
   - **Description**: Detailed explanation including reproduction steps
   - **Severity**: Critical, High, Medium, Low based on business impact
   - **Priority**: Urgent, High, Medium, Low based on timing needs
   - **Environment**: Where the bug occurs (Production, Test, Development)

3. **Add Context and Links**
   - **Tags**: Area (AD, Exchange, etc.), bug type, affected component
   - **Attachments**: Error logs, screenshots, configuration files
   - **Links**: Related User Story, Feature, or previous work items

**IAM Team Bug Examples:**

##### Certificate Management Bug Examples

**Bug**: "Certificate renewal script fails with access denied error for wildcard certificates"

**Description**:

```text
The automated certificate renewal script (RenewCertificates.ps1) fails when attempting 
to renew wildcard certificates (*.domain.com) with the following error:

"Access denied: Insufficient permissions to access certificate private key"

Steps to Reproduce:
1. Run RenewCertificates.ps1 with -CertType "Wildcard"
2. Script processes normal certificates successfully
3. When encountering wildcard certificate, script fails at line 142
4. Error logged to Windows Event Log (Event ID 1001)

Expected Behavior:
- Script should renew wildcard certificates using service account permissions
- No access denied errors should occur
- All certificate types should be processed successfully

Actual Behavior:
- Script fails on wildcard certificates
- Process stops with unhandled exception
- Subsequent certificates in queue are not processed

Impact:
- 15 wildcard certificates not renewed automatically
- Manual intervention required every 30 days
- Potential service outages if certificates expire
```

**Acceptance Criteria**:

- Script successfully renews wildcard certificates without errors
- Service account permissions properly configured for all certificate types
- Error handling improved to continue processing other certificates if one fails
- Logging enhanced to provide clear status for each certificate type
- Regression testing completed for all certificate renewal scenarios

**Bug**: "Exchange mailbox quota monitoring sends duplicate alerts"

**Description**:

```text
The mailbox quota monitoring script (CheckQuotas.ps1) is sending duplicate alert 
emails for the same mailboxes within a 4-hour period.

Steps to Reproduce:
1. Mailbox reaches 85% quota threshold
2. Initial alert email sent correctly
3. Script runs again 4 hours later
4. Duplicate alert sent for same mailbox at same quota level

Expected Behavior:
- Single alert sent when threshold first reached
- No additional alerts until quota level changes or escalation threshold reached
- Clear tracking of alert history per mailbox

Actual Behavior:
- Multiple identical alerts sent for same quota situation
- Email recipients receiving notification fatigue
- Alert suppression logic not working correctly

Impact:
- 50+ duplicate alerts sent per day
- Important alerts may be ignored due to volume
- Reduced confidence in monitoring system reliability
```

##### Active Directory Bug Examples

**Bug**: "User account cleanup script incorrectly identifies active service accounts as inactive"

**Description**:

```text
The InactiveUserCleanup.ps1 script is incorrectly flagging service accounts as 
inactive users despite having recent activity.

Steps to Reproduce:
1. Run InactiveUserCleanup.ps1 with default parameters
2. Script queries last logon times across domain controllers
3. Service accounts with computer logons are flagged as inactive
4. Recommendation to disable accounts is generated

Expected Behavior:
- Service accounts should be excluded from inactive user reports
- Computer logons should be recognized as valid activity
- Clear distinction between user accounts and service accounts

Actual Behavior:
- 25 active service accounts flagged for cleanup
- Potential business disruption if recommendations followed
- Manual review required for all flagged accounts

Impact:
- Risk of disabling critical service accounts
- Additional manual verification work required
- Reduced automation efficiency and trust
```

**Bug Severity and Priority Guidelines:**

**Severity Levels**:

- **Critical (P0)**: System down, data loss, security breach
  - Production outages affecting multiple users
  - Data corruption or loss scenarios
  - Security vulnerabilities with active exploitation risk
  - *Response Time*: Immediate (within 2 hours)

- **High (P1)**: Major functionality broken, significant business impact
  - Key automation failing in production
  - Critical scripts not executing
  - Major performance degradation
  - *Response Time*: Same day (within 8 hours)

- **Medium (P2)**: Functionality impaired, workaround available
  - Non-critical features not working correctly
  - Minor automation issues with manual workarounds
  - Performance issues without service impact
  - *Response Time*: Within 2-3 business days

- **Low (P3)**: Minor issues, cosmetic problems
  - UI display issues in custom tools
  - Non-functional requirements (logging, formatting)
  - Enhancement requests disguised as bugs
  - *Response Time*: Next sprint or when resources available

> [!WARNING]
> **Severity vs. Priority**: Severity is about technical impact; Priority is about business urgency. A low-severity bug might have high priority if it affects a compliance audit.

**Bug Lifecycle Management:**

**Status Workflow**:

```text
New → Triaged → In Progress → Code Review → Testing → Resolved → Closed
     ↓
   Rejected/Duplicate
```

**Status Definitions**:

- **New**: Bug reported but not yet reviewed
- **Triaged**: Bug reviewed, severity/priority assigned, ready for work
- **In Progress**: Developer actively working on fix
- **Code Review**: Fix implemented, under peer review
- **Testing**: Fix deployed to test environment for validation
- **Resolved**: Fix completed and verified, ready for closure
- **Closed**: Bug fix deployed to production and confirmed working
- **Rejected**: Not a valid bug (by design, duplicate, cannot reproduce)

**Bug Triage Process:**

**Daily Bug Review** (10-15 minutes each morning):

1. **New Bug Assessment**
   - Verify bug is reproducible
   - Assign severity and priority levels
   - Determine root cause team/area
   - Link to related work items

2. **Assignment Strategy**
   - Critical/High bugs: Immediate assignment to subject matter expert
   - Medium bugs: Assign during sprint planning or mid-sprint check-in
   - Low bugs: Add to backlog for future sprints

3. **Communication**
   - Notify affected users of bug acknowledgment
   - Provide workarounds if available
   - Set expectations for resolution timeline

> [!TIP]
> **Bug Prevention**: During User Story completion, ask "What could go wrong?" and create test cases to prevent similar bugs.

**Root Cause Analysis:**

For Critical and High severity bugs, conduct root cause analysis:

**5 Whys Technique**:

1. **Why did the bug occur?** Script failed due to permission error
2. **Why was there a permission error?** Service account password expired
3. **Why did the password expire?** No automated password rotation
4. **Why is there no password rotation?** Process was manual and forgotten
5. **Why was it manual?** Lack of automation for service account management

**Root Cause Categories**:

- **Code Quality**: Logic errors, insufficient error handling, poor testing
- **Environment**: Configuration differences, missing dependencies, permissions
- **Process**: Inadequate testing procedures, poor change management
- **Knowledge**: Lack of understanding, insufficient documentation
- **Communication**: Requirements misunderstood, assumptions not validated

**Bug Resolution Best Practices:**

**Fix Implementation**:

- **Minimal Changes**: Fix only what's broken, avoid scope creep
- **Error Handling**: Improve error handling and logging as part of fix
- **Documentation**: Update runbooks and procedures if needed
- **Testing**: Comprehensive testing including edge cases and regression tests

**Verification Steps**:

1. **Developer Testing**: Fix works in development environment
2. **Peer Review**: Code review by another team member
3. **Test Environment**: Validation in environment matching production
4. **User Acceptance**: Confirmation from bug reporter if possible
5. **Production Monitoring**: Watch for related issues after deployment

**Bug Prevention Strategies:**

**Code Quality Improvements**:

- **Code Reviews**: Mandatory peer reviews for all script changes
- **Error Handling**: Consistent error handling patterns across all scripts
- **Logging**: Comprehensive logging for troubleshooting
- **Testing**: Unit tests for critical script functions

**Process Improvements**:

- **Definition of Done**: Include testing requirements
- **Change Management**: Proper testing and approval processes
- **Documentation**: Keep runbooks and procedures current
- **Knowledge Sharing**: Regular technical discussions and training

**Monitoring and Alerting**:

- **Proactive Monitoring**: Detect issues before users report them
- **Health Checks**: Regular validation of critical automation
- **Performance Metrics**: Track script execution times and success rates
- **Trend Analysis**: Identify patterns in bug reports

**Bug Reporting Templates:**

**Standard Bug Report Format**:

```text
Title: [Component] Brief description of issue

Environment: Production/Test/Development
Severity: Critical/High/Medium/Low
Affected Users: Number or description of impacted users

Steps to Reproduce:
1. 
2. 
3. 

Expected Behavior:


Actual Behavior:


Error Messages/Logs:


Screenshots/Attachments:


Related Work Items:


Business Impact:


Workaround (if available):

```

**Integration with Azure DevOps:**

**Linking Strategies**:

- **Parent Relationship**: Link to User Story or Feature where bug originated
- **Related Links**: Connect to similar bugs or related work items
- **Test Cases**: Link to test cases that should prevent regression
- **Commits**: Automatically link commits that fix the bug

**Tracking and Metrics**:

- **Bug Burndown**: Track bug resolution rate over time
- **Escape Rate**: Bugs found in production vs. during development
- **Recurrence Rate**: Bugs that reoccur after being fixed
- **Resolution Time**: Average time from report to fix by severity

**Dashboard Widgets**:

- Active bugs by severity and area
- Bug aging report (how long bugs remain open)
- Bug trends over time
- Team bug resolution velocity

> [!IMPORTANT]
> **Bug vs. Change Request**: Always confirm if the reported issue is actually a bug (something not working as designed) or a change request (working as designed but needs improvement).

---

> [!CAUTION]
> **Production Bug Protocol**: For Critical/High severity production bugs, follow emergency change procedures and notify stakeholders immediately.

#### Issues

Issues represent operational work, tracking items, and miscellaneous tasks that don't fit neatly into other work item categories. While User Stories focus on delivering new capabilities and Bugs address defects, Issues handle the "everything else" category of work that teams need to track and manage.

**When to Create an Issue:**

- Tracking external dependencies and vendor coordination
- ServiceNow ticket management and status tracking
- Operational incidents that require follow-up investigation
- Research and analysis tasks without direct deliverables
- Process improvement initiatives
- Knowledge management and documentation tasks
- Compliance and audit preparation activities
- Team administrative tasks and coordination work

> [!NOTE]
> **Issues vs. User Stories**: If the work delivers direct user value or functionality, create a User Story instead. Issues are for operational, administrative, or tracking work.

**Issue Creation Process:**

1. **Identify the Need**
   - Operational work that needs visibility and tracking
   - External dependencies that could impact sprint work
   - Administrative tasks that consume team time
   - Incidents requiring investigation or follow-up

2. **Define the Issue**
   - **Title**: Clear, specific description of what needs to be tracked
   - **Description**: Detailed explanation including context and requirements
   - **Category**: Type of issue (tracking, operational, research, administrative)
   - **Priority**: Urgency and importance to team operations
   - **Effort Estimate**: Time investment required

3. **Add Context and Links**
   - **Tags**: Area affected, issue type, priority level
   - **Attachments**: Reference documents, email threads, external links
   - **Links**: Related work items, dependencies, or follow-up items

**IAM Team Issue Examples:**

##### ServiceNow Integration and Tracking Issues

**Issue**: "Track ServiceNow integration project with IT Service Management team"

**Description**:

```text
Track the ongoing project to establish automated integration between ServiceNow 
and Azure DevOps for our IAM request management process.

Current Status:
- Initial requirements gathering completed
- Waiting for IT Service Management team to provide API documentation
- Timeline dependent on their Q2 priorities

Key Activities to Track:
- Weekly check-ins with ITSM team
- API documentation review and testing
- Security approval for system integration
- User acceptance testing with team members
- Training and rollout planning

External Dependencies:
- ITSM team availability and priorities
- Security team approval process
- Infrastructure team for network connectivity
- Business approval for process changes

Success Criteria:
- Automated work item creation from ServiceNow tickets
- Bi-directional status synchronization
- Reduced manual data entry by 80%
- Maintained audit trail for compliance
```

**Acceptance Criteria**:

- Weekly status updates documented in Issue comments
- Dependencies tracked and escalated when blocked
- Project timeline updated based on external inputs
- Final deliverable linked to appropriate User Stories
- Lessons learned documented for future integrations

**Issue**: "Coordinate certificate audit preparation with compliance team"

**Description**:

```text
Manage coordination and preparation activities for the annual certificate 
management audit scheduled for Q3.

Audit Scope:
- All SSL/TLS certificates managed by IAM team
- Certificate lifecycle management processes
- Automated renewal and monitoring systems
- Certificate inventory and documentation

Team Responsibilities:
- Prepare certificate inventory reports
- Document all certificate management procedures
- Provide evidence of monitoring and alerting systems
- Demonstrate compliance with certificate policies

External Coordination:
- Weekly meetings with compliance team
- Coordinate access for auditors
- Prepare documentation packages
- Schedule technical demonstrations

Timeline Considerations:
- Audit preparation: 6 weeks before audit date
- Documentation deadline: 2 weeks before audit
- Technical demonstrations: During audit week
- Follow-up remediation: 4 weeks post-audit
```

##### Operational Investigation Issues

**Issue**: "Investigate recurring Active Directory replication delays in Seattle office"

**Description**:

```text
Track investigation into recurring AD replication delays affecting the Seattle 
office. Issue impacts user authentication and group policy updates.

Problem Summary:
- Replication delays of 2-4 hours observed weekly
- Affects 200+ users in Seattle office
- No clear pattern identified yet
- Temporary workarounds in place

Investigation Activities:
- Network latency testing between sites
- Domain controller health analysis
- Review of replication topology
- Analysis of network traffic patterns
- Consultation with network team

Current Findings:
- WAN bandwidth utilization spikes during business hours
- Seattle DC memory utilization higher than baseline
- Possible correlation with backup window timing

Next Steps:
- Coordinate with network team for bandwidth analysis
- Plan DC memory upgrade during maintenance window
- Implement additional monitoring for early detection
- Document findings and recommendations
```

**Acceptance Criteria**:

- Root cause identified and documented
- Permanent solution implemented or planned
- Monitoring improved to prevent recurrence
- Seattle office stakeholders notified of resolution
- Knowledge base updated with troubleshooting steps

**Issue**: "Research and evaluate Azure AD Connect Health deployment"

**Description**:

```text
Research and evaluation project for deploying Azure AD Connect Health to 
improve monitoring and troubleshooting of our hybrid identity infrastructure.

Research Objectives:
- Evaluate benefits of Azure AD Connect Health
- Assess implementation requirements and dependencies
- Determine licensing and cost implications
- Identify potential risks and mitigation strategies

Key Research Areas:
- Agent deployment requirements and security implications
- Monitoring capabilities and alert configuration
- Integration with existing monitoring systems
- Reporting capabilities for management and compliance
- Best practices from Microsoft and industry sources

Deliverables:
- Research summary document
- Pros/cons analysis with recommendations
- Implementation plan if moving forward
- Cost/benefit analysis for management review
- Risk assessment and mitigation strategies

Timeline:
- Research phase: 3 weeks
- Document preparation: 1 week
- Management presentation: 1 week
- Decision and next steps: Following management review
```

##### External Dependency Tracking Issues

**Issue**: "Track vendor security patch deployment for certificate management appliance"

**Description**:

```text
Track critical security patch deployment by vendor for our certificate 
management appliance. Patch addresses CVE-2024-XXXX vulnerability.

Vendor Coordination:
- Patch released by vendor on MM/DD/YYYY
- Vendor requires scheduled maintenance window
- Estimated downtime: 4-6 hours
- Backup and rollback procedures required

Internal Coordination:
- Schedule maintenance window with change management
- Notify all certificate stakeholders of planned outage
- Prepare backup procedures and rollback plan
- Coordinate with network team for access during maintenance
- Plan validation testing post-patch

Risk Considerations:
- Vulnerability remains exposed until patch deployment
- Certificate renewals blocked during maintenance window
- Potential impact on automated certificate processes
- Need for manual certificate management during outage

Communication Plan:
- Initial notification: 2 weeks before maintenance
- Reminder notification: 1 week before maintenance
- Day-of-maintenance status updates
- Completion notification with validation results
```

##### Process Improvement Issues

**Issue**: "Develop team knowledge sharing rotation schedule"

**Description**:

```text
Create and implement a knowledge sharing rotation where team members present 
on their expertise areas to improve cross-functional capabilities.

Objectives:
- Improve team cross-training and knowledge distribution
- Reduce single points of failure in expertise areas
- Enhance team collaboration and understanding
- Document tribal knowledge in formal procedures

Planning Activities:
- Survey team members on expertise areas and learning interests
- Develop presentation schedule (monthly rotation)
- Create presentation format and standards
- Set up recording and documentation process
- Plan hands-on lab sessions for complex topics

Topics to Cover:
- Advanced PowerShell scripting techniques
- Certificate management deep dive
- Exchange administration best practices
- Azure AD Connect troubleshooting
- Security monitoring and alerting
- ServiceNow workflow optimization

Implementation Plan:
- Month 1: Survey and schedule development
- Month 2: First presentation (Active Directory focus)
- Ongoing: Monthly presentations with documented outcomes
- Quarterly: Review effectiveness and adjust format

Success Metrics:
- 100% team member participation
- Knowledge assessments show improvement
- Reduced escalations for cross-functional issues
- Positive team feedback on knowledge sharing value
```

**Issue Types and Categories:**

**Tracking Issues**:

- External vendor coordination
- ServiceNow ticket lifecycle management
- Project milestone tracking
- Audit preparation and compliance activities

**Operational Issues**:

- Incident investigation and follow-up
- Performance analysis and optimization
- System health monitoring and alerting
- Capacity planning and resource management

**Research Issues**:

- Technology evaluation and proof of concepts
- Best practice research and implementation
- Tool assessment and vendor comparisons
- Process improvement investigations

**Administrative Issues**:

- Team training and knowledge sharing
- Documentation and procedure updates
- Meeting coordination and facilitation
- Tool configuration and maintenance

**Issue Management Best Practices:**

**Issue Sizing Guidelines**:

Issues are typically tracked for effort visibility rather than estimated precisely:

- **Simple Tracking (1-5 hours)**: Status updates, basic coordination
- **Moderate Coordination (5-20 hours)**: Multi-party coordination, research projects
- **Complex Initiatives (20+ hours)**: Consider breaking into multiple Issues or converting to User Stories

**Status Tracking**:

- **New**: Issue created but not yet started
- **Active**: Work in progress, regular updates expected
- **Waiting**: Blocked by external dependencies
- **Monitoring**: Ongoing tracking with periodic check-ins
- **Resolved**: Completed or no longer relevant

**Communication Patterns**:

- **Regular Updates**: Weekly or bi-weekly status comments
- **Escalation Triggers**: Clear criteria for when to escalate blocked items
- **Stakeholder Notification**: Who needs to be informed of status changes
- **Documentation Requirements**: What information needs to be preserved

**Integration with Other Work Items**:

**Linking Strategies**:

- **Related**: Issues that track work related to specific User Stories or Features
- **Successor**: Issues that lead to future User Stories or development work
- **Dependency**: Issues that must be resolved before other work can proceed
- **Reference**: Issues that provide context or background for other work

**Conversion Patterns**:

- **Issue → User Story**: When tracking reveals need for new functionality
- **Issue → Bug**: When operational investigation identifies system defects
- **Issue → Feature**: When research leads to major initiative planning

> [!TIP]
> **Issue Evolution**: Be prepared to convert Issues to other work item types as understanding evolves. Start with an Issue for unclear work, then convert to appropriate type when scope becomes clear.

**Issue Quality Checklist**:

Before creating an Issue:

- [ ] Work doesn't fit better as User Story, Bug, or Task
- [ ] Clear tracking objective or coordination need identified
- [ ] Success criteria or completion conditions defined
- [ ] External dependencies and stakeholders identified
- [ ] Appropriate Epic assignment for area categorization
- [ ] Regular update schedule planned and communicated

**Common Issue Anti-Patterns to Avoid**:

> [!WARNING]
> **Avoid These Mistakes**:
>
> - Using Issues for development work that should be User Stories
> - Creating Issues without clear completion criteria
> - Tracking Issues that never get updated or resolved
> - Using Issues to avoid properly categorizing work

**Integration with Azure DevOps**:

**Dashboard Visibility**:

- Issues appear on team boards alongside other work items
- Can be filtered separately for operational vs. development work
- Useful for tracking external dependencies that impact sprint planning
- Status tracking helps identify when blocked work can proceed

**Reporting and Metrics**:

- Track time spent on operational vs. development work
- Monitor external dependencies that frequently block progress
- Measure effectiveness of coordination and communication activities
- Identify patterns in operational issues for process improvement

> [!IMPORTANT]
> **Issues for Team Health**: Use Issues to track important operational work that might otherwise be invisible. This helps demonstrate the full scope of team responsibilities and ensures operational excellence isn't overlooked in favor of development work.

### Work Item Relationships

```text
Epic (Strategic Domain)
└── Feature (Major Initiative)
    ├── User Story (Deliverable Unit)
    │   ├── Task (Technical Work)
    │   ├── Task (Testing)
    │   └── Bug (Defect)
    └── User Story (Another Deliverable)
        └── Issue (Related Operational Work)
```

## Sprint Management

### Sprint Structure

- **Sprint Length**: 2 weeks (10 working days)
- **Sprint Start**: Monday (following planning meeting)
- **Sprint End**: Sunday (following next planning meeting)

### Sprint Planning Process

#### Pre-Planning (Wednesday before sprint ends)

- Product Owner reviews and prioritizes backlog
- Team members provide estimates for upcoming work
- Project Manager identifies any dependencies or blockers

#### Sprint Planning Meeting (Thursday - End of current sprint)

**Duration**: 2 hours
**Attendees**: Entire team, PM, optional manager attendance

**Agenda**:

1. **Sprint Review** (45 minutes)
   - Demo completed User Stories and Features
   - Review sprint metrics and velocity
   - Discuss what went well and challenges faced

2. **Backlog Triage** (30 minutes)
   - Review new ServiceNow requests and operational needs
   - Prioritize urgent items
   - Estimate new work items

3. **Next Sprint Planning** (45 minutes)
   - Select User Stories for next sprint based on capacity
   - Confirm acceptance criteria and definition of done
   - Identify dependencies and assign primary owners

### Sprint Execution

#### Daily Work Management

- Team members update work item status throughout the day
- Use comments in work items to communicate progress and blockers
- Update time estimates and remaining work

#### Mid-Sprint Check-in (Tuesday)

**Duration**: 30 minutes
**Format**: Quick standup or team chat

**Focus Areas**:

- Progress against sprint goals
- Blocking issues or dependencies
- Need for scope adjustments

> [!TIP]
> Use the mid-sprint check-in to adjust scope if you're falling behind on sprint goals

### Sprint Metrics

We track the following metrics to improve our process:

- **Velocity**: Story points or hours completed per sprint
- **Burndown**: Work remaining over time
- **Cycle Time**: Time from start to completion of work items
- **Defect Rate**: Bugs per completed User Story

## � Meetings & Schedule

### Regular Meeting Cadence

#### Sprint Planning & Review (Every 2 weeks - Thursday)

**Duration**: 2 hours  
**Attendees**: All team members, Project Manager, Product Owner, optional management  
**Location**: Conference room or Teams meeting

**Agenda**:

- Sprint Review (45 min) - Demo completed work
- Backlog Triage (30 min) - New items and priorities  
- Sprint Planning (45 min) - Select next sprint work

**Preparation Required**:

- Product Owner: Updated backlog priorities
- Team Members: Demo materials for completed work
- Project Manager: Sprint metrics and timeline updates

#### Mid-Sprint Check-in (Tuesday of second week)

**Duration**: 30 minutes  
**Attendees**: All team members, Project Manager  
**Format**: Standup or brief team chat

**Focus**:

- Progress update on current sprint goals
- Identify and address blocking issues
- Scope adjustments if needed

#### Monthly Retrospective (First Thursday of month)

**Duration**: 1 hour  
**Attendees**: All team members, Project Manager

**Agenda**:

- What went well in the past month
- What could be improved
- Action items for process improvements
- Team feedback and suggestions

#### Backlog Grooming (Weekly - Wednesday)

**Duration**: 1 hour  
**Attendees**: Product Owner, 2-3 team members (rotating)

**Purpose**:

- Review and estimate new work items
- Clarify requirements and acceptance criteria
- Identify dependencies and technical considerations

### Ad-Hoc Meetings

#### Emergency Response

For critical issues requiring immediate attention:

- Emergency standup within 2 hours of issue identification
- Daily briefings until resolution
- Post-incident review within 48 hours of resolution

#### Technical Deep-Dives

As needed for complex technical decisions:

- Architecture reviews for major changes
- Tool evaluation sessions
- Knowledge transfer sessions

## Processes & Workflows

### Work Item Lifecycle

#### 1. Work Item Creation

**Sources of Work**:

- ServiceNow requests (manually created in Azure DevOps)
- Proactive improvements identified by team
- Management initiatives
- Technical debt and maintenance
- Bug reports from operations

**Creation Process**:

1. Create appropriate work item type (User Story, Bug, Issue)
2. Assign to correct Epic and Feature (if applicable)
3. Add detailed description and acceptance criteria
4. Tag with relevant area (AD, Exchange, etc.)
5. Set initial priority and effort estimate

#### 2. Backlog Management

- Product Owner maintains prioritized backlog
- Weekly backlog grooming sessions to review and estimate new items
- Items must meet "Definition of Ready" before sprint inclusion:
  - Clear description and acceptance criteria
  - Effort estimate provided
  - Dependencies identified
  - Assigned to appropriate Epic/Feature

> [!WARNING]
> Items that don't meet the Definition of Ready should not be included in sprint planning

#### 3. Sprint Execution Workflow

```text
New → To Do → In Progress → Code Review → Testing → Done
```

**Status Definitions**:

- **New**: Newly created, not yet groomed
- **To Do**: Ready for sprint, accepted into current iteration
- **In Progress**: Actively being worked on
- **Code Review**: Technical review of scripts/tools (if applicable)
- **Testing**: Validation and testing phase
- **Done**: Meets acceptance criteria and Definition of Done

> [!CAUTION]
> Never move items directly to Done without following the proper workflow and getting required approvals

#### 4. ServiceNow Integration Process

Since we don't have direct integration, we follow this manual process:

1. **ServiceNow Request Received**
   - Evaluate request complexity and priority
   - Create corresponding Azure DevOps work item
   - Link ServiceNow ticket number in description
   - Add to current sprint if urgent, or backlog if not

2. **Work Execution**
   - Update both ServiceNow and Azure DevOps status
   - Document solution in Azure DevOps
   - Communicate progress to requestor via ServiceNow

3. **Completion**
   - Mark Azure DevOps item as Done
   - Close ServiceNow ticket with resolution details
   - Update any relevant documentation

### Definition of Done

> [!IMPORTANT]
> All work items must meet these criteria before being marked as Done:

**For User Stories**:

- All acceptance criteria met
- Code/scripts reviewed by another team member
- Testing completed (functional and regression)
- Documentation updated (if applicable)
- Deployed to production (if applicable)
- Product Owner acceptance obtained

> [!WARNING]
> User Stories cannot be marked as Done without explicit Product Owner acceptance

**For Bugs**:

- Root cause identified and documented
- Fix implemented and tested
- Regression testing completed
- Prevention measures documented

**For Tasks**:

- Specific deliverable completed
- Quality check performed
- Dependencies notified of completion

## � Tools & Reporting

### Azure DevOps Configuration

#### Board Setup

- **Columns**: New → To Do → In Progress → Code Review → Testing → Done
- **Swimlanes**: Organized by Epic or work area (AD, Exchange, etc.)
- **Card Fields**: Assigned To, Work Item Type, Tags, Effort

#### Tags Strategy

Tags are essential for organizing, filtering, and reporting on work items in Azure DevOps. Our IAM team uses a structured tagging approach to enable efficient work management and clear visibility into team activities.

**Why Tags Matter:**

- Enable quick filtering and searching of work items
- Support automated reporting and dashboard creation
- Facilitate sprint planning and capacity management
- Help identify patterns and trends in team work
- Improve collaboration through clear categorization

**Tag Naming Conventions:**

> [!IMPORTANT]
> **Tag Format**: Use PascalCase for all tags (e.g., `ActiveDirectory`, `CriticalPriority`, `ExternalDependency`) to ensure consistency and prevent duplicate tags with different capitalizations.

**Required Tag Categories:**

##### 1. Area Tags (Required for all work items)

- **ActiveDirectory**: AD infrastructure, domain controllers, group policy
- **Exchange**: Email systems, mailbox management, transport rules
- **CertificateManagement**: PKI, SSL/TLS certificates, renewals
- **IdentityManagement**: User provisioning, access management, lifecycle
- **Operations**: Day-to-day operations, monitoring, maintenance
- **Requests**: ServiceNow ticket processing, user requests

##### 2. Work Type Tags (Required for User Stories and Tasks)

- **Script**: PowerShell scripts, automation development
- **Tool**: Custom tools, utilities, applications
- **Documentation**: Runbooks, procedures, knowledge base
- **Infrastructure**: Server setup, configuration, hardware
- **Integration**: System connections, API work, data flows
- **Research**: Investigation, analysis, proof of concepts
- **Training**: Knowledge transfer, skill development

##### 3. Priority Tags (Optional - use when priority differs from work item priority field)

- **CriticalPriority**: Must be completed immediately
- **HighPriority**: Important for current sprint success
- **MediumPriority**: Standard priority work
- **LowPriority**: Can be deferred if needed

##### 4. Status/Coordination Tags (As needed)

- **Blocked**: Work cannot proceed due to dependencies
- **ExternalDependency**: Waiting on external teams or vendors
- **ReadyForReview**: Completed work awaiting approval
- **NeedsApproval**: Requires management or stakeholder approval
- **SecurityReview**: Needs security team evaluation
- **ComplianceReview**: Requires compliance team validation

##### 5. Technical Complexity Tags (Optional for estimation help)

- **SimpleWork**: Basic tasks, minimal complexity
- **ModerateWork**: Standard complexity requiring some expertise
- **ComplexWork**: High complexity, multiple systems, significant risk

##### 6. Environment Tags (For deployment-related work)

- **Development**: Dev environment work
- **Testing**: Test environment activities
- **Staging**: Staging/UAT environment
- **Production**: Production environment changes

**Tag Usage Examples by Work Item Type:**

**User Story Example**:

```text
Title: "As an administrator, I want automated certificate renewal alerts"
Tags: CertificateManagement, Script, MediumPriority, Production
```

**Bug Example**:

```text
Title: "PowerShell script fails on wildcard certificate renewal"
Tags: CertificateManagement, Script, HighPriority, Production, SecurityReview
```

**Task Example**:

```text
Title: "Create PowerShell script for certificate scanning"
Tags: CertificateManagement, Script, Development, ModerateWork
```

**Issue Example**:

```text
Title: "Coordinate with vendor for security patch deployment"
Tags: CertificateManagement, ExternalDependency, NeedsApproval, Blocked
```

**Specialized Tags for IAM Team:**

**Certificate Management Specific**:

- `SSLCertificate`: SSL/TLS certificate work
- `CodeSigningCert`: Code signing certificate tasks
- `CertificateAuthority`: CA-related work
- `CertificateRenewal`: Renewal process improvements
- `CertificateMonitoring`: Monitoring and alerting systems

**Active Directory Specific**:

- `DomainController`: DC-related work
- `GroupPolicy`: GPO management and updates
- `UserAccount`: User account management
- `ServiceAccount`: Service account administration
- `ADReplication`: Replication troubleshooting

**Exchange Specific**:

- `MailboxManagement`: Mailbox administration
- `TransportRules`: Mail flow rules
- `ExchangeOnline`: Cloud Exchange work
- `MailSecurity`: Email security measures

**Identity Management Specific**:

- `UserProvisioning`: Account creation processes
- `AccessReview`: Access certification work
- `PasswordPolicy`: Password management
- `MultiFactorAuth`: MFA implementation

**Tag Best Practices:**

**When Adding Tags**:

1. **Always Include Area Tag**: Every work item must have at least one area tag
2. **Add Work Type Tag**: For User Stories and Tasks, include the type of work
3. **Use Status Tags Sparingly**: Only when the information isn't clear from work item status
4. **Be Consistent**: Use established tags rather than creating new variations
5. **Think About Reporting**: Consider how tags will be used in queries and dashboards

**Tag Maintenance**:

- **Regular Review**: Monthly review of tag usage and consistency
- **Tag Consolidation**: Merge similar tags with low usage
- **Team Agreement**: Get team consensus before adding new standard tags
- **Documentation**: Maintain this list as the authoritative tag reference

> [!WARNING]
> **Avoid Tag Sprawl**: Don't create new tags without team discussion. Too many tags make filtering and reporting ineffective.

**Using Tags for Filtering and Queries:**

**Common Filter Scenarios**:

**All Active Directory work in current sprint**:

```wiql
Area Path = @CurrentIteration AND Tags Contains "ActiveDirectory"
```

**All blocked work items**:

```wiql
Tags Contains "Blocked" OR Tags Contains "ExternalDependency"
```

**Certificate management scripts in development**:

```wiql
Tags Contains "CertificateManagement" AND Tags Contains "Script" AND Tags Contains "Development"
```

**High priority production work**:

```wiql
Tags Contains "Production" AND (Tags Contains "HighPriority" OR Tags Contains "CriticalPriority")
```

**Work requiring external approval**:

```wiql
Tags Contains "NeedsApproval" OR Tags Contains "SecurityReview" OR Tags Contains "ComplianceReview"
```

**Dashboard and Reporting Applications:**

**Sprint Planning Dashboards**:

- Filter by area tags to see workload distribution
- Use complexity tags to assess sprint capacity
- Identify blocked items that need attention

**Management Reporting**:

- Track work distribution across IAM areas
- Monitor external dependency impacts
- Report on security and compliance review items

**Team Efficiency Analysis**:

- Compare estimated vs. actual effort by complexity tags
- Identify areas with frequent blocking issues
- Track work type distribution over time

**Tag Migration and Evolution:**

**When Changing Tag Standards**:

1. **Document Changes**: Update this guide with new tag conventions
2. **Bulk Updates**: Use Azure DevOps queries to update existing work items
3. **Team Communication**: Announce changes in team meetings
4. **Gradual Adoption**: Allow transition period for new tag adoption

**Quarterly Tag Review Process**:

1. **Usage Analysis**: Review tag usage statistics
2. **Team Feedback**: Collect input on tag effectiveness
3. **Cleanup Activities**: Remove unused or redundant tags
4. **Standard Updates**: Revise tag standards based on team needs

> [!TIP]
> **Start Simple**: Begin with the core area and work type tags, then add specialized tags as team needs become clear.

**Integration with Azure DevOps Features:**

**Queries and Searches**:

- Save frequently used tag-based queries for easy access
- Create shared queries for common team filtering needs
- Use tag-based queries for sprint planning and backlog grooming

**Dashboards and Widgets**:

- Create pie charts showing work distribution by area tags
- Build tables filtering by priority or status tags
- Monitor trend charts for specific tag combinations

**Notifications and Alerts**:

- Set up alerts for high-priority tagged items
- Create notifications for blocked work items
- Monitor external dependency tags for follow-up needs

> [!IMPORTANT]
> **Tag Consistency is Key**: The value of tags comes from consistent application across all team work items. Make tagging part of your Definition of Ready for work items.

#### Custom Fields (if configured)

- **ServiceNow Ticket**: Link to original request
- **Business Impact**: High/Medium/Low
- **Technical Complexity**: Complex/Medium/Simple

### Dashboards & Widgets

#### Team Dashboard

**Purpose**: Daily team visibility into current sprint

**Widgets**:

- Sprint Burndown Chart
- Current Sprint work by status
- Work by area (pie chart)
- Recently completed items
- Blocked items list

#### Management Dashboard  

**Purpose**: Executive summary and trend analysis

**Widgets**:

- Velocity trend over time
- Work completion by Epic
- Bug trend analysis
- Cycle time metrics
- Team capacity vs. demand

#### Personal Dashboards

Each team member can create personal dashboards showing:

- Items assigned to them
- Items they're following
- Recent activity in their primary area

### Reporting & Documentation

#### Sprint Reports

Generated at end of each sprint:

- **Sprint Summary**: Completed vs. planned work
- **Velocity Report**: Story points or hours completed
- **Burndown Analysis**: How work progressed through sprint
- **Quality Metrics**: Bugs found, cycle time, rework

#### Monthly Reports

- **Epic Progress**: Status of major initiatives
- **Team Metrics**: Velocity trends, capacity utilization
- **Process Health**: Meeting attendance, estimation accuracy
- **Technical Debt**: Identified issues needing attention

#### Integration with MS Project Online

Project Manager maintains alignment between:

- Azure DevOps sprint data
- MS Project timeline and milestones
- Resource allocation and planning
- Executive reporting requirements

### Repository Management

#### Code Organization

- **Scripts**: Organized by functional area (AD, Exchange, etc.)
- **Documentation**: Runbooks, procedures, architectural decisions
- **Tools**: Custom utilities and automation
- **Templates**: Standardized scripts and configurations

#### Version Control Practices

**Repository Structure**:

- **Main/Master Branch**: Production-ready code only
- **Feature Branches**: Individual work items and development
- **Hotfix Branches**: Critical production fixes
- **Release Branches**: Preparing releases (if applicable)

**Branching Strategy**:

- Create feature branches from `main` for all development work
- Use descriptive branch names: `feature/work-item-id-short-description`
- Keep branches focused on single work items or features
- Delete branches after successful merge to keep repository clean

**Commit Best Practices**:

- **Commit Messages**: Clear, descriptive messages that explain the "what" and "why"
  - Good: `Add certificate expiration monitoring script - fixes #123`
  - Bad: `Updated script` or `Fix`
- **Commit Frequency**: Commit small, logical changes frequently
- **Work Item Linking**: Include work item IDs using keywords:
  - `fixes #123`, `closes #456`, `resolves #789`
  - `related to #123`, `ref #456`

**Code Review Requirements**:

- **Mandatory Reviews**: All changes require at least one reviewer
- **Review Criteria**:
  - Code functionality and logic
  - Security considerations (especially for IAM scripts)
  - Error handling and logging
  - Documentation and comments
  - Adherence to team coding standards
- **Reviewer Selection**: Preferably someone with expertise in the affected area
- **Review Timeframe**: Reviews should be completed within 24-48 hours

**Pull Request Process**:

1. **Create Pull Request**: Include clear title and description
2. **Link Work Items**: Ensure automatic linking is working
3. **Add Reviewers**: Assign appropriate team members
4. **Address Feedback**: Respond to all review comments
5. **Merge Strategy**: Use "Squash and merge" for cleaner history
6. **Post-Merge**: Delete feature branch automatically

**Security and Compliance**:

- **Sensitive Data**: Never commit passwords, API keys, or credentials
- **Code Scanning**: Enable security scanning if available
- **Audit Trail**: Maintain clear history for compliance requirements
- **Access Control**: Limit who can merge to main branch

**File Organization Standards**:

```text
/Scripts
  /ActiveDirectory
    /UserManagement
    /GroupManagement
    /Reporting
  /Exchange
    /Mailbox
    /Distribution
    /Monitoring
  /Certificates
    /Renewal
    /Monitoring
    /Deployment
/Documentation
  /Runbooks
  /Procedures
  /Architecture
/Tools
  /Utilities
  /Automation
/Templates
  /Scripts
  /Configurations
```

**Tagging and Releases**:

- **Version Tags**: Use semantic versioning (v1.0.0, v1.1.0, v2.0.0)
- **Release Notes**: Document changes, fixes, and new features
- **Stable Releases**: Tag stable versions of critical scripts
- **Rollback Strategy**: Maintain ability to quickly revert to previous versions

**Local Development Workflow**:

1. **Sync with Main**: Always start with latest main branch

   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create Feature Branch**: From work item or manually

   ```bash
   git checkout -b feature/123-cert-renewal-script
   ```

3. **Make Changes**: Develop and test locally
4. **Commit Changes**: With descriptive messages

   ```bash
   git add .
   git commit -m "Add automated cert renewal logic - fixes #123"
   ```

5. **Push and Create PR**: Push branch and create pull request

   ```bash
   git push origin feature/123-cert-renewal-script
   ```

**Conflict Resolution**:

- **Prevention**: Keep feature branches short-lived and sync regularly
- **Resolution Process**:
  1. Communicate with team about conflicts
  2. Resolve conflicts locally before pushing
  3. Test thoroughly after conflict resolution
  4. Document any significant merge decisions

**Backup and Recovery**:

- **Azure DevOps Backup**: Repository is automatically backed up
- **Local Copies**: Team members maintain local copies
- **Critical Scripts**: Additional backup of production scripts
- **Recovery Testing**: Periodic verification of restore procedures

#### Creating Branches from Work Items

Azure DevOps allows you to create branches directly from work items, which automatically links your code changes to the work being done.

**How to Create a Branch from a Work Item**:

1. **From the Work Item**:
   - Open the User Story, Bug, or Task in Azure DevOps
   - Click on the "..." (More actions) menu
   - Select "New branch"
   - Choose the source branch (usually `main` or `master`)
   - Azure DevOps will auto-generate a branch name like `users/[username]/[work-item-id]-[work-item-title]`
   - Optionally customize the branch name
   - Click "Create branch"

2. **From the Boards View**:
   - Right-click on a work item card
   - Select "New branch"
   - Follow the same process as above

**Branch Naming Conventions**:

- Auto-generated: `users/jstreeter/123-implement-cert-renewal`
- Manual format: `feature/[work-item-id]-[short-description]`
- Bug fixes: `bugfix/[work-item-id]-[short-description]`

**Benefits of Work Item Branches**:

- Automatic linking between code changes and work items
- Easy tracking of which commits belong to which work item
- Better traceability during code reviews
- Automatic work item updates when pull requests are completed

> [!TIP]
> When you create a branch from a work item, all commits and pull requests will automatically appear in the work item's Development section, providing full traceability.

**Workflow Example**:

1. Create branch from User Story #123
2. Make code changes in your local environment
3. Commit with descriptive messages: `git commit -m "Add certificate expiration check - fixes #123"`
4. Push branch and create pull request
5. Link pull request completion to automatically update work item status

> [!NOTE]
> All script changes require code review before merging to maintain quality and knowledge sharing

## Onboarding Checklist

### For New Team Members

#### Week 1: Access & Orientation

- [ ] Azure DevOps access granted and configured
- [ ] Added to team project with appropriate permissions
- [ ] ServiceNow access verified
- [ ] Introduction to team roles and current Product Owner
- [ ] Review this guide with Project Manager or team lead
- [ ] Attend sprint planning meeting as observer
- [ ] Shadow experienced team member for 2-3 work items

> [!TIP]
> The first week is about learning and observing. Don't worry about contributing to work items yet - focus on understanding the process.

#### Week 2: Process Integration  

- [ ] Create first work item and practice board management
- [ ] Participate in mid-sprint check-in
- [ ] Complete small User Story with guidance
- [ ] Learn tagging and linking conventions
- [ ] Set up personal dashboard
- [ ] Review team's Epic areas and identify primary interest

#### Week 3-4: Full Participation

- [ ] Take ownership of User Stories in sprint
- [ ] Contribute to sprint planning discussions
- [ ] Present completed work in sprint review
- [ ] Provide input in retrospective meeting
- [ ] Identify area of primary responsibility

### For Teams Adopting This Methodology

#### Planning Phase (Week 1-2)

- [ ] Identify Product Owner and Project Manager roles
- [ ] Define team's Epic areas (customize from our model)
- [ ] Set up Azure DevOps project structure
- [ ] Configure boards with appropriate columns and tags
- [ ] Create initial Epic and Feature backlog
- [ ] Plan first sprint planning meeting

> [!IMPORTANT]
> Take time to customize Epic areas to match your team's actual work domains - don't just copy our model exactly.

#### Implementation Phase (Week 3-4)

- [ ] Conduct first sprint planning session
- [ ] Execute first 2-week sprint
- [ ] Hold mid-sprint check-ins
- [ ] Complete first sprint review and retrospective
- [ ] Adjust processes based on initial learnings

> [!CAUTION]
> Don't try to perfect everything in the first sprint. Focus on getting the basic process working first.

#### Optimization Phase (Week 5-8)

- [ ] Refine estimation accuracy
- [ ] Optimize dashboard and reporting
- [ ] Establish rhythm for backlog grooming
- [ ] Fine-tune Definition of Done criteria
- [ ] Implement process improvements from retrospectives

### Setup Checklists

#### Azure DevOps Project Setup

- [ ] Project created with Agile template
- [ ] Team members added with appropriate permissions
- [ ] Board columns configured: New → To Do → In Progress → Code Review → Testing → Done
- [ ] Epic work items created for each major area
- [ ] Tags configured for areas and types
- [ ] Basic dashboard created with burndown and velocity widgets
- [ ] Repository structure established

> [!NOTE]
> This checklist ensures you have all the basic infrastructure in place before starting your first sprint.

#### Meeting Cadence Setup

- [ ] Sprint Planning meetings scheduled (every 2 weeks)
- [ ] Mid-sprint check-ins scheduled (weekly)
- [ ] Monthly retrospectives scheduled
- [ ] Backlog grooming sessions scheduled (weekly)
- [ ] Meeting locations/links configured
- [ ] Calendar invites sent to all team members

#### Integration Setup

- [ ] MS Project Online integration configured (if applicable)
- [ ] ServiceNow ticket tracking process documented
- [ ] Code repository structure established
- [ ] Version control workflows defined
- [ ] Documentation templates created

## FAQ

### General Questions

**Q: Why do we use Azure DevOps instead of just ServiceNow for everything?**  
A: Azure DevOps provides better visibility into our technical work, allows us to track bugs and improvements in our scripts/tools, supports agile planning, and integrates with our code repositories. ServiceNow remains our interface with customers, but Azure DevOps is our internal work management system.

**Q: How do we handle urgent requests that come in mid-sprint?**  
A: Urgent items can be added to the current sprint during the mid-sprint check-in. If the item is truly critical, the team may need to move other work to the backlog to maintain sprint scope.

**Q: What's the difference between a User Story and a Task?**  
A: User Stories deliver value to end users and can be demoed. Tasks are technical work items that support User Stories but don't necessarily have user-facing value (like "Update documentation" or "Refactor script").

### Process Questions

**Q: Do we always need to create Features, or can User Stories go directly under Epics?**  
A: For smaller work items, User Stories can go directly under Epics. Use Features when you have a larger initiative that spans multiple sprints and contains several related User Stories.

**Q: How detailed should our acceptance criteria be?**  
A: Detailed enough that anyone on the team could pick up the work item and understand what "done" looks like. Include specific scenarios, expected outcomes, and any technical requirements.

**Q: What happens if we don't finish all work in a sprint?**  
A: Incomplete work moves to the next sprint. During the sprint review, we analyze why work wasn't completed and adjust planning for future sprints. This is normal and expected as teams learn their capacity.

### Technical Questions

**Q: Should we create branches for every User Story?**  
A: For significant script changes or new tools, yes. For small fixes or configuration changes, you may work directly in the main branch. When in doubt, use a branch and do a code review. Creating branches directly from work items in Azure DevOps provides automatic linking and better traceability.

**Q: How do we link commits to work items?**  
A: Use work item IDs in your commit messages with keywords like "fixes", "closes", or "resolves". Example: `git commit -m "Add logging to cert script - fixes #123"`. When you create branches from work items, this linking happens automatically.

**Q: What happens when we complete a pull request linked to a work item?**  
A: You can configure Azure DevOps to automatically transition the work item state when the pull request is completed. This helps keep work items up-to-date without manual intervention.

**Q: How do we handle documentation updates?**  
A: Documentation updates can be Tasks under User Stories, or separate User Stories if they're substantial (like creating a new runbook). Always update documentation as part of your Definition of Done.

**Q: What if a bug is found in production?**  
A: Create a Bug work item immediately, assess priority, and either add it to the current sprint (if urgent) or prioritize it for the next sprint. Always link bugs to the original User Story if possible.

### Administrative Questions

**Q: Who can create Epics and Features?**  
A: The Product Owner typically creates Epics and Features, but team members can suggest them. All Epic and Feature creation should be discussed during backlog grooming.

**Q: How do we track time spent on work items?**  
A: Use the time tracking features in Azure DevOps. Update "Completed Work" and "Remaining Work" fields regularly. This helps with future estimation and sprint planning.

**Q: Can we change our sprint schedule?**  
A: Sprint schedules should be stable, but can be adjusted if there's a business need. Any changes should be discussed with the entire team and stakeholders, and should align with other team meetings and deadlines.

**Q: What permissions do team members need in Azure DevOps?**  
A: Team members typically need "Contributor" level access to create and edit work items, update boards, and access repositories. The Project Manager and Product Owner may need additional permissions for reporting and configuration.

### Troubleshooting

**Q: What if our velocity is highly inconsistent?**  
A: This is common in the first few months. Focus on improving estimation accuracy, breaking down work items into smaller pieces, and identifying external dependencies that affect your capacity.

**Q: How do we handle work that spans multiple Epics?**  
A: Create User Stories in each relevant Epic and link them with "Related" relationships. Document the cross-Epic dependencies in work item descriptions and discuss during planning.

**Q: What if someone leaves the team mid-sprint?**  
A: Reassign their work items to other team members, adjust sprint scope if necessary, and update capacity planning for future sprints. Document any knowledge transfer needs as new work items.

---

## Additional Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Agile Planning Best Practices](https://docs.microsoft.com/en-us/azure/devops/boards/plans/)
- Team-specific templates and runbooks (link to internal documentation)
- Contact: [Project Manager] for process questions, [Product Owner] for priority questions
