/**
* @name: OpportunityTrigger
* @Description: This trigger is designed to respond to after insert and update on
* the Opportunity object. Calls specific methods in the OpportunityTriggerHandler class
* after an opportunity is inserted or updated
*/
trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
                OpportunityTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);         
    }
}