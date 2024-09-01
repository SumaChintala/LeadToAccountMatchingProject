trigger LeadTriggerForAccountMatch on Lead (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LeadTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}