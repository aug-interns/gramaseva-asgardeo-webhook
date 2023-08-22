import ballerinax/trigger.asgardeo;
import ballerina/http;
import ballerina/log;
import ballerinax/scim;
import asgardeo_webhook.configs;

configurable configs:AsgardeoConfig asgardeoConfig = ?;
configurable asgardeo:ListenerConfig config = ?;
scim:ConnectorConfig scim_config = {
    orgName: asgardeoConfig.managementAppOrganization,
    clientId: asgardeoConfig.managementAppClientId,
    clientSecret : asgardeoConfig.managementAppClientSecret,
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

service asgardeo:RegistrationService on webhookListener {
  
    remote function onAddUser(asgardeo:AddUserEvent event ) returns error? {
      log:printInfo("Fired onAddUser");
      string userId = <string>event.eventData?.userId; // UserId should be there if a new user is created, hence the typecast
      string userName = <string>event.eventData?.userName; // UserId should be there if a new user is created, hence the typecast
      string|error groupId = getGroupIdByName(asgardeoConfig.groupName);
      if (groupId is error) {
        return groupId;
      }

      scim:GroupPatch patchData = {
        schemas: [
          "urn:ietf:params:scim:api:messages:2.0:PatchOp"
        ],
        Operations: [
          { 
            op: "add", 
            value: { 
              members: [ 
                { value: userId, display: userName } 
              ] 
            }
          }
        ]
      };
      scim:GroupResponse|scim:ErrorResponse|error patchResponse = scimClient->patchGroup(groupId, patchData);
      if (patchResponse is scim:ErrorResponse) {
        log:printError(patchResponse.toString());
        log:printError(string `Error setting User:${userId} to Group:${groupId}`);
      } else {
        log:printInfo(string `User:${userId} assigned to Group:${groupId}`);
      }
    }
    remote function onConfirmSelfSignup(asgardeo:GenericEvent event ) returns error? {
      string userId = <string>event.eventData?.userId;
      log:printInfo(string `Fired onConfirmSelfSignup User:${userId}`);
      // Not implemented
    }
    remote function onAcceptUserInvite(asgardeo:GenericEvent event ) returns error? {
      // Not implemented
      string userId = <string>event.eventData?.userId;
      log:printInfo(string `Fired onAcceptUserInvite User:${userId}`);
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