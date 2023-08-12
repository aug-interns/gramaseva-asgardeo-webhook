import ballerinax/trigger.asgardeo;
import ballerina/http;
import ballerina/log;
import ballerinax/scim;

configurable asgardeo:ListenerConfig config = ?;
scim:ConnectorConfig scim_config = {
    orgName: "zetcco",
    clientId: "WjpXaf9B6PLsaS789iUaNhFfHsMa",
    clientSecret : "fv1p6bojR1IDM8Ry6sFiOILBZmkecGDH5skGDEACkmAa",
    scope : [
      "internal_login",
      "internal_user_mgt_view",
      "internal_user_mgt_list",
      "internal_user_mgt_create",
      "internal_user_mgt_delete",
      "internal_user_mgt_update",
      "internal_user_mgt_delete",
      "internal_group_mgt_view",
      "internal_group_mgt_list",
      "internal_group_mgt_create",
      "internal_group_mgt_delete",
      "internal_group_mgt_update",
      "internal_group_mgt_delete"
    ]
};

listener http:Listener httpListener = new(8090);
listener asgardeo:Listener webhookListener =  new(config,httpListener);

scim:Client scimClient = check new(scim_config);

service asgardeo:RegistrationService on webhookListener {
  
    remote function onAddUser(asgardeo:AddUserEvent event ) returns error? {
      log:printInfo("--------------------- AddUserEvent (START) ---------------------");
      string? userId = event.eventData?.userId; // UserId should be there if a new user is created, hence the typecast
      if (!(userId is ())) {
        log:printInfo(userId);
        scim:UserResource|scim:ErrorResponse cresponse = check scimClient->getUsers();
        if (cresponse is scim:ErrorResponse) {
          log:printError(cresponse.message());
          log:printError(cresponse.toString());
          log:printError(cresponse.toBalString());
        }
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

service /ignore on httpListener {}