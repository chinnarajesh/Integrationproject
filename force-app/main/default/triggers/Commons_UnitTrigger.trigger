trigger Commons_UnitTrigger on Unit__c (after update) {
    
    Set<Id> unitId = new Set<Id>();
    if(!Commons_ConnectSFController.firstcall) {
        Commons_ConnectSFController.firstcall = true;
    
    for(Unit__c unit :Trigger.new){
        if(unit.Status__c=='Appointee' ||
           unit.Status__c =='On-Field'||
           unit.Status__c =='Home Assignment'||
           unit.Status__c =='Medical Leave'||
           unit.Status__c =='Study Leave'||
           unit.Status__c =='Leave of Absence'||
           unit.Status__c =='Sabbatical'||
           unit.Status__c =='ST On-Field'||
           unit.Status__c =='Concluded'){
            unitId.add(unit.id);
         }
    }
}
    if(unitId.size()>0){
        Commons_ConnectSFController.syncUnits(unitId);
    }
}