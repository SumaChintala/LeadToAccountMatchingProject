**Lead-to-Account Matching Solution**
**Overview**
This Salesforce project implements a Lead-to-Account matching solution that automatically associates incoming Leads with existing Accounts based on predefined criteria. The project includes custom Apex triggers, custom fields, custom settings, matching and duplicate rules, and a reporting mechanism to track the efficiency of the matching process.

**Features**

**•	Data Modeling:**
o	Customized Salesforce data model to support direct relationships between Leads and Account

**o	Custom Fields**
Account.Domain_Name__c: A formula field that extracts the domain from the Account’s website. Used for matching Leads based on email domains.
Lead.Account__c: A lookup field to link the Lead with an Account. This is a writable custom field, unlike the standard AccountId field.
Lead.Account_Matched__c: A boolean formula field indicating whether a Lead has been matched to an Account. Used for reporting purposes.
o	Key fields used for matching:
	Lead.Company: Matches against Account.Name.
	Lead.Email: Domain part of the email is matched against Account.Domain_Name__c.


**•	Lead-to-Account Matching Logic:**
o	Exact Matching:
	Lead’s company name is exactly matched against Account’s name.
	Lead’s email domain is matched against Account’s domain name, Lead email fields saves data only in lowercase but Account website also accepts the uppercase, hence converted the website domain to lowercase while storing the accounts in Map.

o	Fuzzy and Partial Matching:

	Implements fuzzy logic to match Leads with Accounts based on similar company names.

	We need to consider various Salesforce limits here to build the logic, for example to query all the accounts for fuzzy match SOQL 5000 query rows limit, if we are trying to fuzzy match accounts with 10000+ records we might hit CPU time limit 

	To avoid the limits I thought of building the logic otherway around, instead of querying all the accounts, first generating the fuzzy word combinations for Company names and querieng accounts with SOQL but in this approach also we might face scalability issues, when we try to insert 100 Leads with long company names there will be too many fuzzy words combinations to be queried.

	For partial matching we need additional SOQL query with like operator but building the like operator with many search keys over a Account object with lot of data might fail with SOQL timeout error. 

	Considering the above limitation and after receiving the confirmation for my question I have used SOSL to build the logic. When the fuzzy logic is executed for only one Lead the matching will happen directly based on SOSL result, which is covered both Fuzzy and partial match, for multiple Leads I have bulkified the code using custom fuzzy match logic. This bulkified code on SOSL might not work properly if the Account object data is not in good shape, like so many duplicate accounts etc


o	Account Assignment:
	If a match is found, the Lead is linked to the Account, and key fields on the Lead (Owner, Industry) are updated with data from the matched Account.

o	No Match Handling:
	If no match is found, the Lead proceeds without modification.

**•	User Interface Enhancements:**
o	Matched Leads are visible under the related Account records.
•	Testing:
o	Tried to cover many different test cases like blank email, bulk fuzzy match, different type of email domains and website combinations etc. 
•	Reporting and Analytics:
o	A custom report tracks the percentage of Leads automatically matched to Accounts, providing insights into the matching process.

**Custom Metadata and Configuration
Custom Settings**
•	Lead_To_Account_Match_Settings__c: Custom settings to configure the behavior of the matching logic, including:

o	Fuzzy_Threshold__c: The threshold for fuzzy matching, 1 is for perfect match, 0.7 is a default value for fuzzy match.

o	Minimum_Company_Name_Length__c: The minimum length of the company name required for fuzzy matching. Insert a lead having company name only one or two chars would give many search results, and may not be appropriate. Hence minimum 4 chars length condition is placed in the code.

o	On the need basis the above two settings can be adjusted, for example if we want to impose strict conditions for some specific users or profiles we can create the user/profile specific row with different values in custom settings

**Matching and Duplicate Rules**
To avoid creating duplicate rules we have different options like Trigger on lead, UI customization on Lead conversion screen but I tried to achieve it with configuration through Account duplicate and matching rules, this approach also giving suggestions in the leadscreen and stopping the flow if the result is duplicate account creation. 

•	Matching Rule: Ensures that new Leads are matched with existing Accounts using exact and fuzzy matching logic.
•	Duplicate Rule: Prevents the creation of duplicate Accounts during Lead conversion.

**Installation and Deployment**
Prerequisites
•	Salesforce Developer Org with necessary permissions.
•	Workbench, ANT Migration tool, VSCode or similar tool for deployment.
Deployment Steps
1.	Clone the Repository:
[https://github.com/your-repo/lead-to-account-matching.git](https://github.com/SumaChintala/LeadToAccountMatchingProject/tree/main)
2.	Deploy Metadata:
o	Use a deployment tool to deploy the metadata to your Salesforce org.
3.	Configure Custom Settings:
o	Navigate to Setup>Custom Settings>Lead To Account Match Settings.
o	Set the Fuzzy_Threshold__c and Minimum_Company_Name_Length__c according to your matching needs. Custom settings can be created with default value suggestions which are 0.7 and 3
4.	Test the Functionality:
o	Ensure that the test classes pass by running all tests in your Salesforce org.
5.	Review Matching and Duplicate Rules:
o	Verify that the Matching and Duplicate Rules are correctly configured under Setup>Duplicate Management.
**Testing Instructions**
1.	Create Test Data:
o	Create Leads with varying company names and email addresses.
o	Ensure some Leads have exact matches, some partial/fuzzy matches, and some with no matches.
o	Sample CSV files are added for Accounts and Leads test data
2.	Verify Matching:
o	After inserting Leads, check the Account__c and Account_Matched__c fields to confirm the Lead was correctly matched.
o	Review the custom report to see the percentage of matched vs. unmatched Leads.
Reporting
•	Custom Report:
o	A custom report has been created to track the percentage of Leads matched to Accounts. This report can be accessed under the Reports tab.

