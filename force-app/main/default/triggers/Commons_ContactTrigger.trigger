trigger Commons_ContactTrigger on Contact (after insert,after update) {
  
     set<id> unitId = new set<id>();
     
     if(!Commons_ConnectSFController.firstcall) {
        Commons_ConnectSFController.firstcall = true;
       
    for(Contact conObj: Trigger.new){
        if(conObj.UnitStatus__c =='Appointee'||
           conObj.UnitStatus__c =='On-Field'||
           conObj.UnitStatus__c =='Home Assignment'||
           conObj.UnitStatus__c =='Medical Leave'||
           conObj.UnitStatus__c =='Study Leave'||
           conObj.UnitStatus__c =='Leave of Absence'||
           conObj.UnitStatus__c =='Sabbatical'||
           conObj.UnitStatus__c =='ST On-Field'||
           conObj.UnitStatus__c =='Concluded'){
            unitId.add(conObj.Unit__c);
         }
       }
     }
         if(unitId.size()>0){
            Commons_ConnectSFController.syncContacts(unitId);
          }
}