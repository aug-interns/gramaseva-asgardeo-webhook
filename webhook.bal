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
      log:printInfo(event.toJsonString());
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