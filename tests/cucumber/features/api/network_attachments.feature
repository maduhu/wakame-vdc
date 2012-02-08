@api_from_v12.03
Feature: Network Port Attachments API

  Scenario: Attachment lifecycle
    Given a new network with its uuid in <registry:network_uuid>
    And a new instance with its uuid in <registry:instance_uuid>
    And a new port in <registry:network_uuid> with its uuid in <registry:port_uuid>

    When we make an api get call to instances/<registry:instance_uuid> with no options
      Then the previous api call should be successful
      And the previous api call should have {"vif":[]} with a size of 3
      And the previous api call should not have {"vif":[...,{"port_id":},...]} equal to nil

      And from the previous api call take {"vif":[...,,...]} and save it to <registry:vif> for {"network_id":} equal to "nw-demo1"
      And from <registry:vif> take {"ipv4":{"address":}} and save it to <registry:ip>

    Then we should be able to ping on ip <registry:ip> in 60 seconds or less

    

    # Detach the vnic, restart.
    # Verify the vnic is not attached.

    # Verify that ping fails.

    # Attach the vnic, restart.

    # Verify that ping succeeds.
