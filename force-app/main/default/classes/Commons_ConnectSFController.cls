public class Commons_ConnectSFController {
    
         public static Boolean firstcall = false;
    
       public class authWrapper
    {
        public String id;
        public String access_token;
    }
   
    public static String getRequestToken(){
        
      SalesforceCredentials__c logincreds=[select clientId__c,clientSecret__c,password__c,username__c,Salesforce_URL__c from SalesforceCredentials__c ];

        String reqbody = 'grant_type=password'+'&client_id='+logincreds.clientId__c+'&client_secret='+logincreds.clientSecret__c+'&username='+logincreds.username__c+'&password='+logincreds.password__c;
        
        String endpoint=logincreds.Salesforce_URL__c+'/services/oauth2/token';
        
        Http h1 = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        req.setEndpoint(endpoint);
        HttpResponse res = h1.send(req);
        if(res.getStatusCode()==200 || res.getStatusCode()==201){
            authWrapper response = (authWrapper)JSON.deserialize(res.getBody(),authWrapper.class); 
             System.debug('response--->>>'+response);
             System.debug('accesstoken'+response.access_token);
             return response.access_token; 
        }
        System.debug('response--->>>'+res.getBody());
        return null;   
    }
      @future(callout=true)
    public static void syncUnits(Set<id> unitId){
        system.debug('syncUnits');
         String accessToken=Commons_ConnectSFController.getRequestToken();
         List<Commons_ContactWrapper> WrapperList = new List<Commons_ContactWrapper>();
       SalesforceCredentials__c logincreds=[select Salesforce_URL__c from SalesforceCredentials__c ];

        if(accessToken != null) {
           
            String endPoint=logincreds.Salesforce_URL__c+'/services/apexrest/v1/createContact/';
            
            Map<id,Lifecycle__c> lifecycleMap = new Map<id,Lifecycle__c>();
            for(Lifecycle__c lifecycle:[select id,name,Term_Start_Date__c,Lifecycle_Country__c,Unit__c from Lifecycle__c where Unit__c IN:unitId and Term_Start_Date__c != null ]){
                lifecycleMap.put(lifecycle.Unit__c,lifecycle);
            }
           System.debug('lifecycleMap@@'+lifecycleMap); 
                Set<id> contactIdSet = new Set<id>();
            For(Contact contact:[SELECT Id,LegalName__c,firstname,lastname,Preferred_Language_English__c,Citizenship_Country__c,NonEnglish_Preferred_languages__c,Fax,Gender__c,Birth_Year__c,Latest_Child_Safety_Training__c,npe01__Preferred_Email__c,In_Person_Security__c,Skype__c,npe01__AlternateEmail__c,Expat_Digital__c,Child_Safety__c,OST_Status__c,Unit__c,Citizenship__c,Unit__r.Status__c,Unit__r.Wedding_Date__c,Unit__r.name,npe01__WorkEmail__c,npe01__HomeEmail__c,Unit__r.Appointee_Date__c,Unit__r.Initial_Departure__c,npe01__PreferredPhone__c,Field_Phone__c,Unit__r.Preferred_Contact__c,MailingAddress,Birthdate,MobilePhone,npe01__WorkPhone__c,HomePhone,OtherPhone,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,Unit__r.id FROM Contact where Unit__c IN:unitId]){
                  contactIdSet.add(contact.id);
                Commons_ContactWrapper Wrapper = new Commons_ContactWrapper();
                Wrapper.contactId=contact.Id;
                Wrapper.unitname=contact.Unit__r.name;
                Wrapper.unitid=contact.Unit__c;
                Wrapper.recordType='Standard';
                Wrapper.firstName=contact.FirstName;
                Wrapper.Lastname=contact.LastName;
                Wrapper.PreferredName=contact.FirstName;
                Wrapper.Gender=contact.Gender__c;
                wrapper.BirthYear=contact.Birth_Year__c; 
              
                if(!string.isBlank(contact.Skype__c)){
                wrapper.SkypeID=contact.Skype__c;
                    }
                else if(!string.isBlank(contact.Fax)){
                    wrapper.OtherMessaging=contact.Fax;
                }
                if(contact.Citizenship__c =='Australian'){
                    wrapper.Citizenship='Australia';
                }
                else if(contact.Citizenship__c =='Dual'){
                    list<String> countryList=new list<String>();
                    wrapper.Citizenship='Australia';
                    countryList =contact.Citizenship_Country__c.split(';');
                      for(integer i=0;i<countryList.size();i++) {
                       
                            if(countryList[i]=='Australia'){
                                countryList.remove(i);
                            }
                       }
                    wrapper.OtherCitizenship1=countryList.size()>0?countryList.get(0):null;
                    wrapper.OtherCitizenship2=countryList.size()>1?countryList.get(1):null;
                   }
                else if(contact.Citizenship__c =='Other'){
                    list<String> countryListtwo=new list<String>();
                    countryListtwo =contact.Citizenship_Country__c.split(';');
                        wrapper.OtherCitizenship1=countryListtwo.size()>0?countryListtwo.get(0):null;
                        wrapper.OtherCitizenship2=countryListtwo.size()>1?countryListtwo.get(1):null;      
                    }
                
                /*if(contact.Preferred_Language_English__c ==true){
                    wrapper.PreferredLanguage='English';
                }
                else if(contact.Preferred_Language_English__c ==false){
                    wrapper.PreferredLanguage=contact.NonEnglish_Preferred_languages__c;
                   
                }*/
                if(lifecycleMap.containskey(contact.Unit__c)){
                    Wrapper.CurrentRoleAppointmentDate=lifecycleMap.get(contact.Unit__c).Term_Start_Date__c;
                    Wrapper.CurrentCountryiftraveling=lifecycleMap.get(contact.Unit__c).Lifecycle_Country__c;
                }
                if(contact.Unit__r.Wedding_Date__c!=null){
                    Wrapper.MaritalStatus='Married';
                    Wrapper.DateofMarriage=contact.Unit__r.Wedding_Date__c;
                }
                else if(contact.Unit__r.Wedding_Date__c==null){
                    Wrapper.MaritalStatus='Single';
                }
                if(contact.Unit__r.Status__c=='On-Field'|| contact.Unit__r.Status__c=='Home Assignment' || contact.Unit__r.Status__c=='Medical Leave' || contact.Unit__r.Status__c=='Sabbatical' || contact.Unit__r.Status__c=='Study Leave' || contact.Unit__r.Status__c=='Leave of Absence'){
                    Wrapper.PrimaryRole='Team Member';
                }
                else if(contact.Unit__r.Status__c=='Appointee'){
                   Wrapper.PrimaryRole='Appointee';
                }
                else if(contact.Unit__r.Status__c=='Concluded'){
                    Wrapper.PrimaryRole='Alumni';
                }
                else if(contact.Unit__r.Status__c=='ST On-Field'){
                    Wrapper.PrimaryRole='Short-Termer';
                }
                if(contact.npe01__Preferred_Email__c=='Personal'){
                    Wrapper.preferWorkEmail=contact.npe01__HomeEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c=='Work'){
                    Wrapper.preferWorkEmail=contact.npe01__WorkEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__HomeEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c=='Alternate'){
                    Wrapper.preferWorkEmail=contact.npe01__AlternateEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__HomeEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c==null){
                    Wrapper.preferWorkEmail=contact.npe01__HomeEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }                
                if(contact.Expat_Digital__c=='Completed'){
                    Wrapper.DigitalSecurityTraining=System.today();
                }
                if(contact.Child_Safety__c=='Completed'){
                    Wrapper.CSTInitialTraining=System.today();
                    Wrapper.CSTCompleted=System.today();
                }
                //Wrapper.CSTCompleted=contact.Latest_Child_Safety_Training__c;
                If(contact.OST_Status__c=='Completed'){
                    Wrapper.OSTCompleted=System.today();
                }
                If(contact.In_Person_Security__c=='Completed'){
                    Wrapper.FSTCompleted=System.today();
                }
                                
                    Wrapper.MailingStreet=contact.MailingStreet;
                    Wrapper.MailingCity=contact.MailingCity;
                    Wrapper.MailingState=contact.MailingState;
                    Wrapper.MailingCountry=contact.MailingCountry;
                    Wrapper.MailingPostalCode=contact.MailingPostalCode;
                
                    Wrapper.OtherStreet=contact.OtherStreet;
                    Wrapper.OtherCity=contact.OtherCity;   
                    Wrapper.OtherState=contact.OtherState;
                    Wrapper.OtherCountry=contact.OtherCountry;
                    Wrapper.OtherPostalCode=contact.OtherPostalCode;
                   
                wrapper.MembershipStartDate=contact.Unit__r.Appointee_Date__c;
                Wrapper.OriginalFieldDepartureDate=contact.Unit__r.Initial_Departure__c;
                
                if(contact.npe01__PreferredPhone__c=='Mobile'){
                    Wrapper.HomeCountryPhoneNumber=contact.MobilePhone;
                }
                else if(contact.npe01__PreferredPhone__c=='Work'){
                    Wrapper.HomeCountryPhoneNumber=contact.npe01__WorkPhone__c;
                }
                else if(contact.npe01__PreferredPhone__c=='Home'){
                    Wrapper.HomeCountryPhoneNumber=contact.HomePhone;
                }
                else if(contact.npe01__PreferredPhone__c=='Other'){
                    Wrapper.HomeCountryPhoneNumber=contact.OtherPhone;
                }
                Wrapper.PrimaryFieldPhoneNumber=contact.Field_Phone__c;
                // List<string> preferedContact = new List<string>();
                // preferedContact=contact.Unit__r.Preferred_Contact__c.split(';');
                // System.debug('MultiSelect##'+preferedContact.get(0));

                if(contact.Unit__r.Preferred_Contact__c=='FB Messenger'){
                    Wrapper.PreferredCommunication='FB Messenger';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='WhatsApp'){
                      Wrapper.PreferredCommunication='WhatsApp';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='Email'){
                      Wrapper.PreferredCommunication='Email';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='Text'){
                      Wrapper.PreferredCommunication='Text';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Phone'){
                      Wrapper.PreferredCommunication='Phone';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Skype/Zoom'){
                      Wrapper.PreferredCommunication='Skype/Zoom';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Signal'){
                      Wrapper.PreferredCommunication='Signal';
                } 
                Wrapper.Birthdate=contact.Birthdate;
                
                WrapperList.add(Wrapper);
                System.debug('WrapperList######'+WrapperList);
            }
            
            for(Dependent__c dependent:[select id,name,Birthdate__c,First_Name__c,Mobile__c,Citizenship__c,Last_Name__c,Gender__c,Email__c,Unit__r.Preferred_Contact__c,Unit__c,Unit__r.Wedding_Date__c,Unit__r.name,Education__c,On_Field__c,Unit__r.Status__c,unit__r.Appointee_Date__c,Unit__r.Initial_Departure__c,Unit__r.id from Dependent__c Where Unit__c IN:unitId]){
                Commons_ContactWrapper Wrapperdepp = new Commons_ContactWrapper();
                Wrapperdepp.contactId=dependent.Id;
                Wrapperdepp.unitname=dependent.Unit__r.name;
                Wrapperdepp.unitid=dependent.Unit__c;
                Wrapperdepp.recordType='Dependant';
                Wrapperdepp.firstName=dependent.First_Name__c;
                Wrapperdepp.Lastname=dependent.Last_Name__c;
                Wrapperdepp.Gender=dependent.Gender__c;
                 Wrapperdepp.Phone=dependent.Mobile__c;
                 if(dependent.Unit__r.Wedding_Date__c!=null){
                    Wrapperdepp.MaritalStatus='Married';
                    Wrapperdepp.DateofMarriage=dependent.Unit__r.Wedding_Date__c;
                }
                else if(dependent.Unit__r.Wedding_Date__c==null){
                    Wrapperdepp.MaritalStatus='Single';
                }
               Wrapperdepp.preferWorkEmail=dependent.Email__c;
               
                if(dependent.Unit__r.Status__c=='On-Field' || dependent.Unit__r.Status__c=='Home Assignment' || dependent.Unit__r.Status__c=='Medical Leave' || dependent.Unit__r.Status__c=='Sabbatical' || dependent.Unit__r.Status__c=='Study Leave' || dependent.Unit__r.Status__c=='Leave of Absence'){
                    Wrapperdepp.PrimaryRole='Team Member';
                }
                else if(dependent.Unit__r.Status__c=='Appointee'){
                   Wrapperdepp.PrimaryRole='Appointee';
                }
                else if(dependent.Unit__r.Status__c=='Concluded'){
                    Wrapperdepp.PrimaryRole='Alumni';
                }
                else if(dependent.Unit__r.Status__c=='ST On-Field'){
                    Wrapperdepp.PrimaryRole='Short-Termer';
                }
                if(dependent.Citizenship__c =='Australian'){
                    Wrapperdepp.Citizenship='Australia';
                 }
                 else if(dependent.Citizenship__c =='Dual'){
                    Wrapperdepp.Citizenship='Australia';
                 }
                Wrapperdepp.MembershipStartDate=dependent.Unit__r.Appointee_Date__c;
                Wrapperdepp.OriginalFieldDepartureDate=dependent.Unit__r.Initial_Departure__c;
                
                Wrapperdepp.Birthdate=dependent.Birthdate__c;
                
                 if(lifecycleMap.containskey(dependent.Unit__c)){
                    Wrapperdepp.CurrentRoleAppointmentDate=lifecycleMap.get(dependent.Unit__c).Term_Start_Date__c;
                    Wrapperdepp.CurrentCountryiftraveling=lifecycleMap.get(dependent.Unit__c).Lifecycle_Country__c;
                  }
                
                 if(dependent.Unit__r.Preferred_Contact__c=='FB Messenger'){
                  Wrapperdepp.PreferredCommunication='FB Messenger';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='WhatsApp'){
                      Wrapperdepp.PreferredCommunication='WhatsApp';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='Email'){
                      Wrapperdepp.PreferredCommunication='Email';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='Text'){
                      Wrapperdepp.PreferredCommunication='Text';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Phone'){
                      Wrapperdepp.PreferredCommunication='Phone';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Skype/Zoom'){
                      Wrapperdepp.PreferredCommunication='Skype/Zoom';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Signal'){
                      Wrapperdepp.PreferredCommunication='Signal';
                }
                if(dependent.Education__c=='Home School'){
                Wrapperdepp.dEducation='Home School';
                }
                else if(dependent.Education__c=='Boarding School'){
                    Wrapperdepp.dEducation='Boarding School';
                }
                else if(dependent.Education__c=='Local School'){
                    Wrapperdepp.dEducation='Local School';
                }
                else if(dependent.Education__c=='Not old enough'){
                    Wrapperdepp.dEducation='Not old enough';
                }
                
                WrapperList.add(Wrapperdepp);
            }
                Set<string> newrelationSet = new Set<string>();
                System.debug('contactIdset'+contactIdSet);
        for(npe4__Relationship__c relation :[select id,name,npe4__Contact__c,npe4__RelatedContact__c,npe4__Status__c,npe4__Type__c from npe4__Relationship__c where npe4__Contact__c IN:contactIdSet ]){
               Commons_ContactWrapper Wrapper = new Commons_ContactWrapper();
               if(!newrelationSet.contains(relation.npe4__RelatedContact__c)){
                
                 wrapper.RelationshipId=relation.id;
                 Wrapper.RelationshipContact=relation.npe4__RelatedContact__c;
                 wrapper.RelatedContact=relation.npe4__Contact__c;
                 wrapper.relationType=relation.npe4__Type__c;
                 newrelationSet.add(relation.npe4__Contact__c);
                 System.debug('Type++'+wrapper.relationType);
                 Wrapper.Status=relation.npe4__Status__c;
      
                 System.debug('Name##'+relation.Name);
                 System.debug('RelationshipContact$$'+Wrapper.RelationshipContact);
               }
                 WrapperList.add(Wrapper);
              }
            
              String str=JSON.serialize(WrapperList); 
            System.debug('***JSON STRING'+str); 
            
             Http h2 = new Http();
                    HttpRequest req1 = new HttpRequest();
                    req1.setHeader('Authorization','Bearer ' + accessToken);
                    req1.setHeader('Content-Type','application/json');
                    req1.setHeader('accept','application/json');
                    req1.setMethod('POST');
                    req1.setBody(str);
                    System.debug('body--->>'+str);
                    req1.setEndpoint(endPoint);
                    HttpResponse res1 = h2.send(req1);
                System.debug('Response--->>'+res1.getstatusCode());
                System.debug('Response--->>'+res1.getBody());
        }  
    }
        
    @future(callout=true)
    public static void syncContacts(Set<id> unitId){
        system.debug('syncContacts');
        System.debug('unitId##'+unitId);
        String accessToken=Commons_ConnectSFController.getRequestToken();
         List<Commons_ContactWrapper> conList = new List<Commons_ContactWrapper>();
       SalesforceCredentials__c logincreds=[select Salesforce_URL__c from SalesforceCredentials__c ];

        if(accessToken != null) {
           
            String endPoint=logincreds.Salesforce_URL__c+'/services/apexrest/v1/createContact/';
            
            Map<id,Lifecycle__c> lifecycleMap = new Map<id,Lifecycle__c>();
            for(Lifecycle__c lifecycle:[select id,name,Term_Start_Date__c,Lifecycle_Country__c,Unit__c from Lifecycle__c where Unit__c IN:unitId and Term_Start_Date__c != null ]){
                lifecycleMap.put(lifecycle.Unit__c,lifecycle);
            }
            system.debug('lifecycleMap##'+lifecycleMap);
            Set<id> contactIdSet = new Set<id>();
            Commons_ContactWrapper Wrapper = new Commons_ContactWrapper();

            For(Contact contact:[SELECT Id,LegalName__c,firstname,lastname,Fax,Gender__c,Citizenship_Country__c,Unit__c,Preferred_Language_English__c,NonEnglish_Preferred_languages__c,Latest_Child_Safety_Training__c,Birth_Year__c,npe01__Preferred_Email__c,In_Person_Security__c,Skype__c,npe01__AlternateEmail__c,Expat_Digital__c,Child_Safety__c,OST_Status__c,Citizenship__c,Unit__r.Status__c,Unit__r.Wedding_Date__c,Unit__r.name,npe01__WorkEmail__c,npe01__HomeEmail__c,Unit__r.Appointee_Date__c,Unit__r.Initial_Departure__c,npe01__PreferredPhone__c,Field_Phone__c,Unit__r.Preferred_Contact__c,MailingAddress,Birthdate,MobilePhone,npe01__WorkPhone__c,HomePhone,OtherPhone,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,Unit__r.id FROM Contact where Unit__c IN:unitId]){
                contactIdSet.add(contact.id);
              
                Wrapper.contactId=contact.Id;
                Wrapper.unitname=contact.Unit__r.name;
                Wrapper.unitid=contact.Unit__c;
                Wrapper.recordType='Standard';
                Wrapper.firstName=contact.FirstName;
                Wrapper.Lastname=contact.LastName;
                Wrapper.PreferredName=contact.FirstName;
                Wrapper.Gender=contact.Gender__c;
                wrapper.BirthYear=contact.Birth_Year__c; 
              
                if(!string.isBlank(contact.Skype__c)){
                wrapper.SkypeID=contact.Skype__c;
                }
                else if(!string.isBlank(contact.Fax)){
                    wrapper.OtherMessaging=contact.Fax;
                } 
                if(contact.Citizenship__c =='Australian'){
                    wrapper.Citizenship='Australia';
                }
                else if(contact.Citizenship__c =='Dual'){
                    list<String> countryList=new list<String>();
                    wrapper.Citizenship='Australia';
                    countryList =contact.Citizenship_Country__c.split(';');
                      for(integer i=0;i<countryList.size();i++) {
                            if(countryList[i]=='Australia'){
                                countryList.remove(i);
                            }
                       }
                   wrapper.OtherCitizenship1=countryList.size()>0?countryList.get(0):null;                        
                   wrapper.OtherCitizenship2=countryList.size()>1?countryList.get(1):null;
                   }
                else if(contact.Citizenship__c =='Other'){
                    list<String> countryListtwo=new list<String>();
                    countryListtwo =contact.Citizenship_Country__c.split(';');
                        wrapper.OtherCitizenship1=countryListtwo.size()>0?countryListtwo.get(0):null;
                            System.debug('##'+wrapper.OtherCitizenship1);
                        wrapper.OtherCitizenship2=countryListtwo.size()>1?countryListtwo.get(1):null;
                            System.debug('$$'+wrapper.OtherCitizenship2);       
                    }
                /*if(contact.Preferred_Language_English__c ==true){
                    wrapper.PreferredLanguage='English';
                }
                else if(contact.Preferred_Language_English__c ==false){
                    wrapper.PreferredLanguage=contact.NonEnglish_Preferred_languages__c;
                    System.debug('PreferredLanguage##'+wrapper.PreferredLanguage);
                }  
                */
                if(lifecycleMap.containskey(contact.Unit__c)){
                    Wrapper.CurrentRoleAppointmentDate=lifecycleMap.get(contact.Unit__c).Term_Start_Date__c;
                    Wrapper.CurrentCountryiftraveling=lifecycleMap.get(contact.Unit__c).Lifecycle_Country__c;
                }
                if(contact.Unit__r.Wedding_Date__c!=null){
                    Wrapper.MaritalStatus='Married';
                    Wrapper.DateofMarriage=contact.Unit__r.Wedding_Date__c;
                }
                else if(contact.Unit__r.Wedding_Date__c==null){
                    Wrapper.MaritalStatus='Single';
                }
                if(contact.Unit__r.Status__c=='On-Field'|| contact.Unit__r.Status__c=='Home Assignment' || contact.Unit__r.Status__c=='Medical Leave' || contact.Unit__r.Status__c=='Sabbatical' || contact.Unit__r.Status__c=='Study Leave' || contact.Unit__r.Status__c=='Leave of Absence'){
                    Wrapper.PrimaryRole='Team Member';
                }
                else if(contact.Unit__r.Status__c=='Appointee'){
                   Wrapper.PrimaryRole='Appointee';
                }
                else if(contact.Unit__r.Status__c=='Concluded'){
                    Wrapper.PrimaryRole='Alumni';
                }
                else if(contact.Unit__r.Status__c=='ST On-Field'){
                    Wrapper.PrimaryRole='Short-Termer';
                }
                if(contact.npe01__Preferred_Email__c=='Personal'){
                    Wrapper.preferWorkEmail=contact.npe01__HomeEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c=='Work'){
                    Wrapper.preferWorkEmail=contact.npe01__WorkEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__HomeEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c=='Alternate'){
                    Wrapper.preferWorkEmail=contact.npe01__AlternateEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__HomeEmail__c;
                }
                else if(contact.npe01__Preferred_Email__c==null){
                    Wrapper.preferWorkEmail=contact.npe01__HomeEmail__c;
                    Wrapper.OtherActiveEmail=contact.npe01__WorkEmail__c;
                    Wrapper.AlternateEmail=contact.npe01__AlternateEmail__c;
                }                
                if(contact.Expat_Digital__c=='Completed'){
                    Wrapper.DigitalSecurityTraining=System.today();
                }
                if(contact.Child_Safety__c=='Completed'){
                    Wrapper.CSTInitialTraining=System.today();
                    Wrapper.CSTCompleted=System.today();
                }
                //Wrapper.CSTCompleted=contact.Latest_Child_Safety_Training__c;

                If(contact.OST_Status__c=='Completed'){
                    Wrapper.OSTCompleted=System.today();
                }
                If(contact.In_Person_Security__c=='Completed'){
                    Wrapper.FSTCompleted=System.today();
                }
                    Wrapper.MailingStreet=contact.MailingStreet;
                    Wrapper.MailingCity=contact.MailingCity;
                    Wrapper.MailingState=contact.MailingState;
                    Wrapper.MailingCountry=contact.MailingCountry;
                    Wrapper.MailingPostalCode=contact.MailingPostalCode;
                
                    Wrapper.OtherStreet=contact.OtherStreet;
                    Wrapper.OtherCity=contact.OtherCity;   
                    Wrapper.OtherState=contact.OtherState;
                    Wrapper.OtherCountry=contact.OtherCountry;
                    Wrapper.OtherPostalCode=contact.OtherPostalCode;
                   
                wrapper.MembershipStartDate=contact.Unit__r.Appointee_Date__c;
                Wrapper.OriginalFieldDepartureDate=contact.Unit__r.Initial_Departure__c;
                
                if(contact.npe01__PreferredPhone__c=='Mobile'){
                    Wrapper.HomeCountryPhoneNumber=contact.MobilePhone;
                }
                else if(contact.npe01__PreferredPhone__c=='Work'){
                    Wrapper.HomeCountryPhoneNumber=contact.npe01__WorkPhone__c;
                }
                else if(contact.npe01__PreferredPhone__c=='Home'){
                    Wrapper.HomeCountryPhoneNumber=contact.HomePhone;
                }
                else if(contact.npe01__PreferredPhone__c=='Other'){
                    Wrapper.HomeCountryPhoneNumber=contact.OtherPhone;
                }
               
                Wrapper.PrimaryFieldPhoneNumber=contact.Field_Phone__c;
                
                if(contact.Unit__r.Preferred_Contact__c=='FB Messenger'){
                    Wrapper.PreferredCommunication='FB Messenger';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='WhatsApp'){
                      Wrapper.PreferredCommunication='WhatsApp';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='Email'){
                      Wrapper.PreferredCommunication='Email';
                }
                 else if(contact.Unit__r.Preferred_Contact__c=='Text'){
                      Wrapper.PreferredCommunication='Text';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Phone'){
                      Wrapper.PreferredCommunication='Phone';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Skype/Zoom'){
                      Wrapper.PreferredCommunication='Skype/Zoom';
                }
                else if(contact.Unit__r.Preferred_Contact__c=='Signal'){
                      Wrapper.PreferredCommunication='Signal';
                }
                   
                Wrapper.Birthdate=contact.Birthdate;
                conList.add(Wrapper);
                System.debug('conList+++++'+conList); 
            }
           
            String jsonstr=JSON.serialize(conList); 
            System.debug('***JSON STRING'+jsonstr);      
       
                    Http h2 = new Http();
                    HttpRequest req1 = new HttpRequest();
                    req1.setHeader('Authorization','Bearer ' + accessToken);
                    req1.setHeader('Content-Type','application/json');
                    req1.setHeader('accept','application/json');
                    req1.setMethod('POST');
                    req1.setBody(jsonstr);
                    System.debug('body--->>'+jsonstr);
                    req1.setEndpoint(endPoint);
                    HttpResponse res1 = h2.send(req1);
              System.debug('Response--->>'+res1.getstatusCode());
              System.debug('Response--->>'+res1.getBody());
                }
            }
     @future(callout=true)
    public static void syncDependent(Set<id> unitId){
        system.debug('syncDependent');
        String accessToken=Commons_ConnectSFController.getRequestToken();
        
         List<Commons_ContactWrapper> WrapperList = new List<Commons_ContactWrapper>();
          SalesforceCredentials__c logincreds=[select Salesforce_URL__c from SalesforceCredentials__c ];
        if(accessToken != null) {
           
            String endPoint=logincreds.Salesforce_URL__c+'/services/apexrest/v1/createContact/';
            
            Map<id,Lifecycle__c> lifecycleMap = new Map<id,Lifecycle__c>();
            for(Lifecycle__c lifecycle:[select id,name,Term_Start_Date__c,Lifecycle_Country__c,Unit__c from Lifecycle__c where Unit__c IN:unitId and Term_Start_Date__c != null ]){
                lifecycleMap.put(lifecycle.Unit__c,lifecycle);
            }
            
            for(Dependent__c dependent:[select id,name,Birthdate__c,First_Name__c,Mobile__c,Citizenship__c,Last_Name__c,Gender__c,Email__c,Unit__r.Preferred_Contact__c,Unit__c,Unit__r.Wedding_Date__c,Unit__r.name,Education__c,On_Field__c,Unit__r.Status__c,unit__r.Appointee_Date__c,Unit__r.Initial_Departure__c,Unit__r.id from Dependent__c Where Unit__c IN:unitId]){
                Commons_ContactWrapper Wrapper = new Commons_ContactWrapper();
                Wrapper.contactId=dependent.Id;
                Wrapper.unitname=dependent.Unit__r.name;
                Wrapper.unitid=dependent.Unit__c;
                Wrapper.recordType='Dependant';
                Wrapper.firstName=dependent.First_Name__c;
                Wrapper.Lastname=dependent.Last_Name__c;
                Wrapper.Gender=dependent.Gender__c;
                Wrapper.Phone=dependent.Mobile__c;
                 if(dependent.Unit__r.Wedding_Date__c!=null){
                    Wrapper.MaritalStatus='Married';
                    Wrapper.DateofMarriage=dependent.Unit__r.Wedding_Date__c;
                }
                else if(dependent.Unit__r.Wedding_Date__c==null){
                    Wrapper.MaritalStatus='Single';
                }
                Wrapper.preferWorkEmail=dependent.Email__c;
                if(dependent.Unit__r.Status__c=='On-Field' || dependent.Unit__r.Status__c=='Home Assignment' || dependent.Unit__r.Status__c=='Medical Leave' || dependent.Unit__r.Status__c=='Sabbatical' || dependent.Unit__r.Status__c=='Study Leave' || dependent.Unit__r.Status__c=='Leave of Absence'){
                    Wrapper.PrimaryRole='Team Member';
                }
                else if(dependent.Unit__r.Status__c=='Appointee'){
                   Wrapper.PrimaryRole='Appointee';
                }
                else if(dependent.Unit__r.Status__c=='Concluded'){
                    Wrapper.PrimaryRole='Alumni';
                }
                else if(dependent.Unit__r.Status__c=='ST On-Field'){
                    Wrapper.PrimaryRole='Short-Termer';
                }
                if(dependent.Citizenship__c =='Australian'){
                    wrapper.Citizenship='Australia';
                    //System.debug('Citizenship##'+wrapper.Citizenship);
                 }
                 else if(dependent.Citizenship__c =='Dual'){
                    wrapper.Citizenship='Australia';
                 }
                wrapper.MembershipStartDate=dependent.Unit__r.Appointee_Date__c;
                Wrapper.OriginalFieldDepartureDate=dependent.Unit__r.Initial_Departure__c;
                
                Wrapper.Birthdate=dependent.Birthdate__c;
                
                 if(lifecycleMap.containskey(dependent.Unit__c)){
                    Wrapper.CurrentRoleAppointmentDate=lifecycleMap.get(dependent.Unit__c).Term_Start_Date__c;
                    Wrapper.CurrentCountryiftraveling=lifecycleMap.get(dependent.Unit__c).Lifecycle_Country__c;
                  }
                
                 if(dependent.Unit__r.Preferred_Contact__c=='FB Messenger'){
                  Wrapper.PreferredCommunication='FB Messenger';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='WhatsApp'){
                      Wrapper.PreferredCommunication='WhatsApp';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='Email'){
                      Wrapper.PreferredCommunication='Email';
                }
                 else if(dependent.Unit__r.Preferred_Contact__c=='Text'){
                      Wrapper.PreferredCommunication='Text';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Phone'){
                      Wrapper.PreferredCommunication='Phone';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Skype/Zoom'){
                      Wrapper.PreferredCommunication='Skype/Zoom';
                }
                else if(dependent.Unit__r.Preferred_Contact__c=='Signal'){
                      Wrapper.PreferredCommunication='Signal';
                }
                if(dependent.Education__c=='Home School'){
                Wrapper.dEducation='Home School';
                }
                else if(dependent.Education__c=='Boarding School'){
                    Wrapper.dEducation='Boarding School';
                }
                else if(dependent.Education__c=='Local School'){
                    Wrapper.dEducation='Local School';
                }
                else if(dependent.Education__c=='Not old enough'){
                    Wrapper.dEducation='Not old enough';
                }
               
                WrapperList.add(Wrapper);
            }
              String str=JSON.serialize(WrapperList); 
            System.debug('***JSON STRING'+str); 
            
             Http h2 = new Http();
                    HttpRequest req1 = new HttpRequest();
                    req1.setHeader('Authorization','Bearer ' + accessToken);
                    req1.setHeader('Content-Type','application/json');
                    req1.setHeader('accept','application/json');
                    req1.setMethod('POST');
                    req1.setBody(str);
                    System.debug('body--->>'+str);
                    req1.setEndpoint(endPoint);
                    HttpResponse res1 = h2.send(req1);
            System.debug('Response--->>'+res1.getstatusCode());
            System.debug('Response--->>'+res1.getBody());
                }
        
           }
     @future(callout=true)
    public static void syncRelationShips(Set<id> relationId){
        
         System.debug('syncRelationShips');
         System.debug('relationId'+relationId);
        String accessToken=Commons_ConnectSFController.getRequestToken();

         List<Commons_ContactWrapper> WrapperList = new List<Commons_ContactWrapper>();
          SalesforceCredentials__c logincreds=[select Salesforce_URL__c from SalesforceCredentials__c ];
        
        if(accessToken != null) {
           
            String endPoint=logincreds.Salesforce_URL__c+'/services/apexrest/v1/createContact/';
               Set<string> newrelationSet = new Set<string>();
        for(npe4__Relationship__c relation :[select id,name,npe4__Contact__c,npe4__RelatedContact__c,npe4__Status__c,npe4__Type__c from npe4__Relationship__c where Id IN:relationId ]){
               Commons_ContactWrapper Wrapper = new Commons_ContactWrapper();

               if(!newrelationSet.contains(relation.npe4__RelatedContact__c)){
                 wrapper.RelationshipId=relation.id;
                 Wrapper.RelationshipContact=relation.npe4__RelatedContact__c;
                 wrapper.RelatedContact=relation.npe4__Contact__c;
                 wrapper.relationType=relation.npe4__Type__c;
                 newrelationSet.add(relation.npe4__RelatedContact__c);
                 if(relation.npe4__Type__c=='Wife' || relation.npe4__Type__c=='Husband'){
                   newrelationSet.add(relation.npe4__Contact__c);
                 }
                 System.debug('Type++'+wrapper.relationType);
                 Wrapper.Status=relation.npe4__Status__c;
      
                 System.debug('Name##'+relation.Name);
                 System.debug('RelationshipContact$$'+Wrapper.RelationshipContact);
               }
        
                 WrapperList.add(Wrapper);
              }
                 System.debug('relationData'+WrapperList);
            String str=JSON.serialize(WrapperList); 
            System.debug('***JSON STRING'+str); 
            
             Http h2 = new Http();
                    HttpRequest req1 = new HttpRequest();
                    req1.setHeader('Authorization','Bearer ' + accessToken);
                    req1.setHeader('Content-Type','application/json');
                    req1.setHeader('accept','application/json');
                    req1.setMethod('POST');
                    req1.setBody(str);
                    System.debug('body--->>'+str);
                    req1.setEndpoint(endPoint);
                    HttpResponse res1 = h2.send(req1);
              System.debug('Response--->>'+res1.getstatusCode());
              System.debug('Response--->>'+res1.getBody());
          }
    }
}