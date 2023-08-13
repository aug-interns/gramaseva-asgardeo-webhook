import ballerinax/trigger.asgardeo;
import ballerina/http;
import ballerina/log;
import ballerinax/scim;

configurable asgardeo:ListenerConfig config = ?;
scim:ConnectorConfig scim_config = {
    orgName: "zetcco",
    clientId: "lR3O8bqQBd1A91VCxjExPFSd8Ega",
    clientSecret : "QIMDQjS26fUtOIlrJbVj6nZqZqKwT9coqITEfiVOCg4a",
    scope : [
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

string GROUP_NAME = "HR-Officer";

service asgardeo:RegistrationService on webhookListener {
  
    remote function onAddUser(asgardeo:AddUserEvent event ) returns error? {
      string userId = <string>event.eventData?.userId; // UserId should be there if a new user is created, hence the typecast
      // scim:UserResource response = check scimClient->getUser(userId);

      scim:GroupSearch groupSearchQuery = {filter: string `displayName eq ${GROUP_NAME}`};
      scim:GroupResponse|scim:ErrorResponse|error groupResponse = scimClient->searchGroup(groupSearchQuery);
      if (groupResponse is scim:GroupResponse) {
        if (groupResponse.totalResults != 0) {
          scim:GroupResource[] groups = <scim:GroupResource[]>groupResponse.Resources;
          log:printInfo(groups[0].toJsonString());
          log:printInfo(string `Group ID: ${groups[0].id ?: "Not found"}`);
        } else {
          log:printError(string`No groups found for ${GROUP_NAME}`);
        }
      } else if (groupResponse is scim:ErrorResponse) {
        log:printError(groupResponse.detail().toJsonString());
      } else {
        return groupResponse;
      }
      // log:printInfo(response.toJsonString());
    }
    remote function onConfirmSelfSignup(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
    }
    remote function onAcceptUserInvite(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
    }
}

service /ignore on httpListener {}