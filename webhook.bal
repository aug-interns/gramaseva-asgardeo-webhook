import ballerinax/trigger.asgardeo;
import ballerina/http;
import ballerina/log;
import ballerinax/scim;

configurable asgardeo:ListenerConfig config = ?;
scim:ConnectorConfig scim_config = {
    orgName: "zetcco",
    clientId: "WjpXaf9B6PLsaS789iUaNhFfHsMa",
    clientSecret : "fv1p6bojR1IDM8Ry6sFiOILBZmkecGDH5skGDEACkmAa",
    scope : ["openid"]
};

listener http:Listener httpListener = new(8090);
listener asgardeo:Listener webhookListener =  new(config,httpListener);

scim:Client scimClient = check new(scim_config);

service asgardeo:RegistrationService on webhookListener {
  
    remote function onAddUser(asgardeo:AddUserEvent event ) returns error? {
      log:printInfo("--------------------- AddUserEvent (START) ---------------------");
      string? email = event.eventData?.userName; // UserId should be there if a new user is created, hence the typecast
      if (!(email is ())) {
        log:printInfo(email);
        error|scim:UserResource searchResponse = findUserByEmail(email);

        if searchResponse is error {
            
            return error("error occurred while searching the user");
        }

        string userId = <string>searchResponse.id;
        log:printInfo(userId);
        // log:printInfo(cresponse.toJsonString());
        // scim:UserResource response = check scimClient->getUser(<string>userId);
        // log:printInfo(response.toJsonString());
      }
      log:printInfo("--------------------- AddUserEvent (END) ---------------------");
    }
    remote function onConfirmSelfSignup(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
    }
    remote function onAcceptUserInvite(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
    }
}

function findUserByEmail(string email) returns error|scim:UserResource {

    string properUserName = string `DEFAULT/${email}`;

    scim:UserSearch searchData = {filter: string `userName eq ${properUserName}`};
    scim:UserResponse|scim:ErrorResponse|error searchResponse = check scimClient->searchUser(searchData);
    
    if searchResponse is scim:UserResponse {
        scim:UserResource[] userResources = searchResponse.Resources ?: [];

        return userResources[0];
    } 
    
    return error("error occurred while searching the user");
}

service /ignore on httpListener {}