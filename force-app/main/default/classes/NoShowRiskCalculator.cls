public class NoShowRiskCalculator {

    @InvocableMethod(label='Calculate No-Show Risk' description='Calculates risk level based on patient history')
    public static void calculateRisk(List<Id> accountIds) {
        // Fetch total no-shows (assuming you have a field for this from Feature 5)
        List<Account> patients = [SELECT Id, Total_No_Shows__c FROM Account WHERE Id IN :accountIds];
        
        for (Account p : patients) {
            if (p.Total_No_Shows__c == null || p.Total_No_Shows__c == 0) {
                p.No_Show_Risk__c = 'Low';
                p.No_Show_Prob__c = 5;
            } else if (p.Total_No_Shows__c < 2) {
                p.No_Show_Risk__c = 'Medium';
                p.No_Show_Prob__c = 35;
            } else {
                p.No_Show_Risk__c = 'High';
                p.No_Show_Prob__c = 75;
            }
        }
        update patients;
    }
}