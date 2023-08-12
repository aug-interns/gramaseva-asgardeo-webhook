import ballerinax/trigger.asgardeo;
import ballerina/http;
import ballerina/log;

configurable asgardeo:ListenerConfig config = ?;

listener http:Listener httpListener = new(8090);
listener asgardeo:Listener webhookListener =  new(config,httpListener);

service asgardeo:RegistrationService on webhookListener {
  
    remote function onAddUser(asgardeo:AddUserEvent event ) returns error? {
      log:printInfo("--------------------- AddUserEvent (START) ---------------------");
      log:printInfo(event.toJsonString());
      log:printInfo("--------------------- AddUserEvent (END) ---------------------");
    }
    remote function onConfirmSelfSignup(asgardeo:GenericEvent event ) returns error? {
      log:printInfo("--------------------- ConfirmSelfSignup (START) ---------------------");
      log:printInfo(event.toJsonString());
      log:printInfo("--------------------- ConfirmSelfSignup (END) ---------------------");
    }
    remote function onAcceptUserInvite(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
    }
}

service /ignore on httpListener {}