public class LeadTriggerHandler {
    public static final Double FUZZY_THRESHOLD =  Lead_To_Account_Match_Settings__c.getInstance().Fuzzy_Threshold__c;
    public static final Double REQUIRED_COMPANY_NAME_LENGTH =  Lead_To_Account_Match_Settings__c.getInstance().Minimum_Company_Name_Length__c;

    /**
     * Handles lead inserts before they are saved to the database.
     * This method performs exact matching, partial matching, and fuzzy matching to associate leads with accounts.
     */
    public static void handleBeforeInsert(List<Lead> newLeads) {
        // Collect company names and domain names from leads
        Set<String> companyNameSet = new Set<String>();
        Set<String> domainNameSet = new Set<String>();
        for (Lead l : newLeads) {      
            companyNameSet.add(l.Company);
            if (l.Email != null) {
                String emailDomain = l.Email.substringBetween('@', '.');
                if (emailDomain != null) {
                    domainNameSet.add(emailDomain);
                }
            }
        }
        Map<String, Account> companyNameAccountIdMap = new Map<String, Account>();
        Map<String, Account> domainNamesAccountIdMap = new Map<String, Account>();
        // Query Accounts based on collected company names and domain names
        try{
            for (Account acc : [SELECT Id, Name,Domain_Name__c, OwnerId, Industry FROM Account WHERE Name IN :companyNameSet OR Domain_Name__c IN :domainNameSet]) {
                companyNameAccountIdMap.put(acc.Name, acc);
                if (acc.Domain_Name__c != null) {
                    domainNamesAccountIdMap.put(acc.Domain_Name__c.toLowerCase(), acc); // Contact email saves data in lower case but account website allow upper case, to solve that issue lower case conversion is added
                    }
            }

        }catch(QueryException e){
            System.debug(e.getStackTraceString() + ' - ' + e.getMessage());
            //.debug('Error Message: ' + e.getMessage() + ' ' + 'Line: ' + e.getLineNumber()+'  Error Type: ' + e.getTypeName());
            // we need to throw the user friendly exception error message and logging through project specific implementation
        }
        
        
        List<Lead> leadsListForPartialAndFuzzyMatch = new List<Lead>();
        //List<Lead> leadsListForFuzzySearch = new List<Lead>();
        exactMatchAccountAndDomain(newLeads, companyNameAccountIdMap, domainNamesAccountIdMap, leadsListForPartialAndFuzzyMatch);
        // Handle partial matches and fuzzy matches
        if(leadsListForPartialAndFuzzyMatch.size()>0)
        getAccountsWithSOSL(leadsListForPartialAndFuzzyMatch);
            
    }
    /**
     * Performs exact matching of lead company name and domain name against existing accounts.
     * Updates lead information with the matched account details.
     */
    private static void exactMatchAccountAndDomain(List<Lead> leads, Map<String, Account> companyNameAccountIdMap, Map<String, Account> domainNamesAccountIdMap, List<Lead> leadsListForPartialAndFuzzyMatch) {
        for (Lead leadToUpdate : leads) {           
            String emailDomain =  leadToUpdate.Email?.substringBetween('@', '.');
            if (companyNameAccountIdMap.containsKey(leadToUpdate.Company)) {
                leadToUpdate.Account__c = companyNameAccountIdMap.get(leadToUpdate.Company).Id;
                Account matchedAccount = companyNameAccountIdMap.get(leadToUpdate.Company);
                updateLead(leadToUpdate, matchedAccount);
            } else if (emailDomain != null && domainNamesAccountIdMap.containsKey(emailDomain)) {
                Account matchedAccount = domainNamesAccountIdMap.get(emailDomain);
                updateLead(leadToUpdate, matchedAccount);
            } else if(leadToUpdate.company?.length() > REQUIRED_COMPANY_NAME_LENGTH){   // For fuzzy search if length of company name is greater than 4 chars,if Account is not found by exact match then Fuzzy & Partial match will be searched 
                leadsListForPartialAndFuzzyMatch.add(leadToUpdate);
            }
        }
    }

    /**
     * When some leads are still remaining after exact matching of lead company name and domain name against existing accounts,
     * we need to search for partial and fuzzy matching. retreiving all the account with SOQL is not an optimal way hence using SOSL.
     */
    private static void getAccountsWithSOSL(List<Lead> leadsListForPartialAndFuzzyMatch){
        // Construct the SOSL search string
        String searchString = '';
        Integer leadToBeMatchedCount = 0;
        for (Lead l : leadsListForPartialAndFuzzyMatch) {
            searchString += l.Company + ' OR ';
            leadToBeMatchedCount++;
        }
        searchString = searchString.removeEnd(' OR ');

        // Perform the SOSL search
        List<List<SObject>> accountSearchResult;
        try{
            accountSearchResult = [FIND :searchString IN NAME FIELDS RETURNING Account(Id, Name, OwnerId, Industry)]; 
        }catch(QueryException e){
            System.debug(e.getStackTraceString() + ' - ' + e.getMessage());
            // we need to throw the user friendly exception error message and also error logging through project specific framework
        }
        
        // If the Account object contains lot of companies with similar names then the single search term might return so many rows, SOSL return max 250 rows
        // To make this search foolproof we could consider searching only one account at a time, then we don't need further logic of FUZZY search
        //System.debug('accountSearchResult :'+accountSearchResult);
        if (accountSearchResult!= null && !accountSearchResult[0].isEmpty()) {
            List<Account> accountResultList = (List<Account>)accountSearchResult[0];
            Double similarityScore;
            for(Lead leadForMatch : leadsListForPartialAndFuzzyMatch){
                if(leadForMatch.company != null){
                    if(leadToBeMatchedCount == 1 ){
                        for(Account accForMatch : accountResultList){ // Walmart Inc  - walmart  || walmart - Walmart Inc
                            updateLead(leadForMatch, accForMatch);
                                break;  // in case of single lead for fuzzy, relaying on SOSL result to bulkify the logic for multiple leads
                        }
                    }else{
                        for(Account accForMatch : accountResultList){ // Walmart Inc  - walmart  || walmart - Walmart Inc
                            if((leadForMatch.company?.containsIgnoreCase(accForMatch.Name)) || (accForMatch.Name?.containsIgnoreCase(leadForMatch.company))  ){
                                updateLead(leadForMatch, accForMatch);
                                break;  
                            } // On first match of partial match loop will break.
                        }
                        //System.debug('Inside loop leadForMatch.Account__c '+leadForMatch.Account__c);
                        if(leadForMatch.Account__c == null){ //2nd for loop is to initiate the fuzzy match when partial match is not found 
                            for(Account accForFuzzyMatch : accountResultList){
                                //System.debug('FUZZY Match for :'+accForFuzzyMatch.Name+'  and : '+leadForMatch.company);
                                similarityScore = FuzzyLevenshteinDistance.getSimilarityScore(accForFuzzyMatch.Name.replaceAll('[^a-zA-Z0-9]', '') , leadForMatch.company.replaceAll('[^a-zA-Z0-9]', ''));
                                //removing the special chars to make the search effective 
                                if(similarityScore > FUZZY_THRESHOLD){ 
                                    updateLead(leadForMatch, accForFuzzyMatch);
                                    break;  
                                } // On the first match loop will break
                            }
                        }

                    }
                    
                }
                
            }
        }
    }
    private static void updateLead(Lead leadToUpdate, Account matchedAccount) {
        leadToUpdate.Account__c = matchedAccount.Id;
        leadToUpdate.OwnerId = matchedAccount.OwnerId;
        leadToUpdate.Industry = matchedAccount.Industry;
    }
}