@isTest
public class LeadTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Accounts to test matching
        List<Account> accountList = new List<Account>();
        accountList.add(new Account(Name = 'ExactMatch Inc', website = 'http://exactmatch.com', Industry = 'Technology'));
        accountList.add(new Account(Name = 'DomainMatch Inc', website = 'http://www.domainmatch.com', Industry = 'Technology'));
        accountList.add(new Account(Name = 'DomainMultiDotsMatch Inc', website = 'www.DomainMultiDotsMatch.co.in', Industry = 'Technology'));
        accountList.add(new Account(Name = 'DomainWithoutPrefix Inc', website = 'DomainWithoutPrefix.com', Industry = 'Technology'));
        accountList.add(new Account(Name = 'PartialMatch LLC', website = 'partialmatch.com', Industry = 'Finance'));
        accountList.add(new Account(Name = 'FuzzyMatchInc', website = 'fuzzymatch.org', Industry = 'Healthcare'));
        insert accountList;

        Lead_To_Account_Match_Settings__c leadToAccountMatchSettings = new Lead_To_Account_Match_Settings__c(Fuzzy_Threshold__c = 0.7, Minimum_Company_Name_Length__c = 3);
        insert leadToAccountMatchSettings;
        
        
    }

    @isTest
    static void testExactMatchCompany() {
        Lead lead = new Lead(Company = 'ExactMatch Inc', Email = 'test@exactmatch.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'ExactMatch Inc');
    }

    @isTest
    static void testExactMatchDomain() {
        Lead lead = new Lead(Company = 'www Domain corp Match', Email = 'test@domainmatch.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'DomainMatch Inc');
    }

    @isTest
    static void testExactMatchDomainWithMultiDots() {
        Lead lead = new Lead(Company = 'xxx DomainMultiDotsMatch corp', Email = 'test@domainmultidotsmatch.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'DomainMultiDotsMatch Inc');
    }

    @isTest
    static void testExactMatchDomainWithoutPrefix() {
        Lead lead = new Lead(Company = 'Domain xxx inx test', Email = 'test@domainwithoutprefix.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'DomainWithoutPrefix Inc');
    }

    @isTest
    static void testPartialMatch() {
        List<Id> acctIdsList = new List<Id>();
        for(Account acc: [select id from account where name = 'PartialMatch LLC']){
            acctIdsList.add(acc.Id);
        }
        Test.setFixedSearchResults(acctIdsList);
        Lead lead = new Lead(Company = 'PartialMatch', Email = 'test@test.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'PartialMatch LLC');
    }

    @isTest
    static void testFuzzyMatch() {
        List<Id> acctIdsList = new List<Id>();
        for(Account acc: [select id from account where name = 'FuzzyMatchInc']){
            acctIdsList.add(acc.Id);
        }
        Test.setFixedSearchResults(acctIdsList);
        Lead lead = new Lead(Company = 'FuuzzyMatchInc', Email = 'test@test.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;
        validateLeadWithAccount(lead.Id, 'FuzzyMatchInc');
    }

    @isTest
    static void testNoMatch() {
        Lead lead = new Lead(Company = 'You cannot catch Me', Email = 'test@test.com', LastName = 'Test', Status = 'Open - Not Contacted');
        insert lead;

        Lead insertedLead = [SELECT Id, Account__c, Industry FROM Lead WHERE Id = :lead.Id LIMIT 1];
        System.assertEquals(null, insertedLead.Account__c, 'The Account ID should be null for a no-match scenario.');
        System.assertEquals(null, insertedLead.Industry, 'The Industry should be null for a no-match scenario.');
    }

    @isTest
    static void testFuzzyMatchWithMultipleLeads() {
        // Insert 20 leads with fuzzy variations of "FuzzyMatch"
        List<Id> acctIdsList = new List<Id>();
        for(Account acc: [select id from account]){
            acctIdsList.add(acc.Id);
        }
        Test.setFixedSearchResults(acctIdsList);
        insertFuzzyLeads();
        

        // Query and validate each lead to check if it was matched to "FuzzyMatch"
        List<Lead> leads = [SELECT Id, Company, Account__c FROM Lead WHERE Company LIKE 'Fuzzy%' OR Company LIKE 'Fizzi%' LIMIT 20];
        Account matchedAccount = [SELECT Id, Name, OwnerId, Industry FROM Account WHERE Name = 'FuzzyMatchInc' LIMIT 1];
        for (Lead lead : leads) {
            System.assertEquals(matchedAccount.Id, lead.Account__c, 'The Account ID should match the expected account for the lead with company :'+ lead.company);
        }
    }

    // Helper method to validate lead with the expected account name
    private static void validateLeadWithAccount(Id leadId, String expectedAccountName) {
        Lead insertedLead = [SELECT Id,Company, Account__c, OwnerId, Industry FROM Lead WHERE Id = :leadId LIMIT 1];
        Account matchedAccount = [SELECT Id, Name, OwnerId, Industry FROM Account WHERE Name = :expectedAccountName LIMIT 1];

        System.assertEquals(matchedAccount.Id, insertedLead.Account__c, 'The Account ID should match the expected account.'+insertedLead.Company);
        System.assertEquals(matchedAccount.OwnerId, insertedLead.OwnerId, 'The Owner ID should match the account owner.');
        System.assertEquals(matchedAccount.Industry, insertedLead.Industry, 'The Industry should match the account industry.');
    }

    // Helper method to insert 20 leads with fuzzy variations of "FuzzyMatch"
    private static void insertFuzzyLeads() {
        List<Lead> fuzzyLeads = new List<Lead>{
            new Lead(Company = 'Fuzhzy Match Inc', Email = 'test1@test.com', LastName = 'Test1', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy Match-Inx', Email = 'test2@test.com', LastName = 'Test2', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzszyMatch Inc', Email = 'test3@test.com', LastName = 'Test3', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzxzyMatchInx', Email = 'test4@test.com', LastName = 'Test4', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzyMatcth Inc', Email = 'test5@test.com', LastName = 'Test5', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy MqtchInc', Email = 'test6@test.com', LastName = 'Test6', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzyMatch Inu', Email = 'test7@test.com', LastName = 'Test7', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy MatchInj', Email = 'test8@test.com', LastName = 'Test8', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy Match Inb', Email = 'test9@test.com', LastName = 'Test9', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzyMatch Ioc', Email = 'test10@test.com', LastName = 'Test10', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy-MaktchInc', Email = 'test11@test.com', LastName = 'Test11', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy, MmtchInc', Email = 'test12@test.com', LastName = 'Test12', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzy Madch Inc', Email = 'test13@test.com', LastName = 'Test13', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuztzy MatchInc', Email = 'test14@test.com', LastName = 'Test14', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzoyMatch Inc', Email = 'test15@test.com', LastName = 'Test15', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzyMatcyhInc', Email = 'test16@test.com', LastName = 'Test16', Status = 'Open - Not Contacted'),
            new Lead(Company = 'tFuzzy MatchInc', Email = 'test17@test.com', LastName = 'Test17', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzgyMatch Inc', Email = 'test18@test.com', LastName = 'Test18', Status = 'Open - Not Contacted'),
            new Lead(Company = 'Fuzzyz Match Inc', Email = 'test19@test.com', LastName = 'Test19', Status = 'Open - Not Contacted'),
            new Lead(Company = 'FuzzyMaktchInc', Email = 'test20@test.com', LastName = 'Test20', Status = 'Open - Not Contacted')
        };
        insert fuzzyLeads;
    }
}