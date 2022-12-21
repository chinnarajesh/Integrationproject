@isTest
global class  Commons_MockcalloutsTestClass implements HttpCalloutMock{
    
     global HTTPResponse respond(HTTPRequest req) {
       
        String httpEndpoint = req.getEndpoint();
        String httpMethod = req.getMethod();
         string EndpointUrl ='https://commons--rajeshdev.my.salesforce.com/services/oauth2/token';
         string EndpointUrl2 ='https://commons--rajeshdev.my.salesforce.com/services/apexrest/v1/createContact/';
        if (httpMethod.equals('GET')) {
            if(httpEndpoint.contains(EndpointUrl)){
                 return mockGetToken(req);
            }
              }
        if (httpMethod.equals('POST')) {
            if(httpEndpoint.contains(EndpointUrl)) {
                 return mockGetToken(req);
            }
             else if(httpEndpoint.contains(EndpointUrl2)) {
              return mocksurveyResponse(req);
            }
        }
         return null;
     }
      private static HTTPResponse mockGetToken(HTTPRequest req) {
        
        String jsonResponse = '{"access_token":"00D2h0000008gZa!AREAQEW.hdajGqq8nkoOLEQN8KxKZDdIKLG.gf1ujcvLIoOnTwqEp.ZBJOu4.a5lEHdKmHbUVnqrUdg6cDEg2i4DN_77rrQN","token_type":"Bearer"}';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(jsonResponse);
        res.setStatusCode(200);
        return res;
    }
     private static HTTPResponse mocksurveyResponse(HTTPRequest req) {
        
        String jsonResponse = '';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(jsonResponse);
        res.setStatusCode(200);
        return res;
    }

}