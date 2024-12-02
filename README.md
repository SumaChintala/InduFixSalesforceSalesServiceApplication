# InduFixSalesforceSalesServiceApplication
This is the Application for InduFix Sales and Service Cloud in Salesforce
Functional Requirements Documentation for InduFix
1. Purpose of the Document
The purpose of this document is to define the functional requirements for the Salesforce implementation for InduFix. These requirements address Sales Management and Customer Support functionalities using Sales Cloud and Service Cloud while integrating external systems and automating key processes.
2. Scope
The Salesforce application is to enable:
•	Sales Managers to manage leads, opportunities, quotes, Orders, Assets and contracts effectively.
•	Customer Support to handle cases efficiently while ensuring SLA compliance.
•	Cases resolution SLAs will be based on either Company level special service agreements or Equipment model related agreements. i.e: companies can have pre-agreed SLA or some particular device will have it’s own SLA
•	When a particular case has both Company level SLA and Asset level then the higher one will be choosen
•	Automated integration of ERP and website data to streamline dataflows and reduce manual work. (I have used Google Salesforce connector to setup data integration to Salesforce from Google Sheets)
•	Sales and Service dashboards for monitoring sales and service cloud activities.
•	Salesforce users should be able to login through SSO based on Azure DP (Ignored this requirement as I don’t have Azure DP available)
3. Technical Specification:
Sales Cloud
•	Sales Manager Profile Configuration 
o	Sales Manager Profile should have access to: 
	Leads, Contacts, Opportunities, Opportunity Products, Product2, PriceBook, PriceBook Entries, Tasks, Events, Activities, and Accounts
	Quotes, Contracts, Orders, and Assets
	Dashboards and Reports
•	Custom Field for MDM Integration 
o	MDM ID external ID field on the Account object to integrate with external systems. This field serves as an External Identifier to keep the data in sync between Salesforce and external MDM application.
•	Sales Process Customization 
o	Sales process must include: 
	Engineering Review and Manufacturing Preparation stages
	System should enforce that the Opportunity is going through the mandatory stages without fail.
•	Lead Conversion and Quote Creation 
o	Sales team need to convert the Lead, Lead conversion screen will guide the user to select the existing Account/Contact/Opportunity if found in the advanced search 
o	Once the products are added to the Opportunity users will manually create the Quote and Quote Documents, to negotiate with the customers.
o	After Quote negotiation, once the Quote is moved to Accepted stage, System will automatically create the Contract and link the same to Quote.
o	As the customer negotiation and Quote acceptance is mandatory, this verification should be enforced while Close Winning the Opportunity, without Quote acceptance Sales user should not be allowed to close with the Opportunity. 
•	Opportunity Closure Automation 
o	Automated Order and Asset creation when an Opportunity is closed-won
•	Validation Rules 
o	Opportunity Stage Sequence: Prevents skipping mandatory stages
o	Quote Acceptance Check: Prevents Close winning the Opportunity without Quote Acceptance.
o	Closed-Won Opportunity Stage Change: Locks the Opportunity status, to prevent the duplicate Order / Asset creation. 
•	Apex Triggers 
o	Automated Order and Asset creation on Opportunity closure
Dashboards and Reports
•	Sales Pipeline Dashboard: Tracks opportunities by stage
•	Closed Won vs. Closed Lost Opportunities: Performance breakdown
•	Regional Sales Performance: Sales by geographical regions
•	Reports: Tracks opportunity stages, quote approvals, contract generation, and revenue

Test Scenarios:
S.No	Test Case	Type	Expected Result
1	Leads could be converted into Account, Contact, opportunity by choice after Lead conversion 	Positive	Created Account, Contact, Opportunity
2	Sales Path validation. Must not skip the mandatory Sales path Stages(Engineering Review & Manufacturing Preparation)	Positive	Triggered Validation rules if we skip those Stages
3	Users should generate quotes by adding products and send for client acceptance before close win the opportunity	Positive	Triggered Validation rules if we try to Close win the Opportunity without Quote negotiation  
4	Automation with Flow for contract creation after Quote acceptance	Positive	Contracts created automatically
5	 Once Opportunity is Closed won, Orders and Assets should  be created automatically.(With Apex Triggers)	Positive	Created Orders and Assets
6	Opportunities should be locked once they are Closed Won (Validation rule)	Positive	Can’t change Opportunity once it is Closed Won to avoid Orders and Assets duplicate creation 

Service Cloud
The implementation focused on:
•	Configuring case management processes, including case categorization and SLA monitoring.
•	Automating case assignments and email-to-case functionality.
•	Designing entitlement processes to enforce SLA timeframes
•	Automated escalation process to trigger email alerts and re-assignment when the SLA timeframes breached. 
•	Setting up a custom profile for Service Managers with appropriate access to ensure they can manage cases, escalations, and dashboards effectively.

Data Model
•	Custom Objects and Fields 
o	Equipment Detail (Custom Object) 
	Equipment Model (Text)
	Support Type (Picklist) – To specify equipment specific SLA
•	Case Object (Standard Object) 
o	Urgency (Custom Field)
o	Update Case Type picklist to include: 
	Equipment Maintenance
	Support Request
Technical Specification Details
1.	Service Manager should able to perform below 
o	Case - create, edit, re-assign and escalate cases.
o	Read, edit, and delete permissions for the Equipment Detail Object.
o	Should be able to access all the Case owned by the team.
o	Full access to Service Dashboards.
o	Role Hierarchy based data sharing: Configured the Service Manager role under the Service Team Lead role. Team lead should be able to access all the cases owned by the team and should be able to re-assign to different teams.
2.	Case Management
o	Case Categorization: Case Type picklist used to categorize equipment and support cases
o	Email-to-Case Automation: Automated case creation from incoming emails.
o	If the incoming email is found in the system, automation process should update the Account, Contact and Account’s entitlement process on the case, so that required SLA triggers automatically.
o	Case Assignment: Configured assignment rules based on priority and urgency.
3.	SLA Management and Escalations
o	Entitlement Process: Entitlement Process with multiple milestones, First Response SLA, Resolution SLA & Escalated Case Resolution SLA.
o	Entitlement Rules: Validated SLA milestones against Asset and Account SLAs.
o	Escalation Workflow: Automated escalation workflows.
Dashboards and Reports
o	 Service Dashboard displays open Cases by Priority
o	Cases Nearing SLA deadlines
o	Escalated Cases for Service Manager Review
o	Reports for SLA compliance, milestone tracking, case resolution times, and escalation trends.
Test Scenarios
S.No	Test Case	Type	Expected Result
1	User should be able to Create the Case in UI	Positive	Case created 
2	When customer send an email to the support mail ID, case should be created	Positive	Case created
3	If the email is from known mail ID, System should automatically fetch and update Contact, Account and Entitlement process on the case	Positive	Case detail page with pre-filled details 
4	Milestones should be created on the case based on Account SLA field	Positive	Milestones with target time
5	When we add Asset and Asset specific Entitlement on the Case, if the asset has higher SLA package, respective Milestones should be created on the Case	Positive	Modified Milestone with higher SLA timeframe 
6	If the support team not responds to the case within the SLA, case should be escalated 	Positive	Case escalation email, Case reassignment and also Case status updates to Escalated. This will create new Milestone 
7	Escalation process should trigger the email alert and case should be re-assigned to escalation queue	Positive	System is automatically doing this

