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
      string|error groupId = getGroupIdByName(GROUP_NAME);
      if (groupId is error) {
        return groupId;
      }

      log:printInfo(string `Group ID: ${groupId}`);
      log:printInfo(string `User ID: ${userId}`);
      // scim:UserResource response = check scimClient->getUser(userId);
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

function getGroupIdByName(string name) returns string|error {
  scim:GroupSearch groupSearchQuery = {filter: string `displayName eq ${name}`};
  scim:GroupResponse|scim:ErrorResponse|error groupResponse = scimClient->searchGroup(groupSearchQuery);
  if (groupResponse is scim:GroupResponse) {
    if (groupResponse.totalResults != 0) {
      scim:GroupResource[] groups = <scim:GroupResource[]>groupResponse.Resources;
      return <string>groups[0].id; // GroupId should be there if a group is found
    } else {
      return error(string `No groups found for ${name}`);
    }
  } else if (groupResponse is scim:ErrorResponse) {
    return error(string `SCIM Error: ${groupResponse.detail().toJsonString()}`);
  } else {
    return groupResponse;
  }
}