trigger Commons_DependentTrigger on Dependent__c (after insert,after update) {

    Set<Id> unitId = new Set<Id>();
    if(!Commons_ConnectSFController.firstcall) {
        Commons_ConnectSFController.firstcall = true;
    for(Dependent__c dependent:Trigger.new){
        
        if(dependent.UnitStatus__c=='Appointee'||
           dependent.UnitStatus__c =='On-Field'||
           dependent.UnitStatus__c =='Home Assignment'||
           dependent.UnitStatus__c =='Medical Leave'||
           dependent.UnitStatus__c =='Study Leave'||
           dependent.UnitStatus__c =='Leave of Absence'||
           dependent.UnitStatus__c =='Sabbatical'||
           dependent.UnitStatus__c =='ST On-Field'||
           dependent.UnitStatus__c =='Concluded'){
            unitId.add(dependent.Unit__c);
        }
    }
}
    if(unitId.size()>0){
        Commons_ConnectSFController.syncDependent(unitId);
    }
}