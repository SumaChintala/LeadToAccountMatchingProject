public with sharing class FuzzyLevenshteinDistance {
    /**
     * Calculates the Levenshtein distance between two strings.
     * The Levenshtein distance is the minimum number of single-character edits (insertions, deletions, or substitutions)
     * required to transform one string into the other.
     */
    
    public static Integer levenshteinDistance(String s1, String s2) {
        
        s1 = S1 == null ? '' : s1;
        s2 = S2 == null ? '' : s2;
    
        Integer len1 = s1.length(); 
        Integer len2 = s2.length();

        if(len1 == 0 || len2 == 0){
            return 0;
        }
    
        // Use two arrays to save space
        List<Integer> prevRow = new List<Integer>();
        List<Integer> currRow = new List<Integer>();
        // Initialize the arrays
        for (Integer i = 0; i <= len2; i++) {
            prevRow.add(i);
        }
    
        for (Integer i = 1; i <= len1; i++) {
            currRow.clear();
            currRow.add(i);
            for (Integer j = 1; j <= len2; j++) {
                Integer cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                currRow.add(Math.min(
                    Math.min(currRow[j - 1] + 1, prevRow[j] + 1),
                    prevRow[j - 1] + cost
                ));
            }
            // Swap references
            prevRow.clear();
            prevRow.addAll(currRow);
        }
    
        return prevRow[len2];
    }

    // Method to calculate similarity percentage based on Levenshtein distance
    public static Double getSimilarityScore(String s1, String s2) {
        Integer maxLen = Math.max(s1.length(), s2.length());
        if (maxLen == 0) {
            return 1.0; // Both strings are empty
        }
        Integer levDistance = levenshteinDistance(s1, s2);
        return 1.0 - (Double.valueOf(levDistance) / Double.valueOf(maxLen));
    } 
}