trigger Commons_RelationshipTrigger on npe4__Relationship__c (after insert,before update) {

    set<id> relationId = new set<id>();

    if(!Commons_ConnectSFController.firstcall) {
        Commons_ConnectSFController.firstcall = true;

    for(npe4__Relationship__c relation :Trigger.new){
        if(relation.UnitStatus__c =='Appointee'||
           relation.UnitStatus__c =='On-Field'||
           relation.UnitStatus__c =='Home Assignment'||
           relation.UnitStatus__c =='Medical Leave'||
           relation.UnitStatus__c =='Study Leave'||
           relation.UnitStatus__c =='Leave of Absence'||
           relation.UnitStatus__c =='Sabbatical'||
           relation.UnitStatus__c =='ST On-Field'||
           relation.UnitStatus__c =='Concluded'){
          relationId.add(relation.Id);
           //system.debug('relation$$'+relationId);
           //System.debug('relationName'+relation.name);
         }
       }
   }
     if(relationId.size()>0){
         Commons_ConnectSFController.syncRelationShips(relationId);
       }
}